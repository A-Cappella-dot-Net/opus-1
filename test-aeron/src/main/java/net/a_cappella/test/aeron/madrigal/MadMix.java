package net.a_cappella.test.aeron.madrigal;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.CountDownLatch;

public class MadMix {
    private static final Logger log = LoggerFactory.getLogger(MadMix.class);

    private static final String TAB = StatsLogger.TAB;

    public static final int WUP_SIZE = 1_000_000;
    public static final int TST_SIZE = 1_000_000;

    private static final int REPEAT_CNT = 5;

    private final StatsLogger _statsLogger = new StatsLogger(log, false, 10);

	private static final String _localhost = Utils._localhost;
    private final String _channelType;
    private final String _mediaDriverType;

    private final PrestoClient _client;
    public PrestoClient getClient() {
		return _client;
	}

	private MadHiPri _madHiPri;
	private MadConf _madConf;
	private MadRegPri _madRegPri;
	private MadLowPri _madLowPri;

	private CountDownLatch _cycleCompletedLatch;
	private CountDownLatch _startLatch;
    public CountDownLatch getStartLatch() {
		return _startLatch;
	}
    private CountDownLatch _endLatch;
	public CountDownLatch getEndLatch() {
		return _endLatch;
	}
	public enum TestingPhase {STARTING, WARMUP, BREAK, TESTING, DONE}
	private volatile TestingPhase _testingPhase = TestingPhase.DONE;
    public TestingPhase getTestingPhase() {
		return _testingPhase;
	}
	public void setTestingPhase(TestingPhase testingPhase) {
		_testingPhase = testingPhase;
	}

	private final PingObj _pingObj = new PingObj();

    private static final boolean MINE_IN_SQL = false;
    private static final String _sql = (MINE_IN_SQL) ? "select * from ping where mine=1" : "select * from ping";

    public MadMix(PrestoClient client, String channelType, String mediaDriverType) {
    	_client = client;
    	_channelType = channelType;
    	_mediaDriverType = mediaDriverType;
    }

    public void start() throws Exception {
    	_madHiPri = new MadHiPri(this, false);
    	_madConf = new MadConf(this, false);
    	_madRegPri = new MadRegPri(this, false);
    	_madLowPri = new MadLowPri(this, false);

    	_client.waitUntilInitialized();

    	_statsLogger.dataPointHeader(configHeader() + TestParams.header());

		_client.subscribe(_sql, (obj, subsId) -> {
			if (MINE_IN_SQL || obj.getMine() == (short) 1) {
		    	_cycleCompletedLatch.countDown();
			}
		});

		for (int index=0; index<_testParamsArray.length; index++) {
			for (int tstCnt=0; tstCnt<REPEAT_CNT; tstCnt++) {
				TestParams params = _testParamsArray[index];

				_client.setMaxReads(params.getMaxRead0(), params.getMaxRead1(), params.getMaxRead2(), params.getMaxRead3());
				_client.resetStats();

				System.gc();
		        Thread.sleep(2000);

				log.info("---------------------------------------");

				updateObj(_pingObj, (short) 0);
		        log.debug(">>> "+_pingObj);
		        publish(_pingObj);

		    	_cycleCompletedLatch = new CountDownLatch(1);

				_madHiPri.getHistogram().reset();
				_madConf.getHistogram().reset();
				_madRegPri.getHistogram().reset();
				_madLowPri.getHistogram().reset();

		    	startCycle(params);

		    	updateObj(_pingObj, (short) 1);
		        log.debug(">>> "+_pingObj);
		        publish(_pingObj);
		        
		        _cycleCompletedLatch.await();

		    	endCycle();

		    	_statsLogger.logResults(_madHiPri.getHistogram(), currentConfigValues() + params.values("hi", tstCnt));
		    	_statsLogger.logResults(_madConf.getHistogram(), currentConfigValues() + params.values("conf", tstCnt));
		    	_statsLogger.logResults(_madRegPri.getHistogram(), currentConfigValues() + params.values("reg", tstCnt));
		    	_statsLogger.logResults(_madLowPri.getHistogram(), currentConfigValues() + params.values("low", tstCnt));

				_client.logStats();
			}
		}

		Thread.sleep(1000);
		System.exit(0);
    }

