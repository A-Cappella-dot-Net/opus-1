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

package net.a_cappella.test.presto.perf.pingpong;

import java.util.concurrent.TimeUnit;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.TestObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.test.presto.perf.CpuCycler;
import net.a_cappella.test.presto.perf.StatsTestParams;
import net.a_cappella.test.presto.perf.StatsTestsParams;
import net.openhft.affinity.Affinity;
import net.openhft.affinity.AffinityLock;
import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ping {
    private static final Logger log = LoggerFactory.getLogger(Ping.class);

    private static final String TAB = StatsLogger.TAB;

    private static final int BEFORE_WARMUP_WAIT_MILLIS = 1000;
    private static final int BEFORE_TEST_WAIT_MILLIS = 1000;

    private static final int WUP_SIZE = 1_000_000;
    private static final int TST_SIZE = 1_000_000;

	private static final String _localhost = Utils._localhost;
    private final String _channelType;
    private final String _mediaDriverType;

    private enum TestMsgType {
    	PING, TEST
    }

    private TightLoopThread _tightLoopThread;
    public void setTightLoopThread(TightLoopThread tightLoopThread) {
    	_tightLoopThread = tightLoopThread;
    }

    private static TestMsgType _tstMsgType;
    private static int _cpu;

    private static final String _sqlPing = "select * from ping where mine=1";
    private static final String _sqlTest = "select * from test where mine=1";

    private static final PingObj _pingObj = new PingObj();
    private static final TestObj _testObj = new TestObj();

    private final Histogram _h = new Histogram(TimeUnit.SECONDS.toNanos(100), 3);
    private final StatsLogger _statsLogger = new StatsLogger(log);

    private long _subsId;
    private Obj _msg;

	private final Object _lock = new Object();
	private boolean _received = false;

    private int _pinToCpu = 0; // >0 = pinned to that value; 0 = pinned to param value; <0 = not pinned
    public void setPinToCpu(String pinToCpu) {
    	_pinToCpu = net.a_cappella.continuo.utils.Utils.parseAsInt("pinToCpu", pinToCpu, _pinToCpu);
    }

    private final PrestoClient _client;
	private final CpuCycler _cycler = new CpuCycler();

    public Ping(PrestoClient client, String channelType, String mediaDriverType) {
    	_client = client;
    	_channelType = channelType;
    	_mediaDriverType = mediaDriverType;
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_statsLogger.logHeader(configHeader() + _statsTestsParams.header());
    	_statsTestsParams.initTestParams();

		new Thread(() -> {
			if (_pinToCpu>0) {
				Affinity.setAffinity(_pinToCpu);
				log.info("Pinned to CPU "+Affinity.getCpu()+" of "+ AffinityLock.BASE_AFFINITY);
			} else if (_pinToCpu<0) {
				log.info("Starting on CPU "+ Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
			}

			try {
		    	do {
		        	_subsId = _client.subscribe(getSql(), _subListener);

					if (_pinToCpu==0) Affinity.setAffinity(_cpu);

					runOneTest();

					_client.unsubscribe(_subsId);

		        	_statsLogger.logRow(_h, currentConfigValues() + _statsTestsParams.currentTestParams());

		        	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_TEST, 10);
		        	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_PING, 10);

		    	} while (_statsTestsParams.nextTestParams());

		    	log.info("Done!");

				if (_pinToCpu<0) log.info("Ending on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);

				_client.stop();
		    	if (_tightLoopThread!=null) _tightLoopThread.stop();

			} catch (Exception x) {
				log.error("", x);
			}
		}, "Ping-Thread").start();
    }

    private final ISubscriptionListener _subListener = (obj, subsId) -> {
		try {
			obj.startUsing();

			recordLatency(obj);
			logObj(obj);

			synchronized (_lock) {
    			_lock.notify();
    			_received = true;
			}

		} catch (Exception x) {
			log.error("", x);
		} finally {
			obj.stopUsing();
		}
	};
 
   	private void runOneTest() throws Exception {
        _msg = getObj();
		_h.reset();

        setTestFields(0, Long.MIN_VALUE);
		_client.publish(_msg); // trigger a GC on the Pong side
        System.gc();

        if (WUP_SIZE>0) {
        	Thread.sleep(BEFORE_WARMUP_WAIT_MILLIS);
            log.info("starting warmup...");

            for (int i = -WUP_SIZE; i<0; i++) {
                setTestFields(i, 0);
    	        try {
    				_client.publish(_msg);
    			} catch (Exception e) {
    				log.error("", e);
    			}

    	        synchronized (_lock) {
    		        while(!_received) _lock.wait();
    		        _received = false;
    	        }
            }
 
			log.info("done warming up!");
        }

    	Thread.sleep(BEFORE_TEST_WAIT_MILLIS);
        log.info("starting test...");

        for (int i=0; i<TST_SIZE; i++) {
            setTestFields(i, System.nanoTime());
	        try {
				_client.publish(_msg);
			} catch (Exception e) {
				log.error("", e);
			}

	        synchronized (_lock) {
		        while(!_received) _lock.wait();
		        _received = false;
	        }
        }

		log.info("test ended!");
   	}

	private void recordLatency(Obj obj) throws Exception {
		long endNanoTime = System.nanoTime();
		long startNanoTime = getStartNanoTime(obj);
		if (startNanoTime>0) {
			long latency = (endNanoTime - startNanoTime) / 2; // 1/2 RTT
			try {
				_h.recordValue(latency);
			} catch (Exception x) {
				log.info("Error logging value " + latency, x);
			}
		}
	}



    private String getSql() {
    	if (_tstMsgType == TestMsgType.PING) {
			return _sqlPing;
    	} else {
   			return _sqlTest;
    	}
    }

    private Obj getObj() {
    	if (_tstMsgType == TestMsgType.PING) {
    		return _pingObj;
    	} else {
    		return _testObj;
    	}
    }

	private void setTestFields(int id, long startNanoTime) {
    	if (_tstMsgType == TestMsgType.PING) {
    			PingObj pingObj = _pingObj;
        		pingObj.setMine((short) 0);
        		pingObj.setTsNanos(startNanoTime);
        		pingObj.setId(id);
        		pingObj.setPayload(startNanoTime);
    	} else {
    			TestObj testObj = _testObj;
        		testObj.setMine((short) 0);
        		testObj.setTsNanos(startNanoTime);
        		testObj._anInt = id;
        		testObj._aLong = startNanoTime;
    	}
	}

	private long getStartNanoTime(Obj obj) {
		return obj.getTsNanos();
	}


	@SuppressWarnings("unused")
	private void logObj(Obj obj) {
		int id = (obj instanceof PingObj) ? ((PingObj)obj).getId() : ((TestObj)obj)._anInt;
		if (id<0) {
			if (WUP_SIZE<=1000 && id%200==0 || WUP_SIZE<=10) {
				log.info("onSubscriptionMessage "+obj);
			}
		} else {
			if (TST_SIZE<=1000 && id%200==0 || TST_SIZE<=10) {
				log.info("onSubscriptionMessage "+obj);
			}
		}
	}




	public String configHeader() {
		return "host" + TAB + "chType" + TAB + "mdType" + TAB;
	}
	public String currentConfigValues() {
		return _localhost + TAB + _channelType + TAB + _mediaDriverType + TAB;
	}

	private final StatsTestsParams _statsTestsParams = new StatsTestsParams(
		new TestParams[] {
//			TestParams(msgType, cpu)

			new TestParams(TestMsgType.TEST, (_pinToCpu==0) ? _cycler.nextCpuAsc() : _pinToCpu),
			new TestParams(TestMsgType.PING, (_pinToCpu==0) ? _cycler.nextCpuAsc() : _pinToCpu),
			new TestParams(TestMsgType.TEST, (_pinToCpu==0) ? _cycler.nextCpuDesc() : _pinToCpu),
			new TestParams(TestMsgType.PING, (_pinToCpu==0) ? _cycler.nextCpuDesc() : _pinToCpu),
			new TestParams(TestMsgType.TEST, (_pinToCpu==0) ? _cycler.nextCpuAsc() : _pinToCpu),
			new TestParams(TestMsgType.PING, (_pinToCpu==0) ? _cycler.nextCpuAsc() : _pinToCpu),
			new TestParams(TestMsgType.TEST, (_pinToCpu==0) ? _cycler.nextCpuDesc() : _pinToCpu),
			new TestParams(TestMsgType.PING, (_pinToCpu==0) ? _cycler.nextCpuDesc() : _pinToCpu),
		}
	);



	private static class TestParams implements StatsTestParams {
	    TestMsgType _tstMsgType;
	    int _cpu;

		TestParams(TestMsgType tstMsgType, int cpu) {
			_tstMsgType = tstMsgType;
			_cpu = cpu;
		}

		public void updateTestParams() {
			Ping._tstMsgType = _tstMsgType;
			Ping._cpu = _cpu;
		}
		public String header() {
			return "msgType"+TAB+"cpu"+TAB;
		}
		public String toString() {
			return _tstMsgType+TAB+_cpu+TAB;
		}
	}
}
