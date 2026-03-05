package net.a_cappella.test.aeron.presto;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.obj.MyEnum;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.TestObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.PublicationHelper;
import net.openhft.affinity.Affinity;
import net.openhft.affinity.AffinityLock;
import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

public class BurstPing {
    private static final Logger log = LoggerFactory.getLogger(BurstPing.class);

    private static final String TAB = StatsLogger.TAB;

    private static final int BEFORE_WARMUP_WAIT_MILLIS = 1000;
    private static final int BEFORE_TEST_WAIT_MILLIS = 1000;

    private static final int WUP_SIZE = 1_000_000;

    private static final String _localhost = Utils._localhost;
    private final String _channelType;
    private final String _mediaDriverType;

    private static int _retriesOnBackPressure;
    private static int _sleepNanosOnBackPressureRetry;
    private static int _sleepNanosBetweenMessages;
    private static int _tstSize;

    private final Histogram _h = new Histogram(TimeUnit.SECONDS.toNanos(50), 3);
    private final StatsLogger _statsLogger = new StatsLogger(log);

    private long _subsId;

    private int _pinToCpu = 0;
    public void setPinToCpu(String pinToCpu) {
    	_pinToCpu = net.a_cappella.continuo.utils.Utils.parseAsInt("pinToCpu", pinToCpu, _pinToCpu);
    }

    private final PrestoClient _client;

    private final TestObj _testObj = newTestObj();
    private final PingObj _pingObj = new PingObj();

    private final String _pingSql = "select * from ping where mine=0";

    private TightLoopThread _tightLoopThread;
    public void setTightLoopThread(TightLoopThread tightLoopThread) {
    	_tightLoopThread = tightLoopThread;
    }

    public BurstPing(PrestoClient client, String channelType, String mediaDriverType) {
    	_client = client;
    	_channelType = channelType;
    	_mediaDriverType = mediaDriverType;
    }

	private final Object _lock = new Object();
	private boolean _received = false;

    private volatile int _lastReceivedId;

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_statsLogger.logHeader(configHeader() + _statsTestsParams.header());
    	_statsTestsParams.initTestParams();

