/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.test.aeron.madrigal;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ps.PrestoClient;
import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class MadMixBase {
    private static final Logger log = LoggerFactory.getLogger(MadMixBase.class);

    protected static final int RESOLUTION_MILLIS = 10;

    protected final boolean _dummyTest;

    protected final MadMix _madMix;
    protected final PrestoClient _client;
    protected ISubscriptionListener _listener;
    private volatile Long _subsId = -1L;

	protected String _sql;
    protected String _sqlOiN;

    private final Histogram _h;
    public Histogram getHistogram() {
    	return _h;
    }

    public MadMixBase(MadMix madMix, String type, long highestTrackableValue, boolean dummyTest) {
    	_madMix = madMix;
    	_dummyTest = dummyTest;
		_client = madMix.getClient();

    	_sql = "select * from " + type;
    	_sqlOiN = _sql + " where mine=0";

    	_h = new Histogram(highestTrackableValue, 3);

    	_listener = new MadMixMsgHandler();
    }
    
    private class MadMixMsgHandler implements ISubscriptionListener {
		@SuppressWarnings("unused")
		@Override
		public void onSubscriptionMessage(Obj obj, long subsId) {
			try {
				obj.startUsing();
				long endNanoTime = System.nanoTime();
				long startNanoTime = obj.getTsNanos();

				if (startNanoTime > 0) {
					long latency = endNanoTime - startNanoTime;
					try {
						getHistogram().recordValue(latency);
					} catch (Exception x) {
						log.info("Error logging value " + latency, x);
					}
				}
				if (MadMix.TST_SIZE<=10) {
					log.info("<<< "+obj);
				}
			} catch (Exception x) {
				log.error("", x);
			} finally {
				obj.stopUsing();
			}
		}
    }

	public abstract void runTest(MadMix.TestParams params) throws Exception;

	public void startCycle(MadMix.TestParams params) {
    	try {
        	_subsId = _client.subscribe((params.getOneInN()==1) ? _sql : _sqlOiN, (obj, subsId) -> {
    			try {
    				obj.startUsing();
    				long endNanoTime = System.nanoTime();
    				long startNanoTime = obj.getTsNanos();

    				if (startNanoTime > 0) {
    					long latency = endNanoTime - startNanoTime;
    					try {
    						getHistogram().recordValue(latency);
    					} catch (Exception x) {
    						log.info("Error logging value " + latency, x);
    					}
    				}
    				if (MadMix.TST_SIZE<=10) {
    					log.info("<<< "+obj);
    				}
    			} catch (Exception x) {
    				log.error("", x);
    			} finally {
    				obj.stopUsing();
    			}
        	});

        	_madMix.getStartLatch().await();
        	
    		if (_dummyTest) {
    			runDummyTest(params);
    		} else {
    			runTest(params);
    		}

			_madMix.getEndLatch().countDown();
		} catch (Exception e) {
			log.error("", e);
		}
    }

    public void endCycle() {
    	_client.unsubscribe(_subsId);
    }

    public void updateObj(Obj obj, long seqNo, int oneInN) {
        obj.setMine((short) (seqNo%oneInN));
        obj.setTsNanos((seqNo>=0) ? System.nanoTime() : seqNo);
    }


	protected void runDummyTest(MadMix.TestParams params) throws Exception {
    	while (_madMix.getTestingPhase() != MadMix.TestingPhase.DONE) {
    		Utils.sleepMillisDelay(RESOLUTION_MILLIS);
    	}
    	log.info("Completed...");
	}
}
