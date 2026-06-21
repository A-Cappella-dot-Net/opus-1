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

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.openhft.affinity.Affinity;
import net.openhft.affinity.AffinityLock;
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

    private int _pinToCpu = 0;
    public void setPinToCpu(String pinToCpu) {
        _pinToCpu = net.a_cappella.continuo.utils.Utils.parseAsInt("pinToCpu", pinToCpu, _pinToCpu);
    }

    private volatile CountDownLatch _batchCompletedLatch;
    private CountDownLatch getBatchCompletedLatch() {
        return _batchCompletedLatch;
    }
    private volatile boolean _stop = false;

    private Test _test = new Test();


    public MadBurst(PrestoClient client) {
        _client = client;

        ShutdownHook.registerShutdownAction(() -> _stop = true);
    }

    public void start() throws Exception {
        if (_pinToCpu>0) {
            Affinity.setAffinity(_pinToCpu);
            log.info("Pinned to CPU "+Affinity.getCpu()+" of "+ AffinityLock.BASE_AFFINITY);
        } else {
            log.info("Starting on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
        }

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

        _client.setMaxReads(11_000, 11_000, 1, 1_000);

        outerLoop:
        for (int index = 0; index < _test.testLength(); index++) {
            for (int tstCnt = 0; tstCnt < REPEAT_CNT; tstCnt++) {
                System.gc();
                Thread.sleep(1000);

                if (_stop) break outerLoop;

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
                params = _burst._test._testParams[paramsIdx];
            } else {
                params = _burst._test._warmupParams[- paramsIdx - 1];
            }
            int lastOrderInBatch = params._sectionsPerBatch - 1;
            int lastPriceInBatch = params._pricesPerSection - 1;
            int publicationIntervalMicros = params._publicationIntervalMicros;
            int k = 0;
            for (int i = 0; i < params._sectionsPerBatch; i++) {
                publishOrder(tstCnt, paramsIdx, i == 0, i == lastOrderInBatch);
                Utils.busyMicrosDelay(publicationIntervalMicros);
                for (int j = 0; j < params._pricesPerSection; j++) {
                    publishPrice(tstCnt, paramsIdx, k, i == lastOrderInBatch && j == lastPriceInBatch);
                    Utils.busyMicrosDelay(publicationIntervalMicros);
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
                        params = _burst._test._testParams[paramsIdx];
                    } else {
                        params = _burst._test._warmupParams[- paramsIdx - 1];
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

        private final TestParams[] _warmupParams =
                new TestParams[] {
                        new TestParams(10, 100, 100, 0, 1)
                };

        private final TestParams[] _testParamsSeed = new TestParams[] {
                new TestParams(10, 10, 10),
                new TestParams(10, 100, 10),
                new TestParams(100, 10, 10),
                new TestParams(100, 100, 100)
        };
        private final int[] _publicationIntervals = new int[] {0, 5, 50, 200};
        private final int[] _processingTimes = new int[] {1, 10, 100};

        private final TestParams[] _testParams = new TestParams[_testParamsSeed.length * _publicationIntervals.length * _processingTimes.length];

        public Test() {
            int l = 0;
            for (int k = 0; k < _testParamsSeed.length; k++) {
                for (int j = 0; j < _processingTimes.length; j++) {
                    for (int i = 0; i < _publicationIntervals.length; i++) {
                        _testParams[l++] = new TestParams(_testParamsSeed[k], _publicationIntervals[i], _processingTimes[j]);
                    }
                }
            }
        }

        public int warmupLength() {
            return _warmupParams.length;
        }

        public TestParams warmupParamsAtIndex(int index) {
            return _warmupParams[index];
        }

        public int testLength() {
            return _testParams.length;
        }

        public TestParams testParamsAtIndex(int index) {
            return _testParams[index];
        }

        public void logHeader() {
            _statsLogger.logHeader(headerPrefix() + TestParams.header(), NO_BUCKETS);
        }

        public void logRow(Histogram h, int paramsIdx, String obj, ObjPriority pri, int tstCnt) {
            TestParams params;
            if (paramsIdx >= 0) {
                params = testParamsAtIndex(paramsIdx);
            } else {
                params = warmupParamsAtIndex(- paramsIdx - 1);
            }
            _statsLogger.logRow(h, rowPrefix(obj, pri, tstCnt) + params.row(), NO_BUCKETS);
        }

        private String headerPrefix() {
            return "host" + TAB + "obj" + TAB + "pri " + TAB + "tstCnt" + TAB;
        }
        private String rowPrefix(String obj, ObjPriority pri, int tstCnt) {
            return _localhost + TAB + obj + TAB + pri + TAB + tstCnt + TAB;
        }
    }

    public static class TestParams {
        private final int _sectionsPerBatch;
        private final int _pricesPerSection;
        private final int _uniquePrices;
        private final int _publicationIntervalMicros;
        private final int _processingTimeMicros;

        public TestParams(int sectionsPerBatch, int pricesPerSection, int uniquePrices) {
            _sectionsPerBatch = sectionsPerBatch;
            _pricesPerSection = pricesPerSection;
            _uniquePrices = uniquePrices;
            _publicationIntervalMicros = 0;
            _processingTimeMicros = 0;
        }
        public TestParams(TestParams seed, int pubTm, int procInt) {
            _sectionsPerBatch = seed._sectionsPerBatch;
            _pricesPerSection = seed._pricesPerSection;
            _uniquePrices = seed._uniquePrices;
            _publicationIntervalMicros = pubTm;
            _processingTimeMicros = procInt;
        }

        TestParams(int sectionsPerBatch, int pricesPerSection, int uniquePrices, int publicationIntervalMicros, int processingTimeMicros) {
            _sectionsPerBatch = sectionsPerBatch;
            _pricesPerSection = pricesPerSection;
            _uniquePrices = uniquePrices;
            _publicationIntervalMicros = publicationIntervalMicros;
            _processingTimeMicros = processingTimeMicros;
        }

        public static String header() {
            return "ord"+TAB+"pri"+TAB+"unq"+TAB+"pubInt"+TAB+"procTm"+TAB;
        }
        public String row() {
            return _sectionsPerBatch +TAB+_pricesPerSection+TAB+_uniquePrices+TAB+_publicationIntervalMicros+TAB+_processingTimeMicros+TAB;
        }
    }
}