    	new Thread(() -> {
			if (_pinToCpu>0) {
				Affinity.setAffinity(_pinToCpu);
				log.info("Pinned to CPU "+Affinity.getCpu()+" of "+ AffinityLock.BASE_AFFINITY);
			} else {
				log.info("Starting on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
			}

    		try {
    	    	_subsId = _client.subscribe(_pingSql, _subListener);

    			do {
    				runOneTest();
    			} while (_statsTestsParams.nextTestParams());

    			_client.unsubscribe(_subsId);

    			log.info("Done!");

				if (_pinToCpu<=0) log.info("Ending on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);

    			_client.stop();
    	    	if (_tightLoopThread!=null) _tightLoopThread.stop();

    		} catch (Exception x) {
				log.error("", x);
    		}
    	}, "Ping-Thread").start();
    }

    private final ISubscriptionListener _subListener = (obj, subsId) -> {
		obj.startUsing();

		PingObj ping = (PingObj) obj;
    	long warmup = ping.getPayload();

    	if (warmup == -1) { // warmup
			synchronized (_lock) {
    			_lock.notify();
    			_received = true;
			}
    	} else { // proper test
        	try {
        		recordLatency(ping);
    		} catch (Exception x) {
    			log.error("", x);
        	}

        	_lastReceivedId = ping.getId();
    	}

    	obj.stopUsing();
	};
 
	private void runOneTest() throws Exception {
		_h.reset();

        updateObj(_testObj, _retriesOnBackPressure, _sleepNanosOnBackPressureRetry);
        _client.publish(_testObj); // trigger a GC on the Pong side
        System.gc();

        if (WUP_SIZE>0) {
        	Thread.sleep(BEFORE_WARMUP_WAIT_MILLIS);
            log.info("starting warmup...");

            for (int i = -WUP_SIZE; i<0; i++) {
		        updateObj(_pingObj, i, -1);
    	        try {
    				_client.publish(_pingObj);
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

        int lastPublishedId = 0;
        int lastResult;
        boolean published;

        do {
	        Utils.sleepNanosDelay(_sleepNanosBetweenMessages);
	        updateObj(_pingObj, ++lastPublishedId, 0);
	        lastResult = _client.publish(_pingObj);
	        published = PublicationHelper.isPublished(lastResult);
        } while (published && lastPublishedId<_tstSize);

        if (!published) lastPublishedId--;
    	log.info("publication ended! lastPublishedId="+lastPublishedId+" result="+String.format("0x%08X", lastResult));

    	while (_lastReceivedId != lastPublishedId);

    	log.info("test ended!");

    	_statsLogger.logRow(_h, currentConfigValues() + _statsTestsParams.currentTestParams());
    }









    private TestObj newTestObj() {
        TestObj obj = new TestObj();

        obj._aBoolean = false;
        obj._aChar = 'c';
        obj._aDouble = Math.PI;
        obj._aFloat = (float) Math.PI;
        obj._aString = "testy";
        obj._anEnum = MyEnum.ONE;

        return obj;
    }
    private void updateObj(TestObj obj, int retriesOnBackPressure, int sleepNanosOnBackPressureRetry) {
        long timeMillis = System.currentTimeMillis();
        int date = PDate.fromMillis(timeMillis);
        int time = PTime.fromMillis(timeMillis);

        obj._anInt = retriesOnBackPressure;
        obj._aLong = sleepNanosOnBackPressureRetry;
        obj._aTimestamp = timeMillis;
        obj._aDate = date;
        obj._aTime = time;

        obj.setTsNanos(System.nanoTime());
    }

    private void updateObj(PingObj obj, int id, long warmup) {
    	long nanoTime = System.nanoTime();
    	obj.setMine((short) 1);
        obj.setTsNanos(nanoTime);
    	obj.setId(id);
    	obj.setPayload(warmup);
    }

    private void recordLatency(PingObj obj) {
    	boolean backPressured = obj.isBackPressured();
		if (!backPressured) {
			long endNanoTime = System.nanoTime();
			long sentNanoTime = obj.getTsNanos();
			long latency = (endNanoTime - sentNanoTime) / 2; // 1/2 RTT
			try {
				_h.recordValue(latency);
			} catch (Exception x) {
				log.info("Error logging value " + latency, x);
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
//			TestParams(retriesOnBackPressure, sleepNanosOnBackPressureRetry, sleepNanosBetweenMessages, tstSize)
				new TestParams(-1, 1_000_000, 1_000_000_000, 100),
				new TestParams(-1, 1_000_000, 100_000_000, 1_000),
				new TestParams(-1, 1_000_000, 10_000_000, 10_000),
				new TestParams(-1, 1_000_000, 1_000_000, 100_000),
				new TestParams(-1, 1_000_000, 100_000, 1_000_000),
				new TestParams(-1, 1_000_000, 50_000, 1_000_000),

// when messages are sufficiently distanced performance is optimal, irrespective of the test size
				new TestParams(-1, 1_000_000, 10_000, 5_000_000),
				new TestParams(-1, 1_000_000, 10_000, 1_000_000),
				new TestParams(-1, 1_000_000, 10_000, 500_000),
				new TestParams(-1, 1_000_000, 10_000, 100_000),
				new TestParams(-1, 1_000_000, 10_000, 10_000),
				new TestParams(-1, 1_000_000, 10_000, 1_000),

				new TestParams(-1, 1_000_000, 5_000, 5_000_000),
				new TestParams(-1, 1_000_000, 5_000, 1_000_000),
				new TestParams(-1, 1_000_000, 5_000, 500_000),
				new TestParams(-1, 1_000_000, 5_000, 100_000),
				new TestParams(-1, 1_000_000, 5_000, 10_000),
				new TestParams(-1, 1_000_000, 5_000, 1_000),
// when messages are close to the back pressure limit performance drops, irrespective of the test size
				new TestParams(-1, 1_000_000, 2_000, 5_000_000),
				new TestParams(-1, 1_000_000, 2_000, 1_000_000),
				new TestParams(-1, 1_000_000, 2_000, 500_000),
				new TestParams(-1, 1_000_000, 2_000, 100_000),
				new TestParams(-1, 1_000_000, 1_000, 5_000_000),
				new TestParams(-1, 1_000_000, 1_000, 1_000_000),
				new TestParams(-1, 1_000_000, 1_000, 500_000),
				new TestParams(-1, 1_000_000, 1_000, 100_000),
// when messages are packed beyond the back pressure limit performance drops significantly, irrespective of the test size
// the number of messages until back pressure is roughly constant irrespective of the interval between messages at about 70K
// message processing falls further and further behind; the number of messages processes in each bucket is roughly constant
				new TestParams(-1, 1_000_000, 900, 100_000),
				new TestParams(-1, 1_000_000, 500, 100_000),
				new TestParams(-1, 1_000_000, 100, 100_000),

// when messages are packed further even if in smaller bursts performance still drops
// latency does not depend on the interval between messages
// latency varies linearly with the position of the message in the burst
// i.e., first messages have lower latencies and later messages have higher latencies
// this suggests a cumulative effect for later messages
				new TestParams(-1, 1_000_000, 500, 100_000),
				new TestParams(-1, 1_000_000, 100, 100_000),

				new TestParams(-1, 1_000_000, 500, 80_000),
				new TestParams(-1, 1_000_000, 100, 80_000),

				new TestParams(-1, 1_000_000, 500, 70_000),
				new TestParams(-1, 1_000_000, 100, 70_000),

				new TestParams(-1, 1_000_000, 500, 60_000),
				new TestParams(-1, 1_000_000, 100, 60_000),

				new TestParams(-1, 1_000_000, 500, 50_000),
				new TestParams(-1, 1_000_000, 100, 50_000),

				new TestParams(-1, 1_000_000, 500, 10_000),
				new TestParams(-1, 1_000_000, 100, 10_000),

				new TestParams(-1, 1_000_000, 500, 1_000),
				new TestParams(-1, 1_000_000, 100, 1_000),
		}
	);

	private static class TestParams implements StatsTestParams {
	    int _retriesOnBackPressure;
	    int _sleepNanosOnBackPressureRetry;
	    int _sleepNanosBetweenMessages;
	    int _tstSize;

		TestParams(int retriesOnBackPressure, int sleepNanosOnBackPressureRetry, int sleepNanosBetweenMessages, int tstSize) {
			_retriesOnBackPressure = retriesOnBackPressure;
			_sleepNanosOnBackPressureRetry = sleepNanosOnBackPressureRetry;
			_sleepNanosBetweenMessages = sleepNanosBetweenMessages;
			_tstSize = tstSize;
		}

		public void updateTestParams() {
			BurstPing._retriesOnBackPressure = _retriesOnBackPressure;
			BurstPing._sleepNanosOnBackPressureRetry = _sleepNanosOnBackPressureRetry;
			BurstPing._sleepNanosBetweenMessages = _sleepNanosBetweenMessages;
			BurstPing._tstSize = _tstSize;
		}
		public String header() {
			return "retries"+TAB+"bpSleep"+TAB+"sleep"+TAB+"tstSize"+TAB;
		}
		public String toString() {
			return _retriesOnBackPressure+TAB+_sleepNanosOnBackPressureRetry+TAB+_sleepNanosBetweenMessages+TAB+_tstSize+TAB;
		}
	}
}
