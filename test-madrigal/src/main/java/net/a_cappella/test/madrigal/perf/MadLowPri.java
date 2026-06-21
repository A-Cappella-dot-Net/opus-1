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

package net.a_cappella.test.madrigal.perf;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.ISnapRequestListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

public class MadLowPri extends MadMixBase {
    private static final Logger log = LoggerFactory.getLogger(MadLowPri.class);
	private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(MadLowPri.class.getSimpleName() + "-%d").setDaemon(true).build();

    private static final int MILLIS_PER_BURST = 1000;
    private static final int RESOLUTION_MICROS = 10;
    private static final int MSG_SPACING_MICROS = 1;

    private int _burstSize;
	private long _warmupCnt = 0;
	private long _testCnt = 0;


    public MadLowPri(MadMix madMix, boolean dummyTest) {
    	super(madMix, "ecn.instrument", TimeUnit.MILLISECONDS.toNanos(200), dummyTest);

    	new SnapService();
    }

	public void startCycle(MadMix.TestParams params) {
    	try {
        	_madMix.getStartLatch().await();
        	_burstSize = params.getBurstSize();

    		if (_dummyTest) {
    			runDummyTest(params);
    		} else {
    			runTest(params);
    		}
		} catch (Exception e) {
			log.error("", e);
		}
    }

    public void endCycle() {}

	@Override
	public void runTest(MadMix.TestParams params) {
    	long endTime = 0;

    	while (_madMix.getTestingPhase() != MadMix.TestingPhase.DONE) {
    		switch (_madMix.getTestingPhase()) {
            case DONE:
            case STARTING:
            case BREAK:
        		Utils.busyMicrosDelay(RESOLUTION_MICROS);
            	continue;
            case WARMUP:
            case TESTING:
        		Utils.busyMicrosDelay(RESOLUTION_MICROS);
        		long nowMillis = System.currentTimeMillis();
        		if (nowMillis > endTime) {
        	    	endTime = nowMillis + MILLIS_PER_BURST;
        	    	try {
        	        	_client.snap(_sql, _listener);
        			} catch (Exception e) {
        				log.error("", e);
        			}
        		}
        		break;
            }
    	}

    	log.info("Completed " + -_warmupCnt + "/" + _testCnt);

    	_madMix.getEndLatch().countDown();
    }

    private void updateObj(EcnInstrumentObj obj, int tstCnt, long seqNo, int oneInN) {
        obj.set("instrId", "symbol", 20190324, 3.0, 1.0, 0.01, 1.0, 1.0, "ecn", System.currentTimeMillis());
        super.updateObj(obj, seqNo, oneInN);
    }




    private class SnapService implements ISubscriptionListener, ISnapRequestListener {
        private final ExecutorService _executor = Executors.newFixedThreadPool(1, _threadFactory);
        private final String _qsSql = "select * from ecn.instrument";
        private final EcnInstrumentObj _obj = new EcnInstrumentObj();

        public SnapService() {
	    	try {
	    		_client.subscribe(_qsSql, this);
			} catch (Exception e) {
				log.error("", e);
			}
		}

	    @Override
		public void onSubscriptionMessage(Obj obj, long subsId) {}

		@Override
		public void onSnapRequest(SnapRequestObj obj, long subsId) {
			_executor.execute(
				() -> {
					try {
						SnapRequestObj snp = new SnapRequestObj();
						snp.set(obj.getSubject(), obj.getSql(), subsId);
						snp.copyRoutingFields(obj);

						_madMix.reply(snp, PubType.SNP_BEGIN);

			        	_obj.copyRoutingFields(obj);
			        	_obj.setSubject("ecn.instrument");

			        	int burstSize = 0;
			        	boolean done = false;

			        	while (burstSize < _burstSize && !done) {
			        		switch (_madMix.getTestingPhase()) {
			                case DONE:
			                	done = true;
			                	break;
			                case STARTING:
			                case BREAK:
			            		Utils.busyMicrosDelay(MSG_SPACING_MICROS);
			                    break;
			                case WARMUP:
			                	burstSize++;
			            		Utils.busyMicrosDelay(MSG_SPACING_MICROS);
			                	_warmupCnt--;
			            		updateObj(_obj, 0, _warmupCnt, 1);
			                    _madMix.reply(_obj, PubType.SNP_MSG);
			                    break;
			                case TESTING:
			                	burstSize++;
			            		Utils.busyMicrosDelay(MSG_SPACING_MICROS);
			                	_testCnt++;
			            		updateObj(_obj, 0, _testCnt, 1);
			                    _madMix.reply(_obj, PubType.SNP_MSG);
			                    break;
			        		}
			        	}

			            _madMix.reply(snp, PubType.SNP_END);
					} catch (Exception e) {
						log.error("", e);
					}
				}
			);
		}
	}
}
