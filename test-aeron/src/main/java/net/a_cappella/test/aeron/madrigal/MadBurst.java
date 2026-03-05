package net.a_cappella.test.aeron.madrigal;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class MadBurst {
    private static final Logger log = LoggerFactory.getLogger(MadBurst.class);

    private static final String TAB = StatsLogger.TAB;
    private static final int REPEAT_CNT = 10;

    private final PrestoClient _client;

    private volatile CountDownLatch _batchCompletedLatch;
    private CountDownLatch getBatchCompletedLatch() {
        return _batchCompletedLatch;
    }

    private Test _test = new Test();


    public MadBurst(PrestoClient client) {
        _client = client;
    }

    public void start() throws Exception {
        _client.waitUntilInitialized();

        _test.logHeader();

        new Subscriber(this).start();

        Publisher publisher = new Publisher(this);
        publisher.init();

        for (int index = 0; index < _test.warmupLength(); index++) {
            for (int tstCnt = 0; tstCnt < REPEAT_CNT; tstCnt++) {
                _batchCompletedLatch = new CountDownLatch(1);
                publisher.publishBatch((byte) tstCnt, -1 - index);
                _batchCompletedLatch.await();
            }
        }

        _client.setMaxReads(10_000, 10_000, 1, 1_000);

        for (int index = 0; index < _test.testLength(); index++) {
            for (int tstCnt = 0; tstCnt < REPEAT_CNT; tstCnt++) {
                System.gc();
                Thread.sleep(1000);

                log.info("---------------------------------------");
                _client.resetStats();
                _batchCompletedLatch = new CountDownLatch(1);
                publisher.publishBatch((byte) tstCnt, index);
                _batchCompletedLatch.await();
                _client.logStats();
            }
        }

        Thread.sleep(1000);
        System.exit(0);
    }










    public static class Publisher {
        private final MadBurst _burst;
        private final PrestoClient _client;

        private final OrderObj _order = new OrderObj();
        private final EcnPriceObj _price = new EcnPriceObj();
        private String[] _instrIds = new String[1_000];

        public Publisher(MadBurst burst) {
            _burst = burst;
            _client = burst._client;
        }

        public void init() {
            _order.setAddRequest("ecn", "uid", "ordId", 0, "clOrdId", "instrId",
                    MadrigalOrdType.MARKET, MadrigalTimeInForce.DAY, MadrigalSide.Buy, 0.0, 100.0, 100.0, 0);
            _price.setEcn("ecn");
            _price.stale();
            for (int i = 0; i < 1_000; i++) {
                _instrIds[i] = String.format("I%03d", i);
            }
        }

        public void publishBatch(byte tstCnt, int paramsIdx) throws Exception {
            TestParams params;
            if (paramsIdx >= 0) {
                params = _burst._test.testParams[paramsIdx];
            } else {
                params = _burst._test.warmupParams[- paramsIdx - 1];
            }
            int lastOrderInBatch = params._sectionsPerBatch - 1;
            int lastPriceInBatch = params._pricesPerSection - 1;
            int k = 0;
            for (int i = 0; i < params._sectionsPerBatch; i++) {
                publishOrder(tstCnt, paramsIdx, i == 0, i == lastOrderInBatch);
                for (int j = 0; j < params._pricesPerSection; j++) {
                    publishPrice(tstCnt, paramsIdx, k, i == lastOrderInBatch && j == lastPriceInBatch);
                    k++;
                    if (k == params._uniquePrices) {
                        k = 0;
                    }
                }
            }
        }

        private int publishOrder(int tstCnt, int paramsIdx, boolean firstOrderInBatch, boolean lastOrderInBatch) throws Exception {
            long tsNanos = System.nanoTime();
            _order.setMine((short) ((firstOrderInBatch) ? 1 : ((lastOrderInBatch) ? 2 : 0)));
            _order.setTsNanos(tsNanos);
            _order.setTs(tstCnt);
            _order.setTsx(paramsIdx);
            return _client.publish(_order);
        }

        private int publishPrice(int tstCnt, int paramsIdx, int instrIdx, boolean lastPriceInBatch) throws Exception {
            long tsNanos = System.nanoTime();
            _price.setMine((short) ((lastPriceInBatch) ? 1 : 0));
            _price.setTsNanos(tsNanos);
            _price.setTs(tstCnt);
            _price.setTsx(paramsIdx);
            _price.setInstrId(_instrIds[instrIdx]);
            return _client.publish(_price);
        }
    }

    public static class Subscriber {
        private int _processingTimeMicros;
        private boolean _lastOrderInBatch;
        private boolean _lastPriceInBatch;

        private final Histogram _hOrder = new Histogram(TimeUnit.MILLISECONDS.toNanos(10_000), 3);
        private final Histogram _hPrice = new Histogram(TimeUnit.MILLISECONDS.toNanos(10_000), 3);

        private final MadBurst _burst;

        public Subscriber(MadBurst burst) {
            _burst = burst;
        }

        public void start() throws Exception {
            _burst._client.subscribe("select * from order", (obj, subsId) -> {
                boolean firstOrderInBatch = obj.getMine() == 1;
                _lastOrderInBatch = obj.getMine() == 2;

                OrderObj order = (OrderObj) obj;
                int tstCnt = (int) order.getTs();
                int paramsIdx = (int) order.getTsx();

                if (firstOrderInBatch) {
                    TestParams params;
                    if (paramsIdx >= 0) {
                        params = _burst._test.testParams[paramsIdx];
                    } else {
                        params = _burst._test.warmupParams[- paramsIdx - 1];
                    }

                    _processingTimeMicros = params._processingTimeMicros;
                }

                recordLatency(obj, _hOrder);
                Utils.busyMicrosDelay(_processingTimeMicros); // simulate execution

                if (_lastPriceInBatch && _lastOrderInBatch) {
                    completeBatch(paramsIdx, tstCnt);
                }
            });

            _burst._client.subscribe("select * from ecn.price", (obj, subsId) -> {
                recordLatency(obj, _hPrice);
                Utils.busyMicrosDelay(_processingTimeMicros); // simulate execution

                EcnPriceObj price = (EcnPriceObj) obj;
                int tstCnt = (int) price.getTs();
                int paramsIdx = (int) price.getTsx();

                _lastPriceInBatch = price.getMine() == 1;
                if (_lastPriceInBatch && _lastOrderInBatch) {
                    completeBatch(paramsIdx, tstCnt);
                }
            });
        }

        private void completeBatch(int paramsIdx, int tstCnt) {
            if (paramsIdx >= 0) { // not warmup
                _burst._test.logRow(_hOrder, paramsIdx, "order", Test._orderPriority, tstCnt);
                _burst._test.logRow(_hPrice, paramsIdx, "price", Test._pricePriority, tstCnt);
            }
            _hOrder.reset();
            _hPrice.reset();

            _lastPriceInBatch = false;
            _lastOrderInBatch = false;
            _burst.getBatchCompletedLatch().countDown(); // proceed to the next test
        }

        private void recordLatency(Obj obj, Histogram histogram) {
            long startNanoTime = obj.getTsNanos();
            long endNanoTime = System.nanoTime();

            if (startNanoTime > 0) {
                long latency = endNanoTime - startNanoTime;
                try {
                    histogram.recordValue(latency);
                } catch (Exception x) {
                    log.info("Error logging value " + latency, x);
                }
            }
        }
    }

    public static class Test {
        private static final int NO_BUCKETS = 10;

        private final StatsLogger _statsLogger = new StatsLogger(log, false, 10);
        private static final String _localhost = Utils._localhost;
        public static final ObjPriority _pricePriority = new EcnPriceObj().getPriority();
        public static final ObjPriority _orderPriority = new OrderObj().getPriority();

        public int warmupLength() {
            return warmupParams.length;
        }

        public TestParams warmupParamsAtIndex(int index) {
            return warmupParams[index];
        }

        public int testLength() {
            return testParams.length;
        }

        public TestParams testParamsAtIndex(int index) {
            return testParams[index];
        }

        public void logHeader() {
            _statsLogger.logHeader(testHeader() + TestParams.header(), NO_BUCKETS);
        }

        public void logRow(Histogram h, int paramsIdx, String obj, ObjPriority pri, int tstCnt) {
            TestParams params;
            if (paramsIdx >= 0) {
                params = testParamsAtIndex(paramsIdx);
            } else {
                params = warmupParamsAtIndex(- paramsIdx - 1);
            }
            _statsLogger.logRow(h, testRow(obj, pri, tstCnt) + params.row(), NO_BUCKETS);
        }




        private String testHeader() {
            return "host" + TAB + "obj" + TAB + "pri " + TAB + "tstCnt" + TAB;
        }
        private String testRow(String obj, ObjPriority pri, int tstCnt) {
            return _localhost + TAB + obj + TAB + pri + TAB + tstCnt + TAB;
        }

        private final TestParams[] warmupParams =
                new TestParams[] {
                        new TestParams(10, 10, 100, 1)
                };

        private final TestParams[] testParams =
                new TestParams[] {
                        new TestParams(10, 10, 10, 1),
                        new TestParams(10, 10, 10, 10),
                        new TestParams(10, 10, 10, 100),
                        new TestParams(10, 10, 100, 1),
                        new TestParams(10, 10, 100, 10),
                        new TestParams(10, 10, 100, 100),
                        new TestParams(100, 100, 10, 1),
                        new TestParams(100, 100, 10, 10),
                        new TestParams(100, 100, 10, 100),
                        new TestParams(100, 100, 100, 1),
                        new TestParams(100, 100, 100, 10),
                        new TestParams(100, 100, 100, 100),
                };
    }

    public static class TestParams {
        private final int _pricesPerSection;
        private final int _uniquePrices;
        private final int _sectionsPerBatch;
        private final int _processingTimeMicros;

        TestParams(int pricesPerSection, int uniquePrices, int sectionsPerBatch, int processingTimeMicros) {
            _pricesPerSection = pricesPerSection;
            _uniquePrices = uniquePrices;
            _sectionsPerBatch = sectionsPerBatch;
            _processingTimeMicros = processingTimeMicros;
        }

        public static String header() {
            return "spb"+TAB+"pps"+TAB+"up"+TAB+"ptm"+TAB;
        }
        public String row() {
            return _sectionsPerBatch+TAB+_pricesPerSection+TAB+_uniquePrices+TAB+_processingTimeMicros+TAB;
        }
    }
}