    private void startCycle(final TestParams params) throws InterruptedException {
    	_startLatch = new CountDownLatch(1);
    	_endLatch = new CountDownLatch(4);
    	_testingPhase = TestingPhase.STARTING;

    	new Thread(() -> _madHiPri.startCycle(params)).start();
    	new Thread(() -> _madConf.startCycle(params)).start();
    	new Thread(() -> _madRegPri.startCycle(params)).start();
    	new Thread(() -> _madLowPri.startCycle(params)).start();

    	_startLatch.countDown();
    	_endLatch.await();
    }
    private void endCycle() {
    	_madHiPri.endCycle();
    	_madConf.endCycle();
    	_madRegPri.endCycle();
    	_madLowPri.endCycle();
    }

    private void updateObj(PingObj obj, short mine) {
        obj.setMine(mine);
    }

    public int publish(Obj obj) throws Exception {
    	return _client.publish(obj);
    }

    public void reply(Obj obj, PubType pubType) throws Exception {
		_client.reply(obj, pubType);
    }





	public String configHeader() {
		return "host" + TAB + "chType" + TAB + "mdType" + TAB;
	}
	public String currentConfigValues() {
		return _localhost + TAB + _channelType + TAB + _mediaDriverType + TAB;
	}

	private final TestParams[] _testParamsArray =
		new TestParams[] {
//			TestParams(maxRd0, maxRd1, maxRd2, maxRd3, oneInN, burstCnt, lullCnt, sleepMillis, busyMicros, burstSize)
//				new TestParams(1, 10, 1, 100, 1, 1, 1, 100, 10, 1000),
//				new TestParams(5, 10, 1, 100, 1, 1, 1, 100, 10, 1000),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 10),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 100),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 1000),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 10),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 100),
				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 10, 1000),
//				new TestParams(20, 10, 1, 100, 1, 1, 1, 100, 10, 1000),
//				new TestParams(10, 10, 1, 100, 1, 1, 1, 100, 20, 1000),
//				new TestParams(10, 10, 1, 100, 4, 1, 1, 100, 10, 1000),
		};

	public static class TestParams {
		private final int _maxRead0;
		private final int _maxRead1;
		private final int _maxRead2;
		private final int _maxRead3;
	    private final int _oneInN;
	    private final int _burstCnt;
	    private final int _lullCnt;
	    private final int _sleepMillis;
	    private final int _busyMicros;
	    private final int _burstSize; // lowPri only

		TestParams(int maxRead0, int maxRead1, int maxRead2, int maxRead3, int oneInN, int burstCnt, int lullCnt, int sleepMillis, int busyMicros, int batchCnt) {
			_maxRead0 = maxRead0;
			_maxRead1 = maxRead1;
			_maxRead2 = maxRead2;
			_maxRead3 = maxRead3;
			_oneInN = oneInN;
			_burstCnt = burstCnt;
			_lullCnt = lullCnt;
			_sleepMillis = sleepMillis;
			_busyMicros = busyMicros;
			_burstSize = batchCnt;
		}

		public int getMaxRead0() {
			return _maxRead0;
		}
		public int getMaxRead1() {
			return _maxRead1;
		}
		public int getMaxRead2() {
			return _maxRead2;
		}
		public int getMaxRead3() {
			return _maxRead3;
		}
		public int getOneInN() {
			return _oneInN;
		}
		public int getBurstCnt() {
			return _burstCnt;
		}
		public int getLullCnt() {
			return _lullCnt;
		}
		public int getSleepMillis() {
			return _sleepMillis;
		}
		public int getBusyMicros() {
			return _busyMicros;
		}
		public int getBurstSize() {
			return _burstSize;
		}

		public static String header() {
			return "pri"+TAB+"tstCnt"+TAB+"maxRd0"+TAB+"maxRd1"+TAB+"maxRd2"+TAB+"maxRd3"+TAB+"oneInN"+TAB+"burst"+TAB+"lull"+TAB+"sleep"+TAB+"busy"+TAB+"burst"+TAB;
		}
		public String values(String pri, int tstCnt) {
			return pri+TAB+tstCnt+TAB+_maxRead0+TAB+_maxRead1+TAB+_maxRead2+TAB+_maxRead3+TAB+_oneInN+TAB+_burstCnt+TAB+_lullCnt+TAB+_sleepMillis+TAB+_busyMicros+TAB+_burstSize+TAB;
		}
	}
}
