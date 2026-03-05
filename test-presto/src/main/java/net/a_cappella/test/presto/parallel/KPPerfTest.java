package net.a_cappella.test.presto.parallel;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.TestMsg;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.StatsLogger;

public class KPPerfTest implements IKPHandler<String, Histogram> {
    private static final Logger log = LoggerFactory.getLogger(KPPerfTest.class);

    private static final String NL = System.lineSeparator();
    private static final String TAB = StatsLogger.TAB;
    private static final int REPEAT_CNT = 5;
    private static final int STAT_FREQ_CNT = 10;
    private static final boolean SAMPLE_POOL_STATS = true;
    private static final String LOCALHOST = Utils._localhost;

    private static final String INITIAL_POOL_SIZE = "-i";
    private static final String POOL_SIZE_INCREMENT = "-r";
    private static final String WARMUP_COUNT = "-wc";
    private static final String TEST_COUNT = "-tc";

    private static int _initialPoolSize = 10_000;
    private static int _poolSizeIncrement = 10;
    private static int _warmupCnt = 1_000_000;
    private static int _testCnt = 1_000_000;

    private final StatsLogger _statsLogger = new StatsLogger(log, false, 10);

    private static final String[] _keys = new String[]{
            "k0", "k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8", "k9",
            "k10", "k11", "k12", "k13", "k14", "k15", "k16", "k17", "k18", "k19",
            "k20", "k21", "k22", "k23", "k24", "k25", "k26", "k27", "k28", "k29",
            "k30", "k31", "k32", "k33", "k34", "k35", "k36", "k37", "k38", "k39",
            "k40", "k41", "k42", "k43", "k44", "k45", "k46", "k47", "k48", "k49",
            "k50", "k51", "k52", "k53", "k54", "k55", "k56", "k57", "k58", "k59",
            "k60", "k61", "k62", "k63", "k64", "k65", "k66", "k67", "k68", "k69",
    };

    private static int _testIndex;
    private static int _numThreads;
    private static TestParams _params;


    private final MsgInstantiator _msgInstantiator = new MsgInstantiator("test.presto.parallel.KPTestMsg");
    private final ObjectManager _objectManager = ObjectManager.getInstance();

    public KPPerfTest(String[] args) throws Exception {
        parseArgs(args);
        _statsLogger.logHeader(configHeader() + TestParams.header());
        _objectManager.setMsgInstantiators(Arrays.asList(_msgInstantiator));
    }


    private static void parseArgs(String[] args) throws Exception {
        if (args.length % 2 != 0) {
            log.error("Please provide an even number of arguments. Usage:");
            log.error(usage());
            Thread.sleep(100);
            System.exit(-1);
        }
        for (int i = 0; i < args.length / 2; i++) {
            String key = args[2 * i];
            String val = args[2 * i + 1];
            switch (key) {
                case INITIAL_POOL_SIZE:
                    _initialPoolSize = Integer.parseInt(val);
                    break;
                case POOL_SIZE_INCREMENT:
                    _poolSizeIncrement = Integer.parseInt(val);
                    break;
                case WARMUP_COUNT:
                    _warmupCnt = Integer.parseInt(val);
                    break;
                case TEST_COUNT:
                    _testCnt = Integer.parseInt(val);
                    break;
                default:
                    log.error("Unknown param " + key + " Usage:");
                    log.error(usage());
                    Thread.sleep(100);
                    System.exit(-1);
            }
        }
    }

    private static String usage() {
        return NL + INITIAL_POOL_SIZE + " " + _initialPoolSize +
                POOL_SIZE_INCREMENT + " " + _poolSizeIncrement +
                WARMUP_COUNT + " " + _warmupCnt +
                TEST_COUNT + " " + _testCnt;
    }

    @SuppressWarnings("unused")
    private void testLoop() throws InterruptedException {
        Pool<TestMsg> pool = null;
        if (_params._usePool) {
            pool = new Pool<>(_params._useCas, _msgInstantiator, _initialPoolSize, _poolSizeIncrement);
            _objectManager.setMsgPools(Arrays.asList(pool));
        }

        IKeyedParallelizer<String> kpll = new KeyedParallelizer<>(this, _numThreads,
                () -> new Histogram(TimeUnit.SECONDS.toMicros(2), 3));
        kpll.init();

        int warmupIterations = _warmupCnt * _numThreads;
        int testIterations = _testCnt * _numThreads;

        int warmupFreq = 0;
        int testFreq = 0;
        if (SAMPLE_POOL_STATS && _params._usePool) {
            warmupFreq = warmupIterations / STAT_FREQ_CNT;
            testFreq = testIterations / STAT_FREQ_CNT;
        	pool.initPoolStats(STAT_FREQ_CNT + STAT_FREQ_CNT);
        }

        for (int i = 0; i < warmupIterations; i++) {
            if (SAMPLE_POOL_STATS && _params._usePool && i % warmupFreq == 0) {
            	pool.recordPoolStats();
            }
            KPTestMsg msg = _objectManager.acquire(PrestoConstants.TEST_MSG);
            msg.setTimeNanos(-System.nanoTime());
            msg.setThreadKey(_keys[i % _numThreads]);
            kpll.parallelize(msg);
            int warmupSleep = _params._wupSleep;
            if (warmupSleep > 0) Utils.busyMicrosDelay(warmupSleep);
        }
        Thread.sleep(1000);
        for (int i = 0; i < testIterations; i++) {
            if (SAMPLE_POOL_STATS && _params._usePool && i % testFreq == 0) {
            	pool.recordPoolStats();
            }
            KPTestMsg msg = _objectManager.acquire(PrestoConstants.TEST_MSG);
            msg.setThreadKey(_keys[i % _numThreads]);
            msg.setTimeNanos(System.nanoTime());
            kpll.parallelize(msg);
            int testSleep = _params._tstSleep;
            if (testSleep > 0) Utils.busyMicrosDelay(testSleep);
        }
        Thread.sleep(1000);
        for (int i = 0; i < _numThreads; i++) {
            KPTestMsg msg = _objectManager.acquire(PrestoConstants.TEST_MSG);
            msg.setTimeNanos(0);
            msg.setThreadKey(_keys[i]);
            kpll.parallelize(msg);
        }
        Thread.sleep(500);

        if (SAMPLE_POOL_STATS && _params._usePool) {
        	log.info("Pool Stats " + pool.getPoolStats());
        }
    }

    @Override
    public boolean handleMessage(IKPMessage<String> t, Histogram h) {
        if (t instanceof TestMsg) {
            TestMsg msg = (TestMsg) t;
            long msgNanos = msg.getTimeNanos();
            msg.stopUsing();
            if (msgNanos == 0) {
                _statsLogger.logRow(h, currentConfigValues() + _params.values(_testIndex));
                h.reset();
            } else if (msgNanos < 0) {
                // ignore, warmup
            } else {
                long delta = System.nanoTime() - msgNanos;
                h.recordValue(delta / 1000);
            }
        }
        return false;
    }


    public static void main(String[] args) throws Exception {
        KPPerfTest instance = new KPPerfTest(args);

        for (int index = 0; index < _testParamsArray.length; index++) {
            _params = _testParamsArray[index];

            int numProcessors = Runtime.getRuntime().availableProcessors();
            for (_numThreads = 1; _numThreads < numProcessors; _numThreads++) {
                if (_numThreads <= _params._threadCnt || _numThreads >= numProcessors - _params._threadCnt) {
                    for (_testIndex = 0; _testIndex < REPEAT_CNT; _testIndex++) {
                        instance.testLoop();
                    }
                }
            }

            for (_numThreads = numProcessors-1; _numThreads >= 1; _numThreads--) {
                if (_numThreads <= _params._threadCnt || _numThreads >= numProcessors - _params._threadCnt) {
                    for (_testIndex = 0; _testIndex < REPEAT_CNT; _testIndex++) {
                        instance.testLoop();
                    }
                }
            }
        }

        System.exit(0);
    }


    public String configHeader() {
        return "host" + TAB + "pSz" + TAB + "pSzInc" + TAB + "wupCnt" + TAB + "tstCnt" + TAB;
    }

    public String currentConfigValues() {
        return LOCALHOST + TAB + _initialPoolSize + TAB + _poolSizeIncrement + TAB + _warmupCnt + TAB + _testCnt + TAB;
    }

    private static final TestParams[] _testParamsArray =
            new TestParams[]{
                    // boolean usePool, boolean useCas, int threadCnt, int wupSleep, int tstSleep
                    new TestParams(true, true, 3, 0, 0),
                    new TestParams(true, true, 3, 1, 1),
                    new TestParams(true, true, 3, 5, 5),
                    new TestParams(true, true, 3, 10, 10),

                    new TestParams(true, false, 3, 0, 0),
                    new TestParams(true, false, 3, 1, 1),
                    new TestParams(true, false, 3, 5, 5),
                    new TestParams(true, false, 3, 10, 10),

                    new TestParams(false, false, 3, 0, 0),
                    new TestParams(false, false, 3, 1, 1),
                    new TestParams(false, false, 3, 5, 5),
                    new TestParams(false, false, 3, 10, 10),
            };

    public static class TestParams {
        private final boolean _usePool;
        private final boolean _useCas;
        private final int _threadCnt;
        private final int _wupSleep;
        private final int _tstSleep;

        TestParams(boolean usePool, boolean useCas, int threadCnt, int wupSleep, int tstSleep) {
            _usePool = usePool;
            _useCas = useCas;
            _threadCnt = threadCnt;
            _wupSleep = wupSleep;
            _tstSleep = tstSleep;
        }

        public boolean isUsePool() {
            return _usePool;
        }

        public boolean isUseCas() {
            return _useCas;
        }

        public int getThreadCnt() {
            return _threadCnt;
        }

        public int getWupSleep() {
            return _wupSleep;
        }

        public int getTstSleep() {
            return _tstSleep;
        }

        public static String header() {
            return "tstCnt" + TAB + "usePool" + TAB + "useCas" + TAB + "thrdCnt" + TAB + "wupSlp" + TAB + "tstSlp" + TAB;
        }

        public String values(int tstCnt) {
            return tstCnt + TAB + _usePool + TAB + _useCas + TAB + _numThreads + TAB + _wupSleep + TAB + _tstSleep + TAB;
        }
    }
}
