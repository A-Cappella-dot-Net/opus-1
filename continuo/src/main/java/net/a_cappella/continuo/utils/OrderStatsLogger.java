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

package net.a_cappella.continuo.utils;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import net.a_cappella.continuo.ShutdownHook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Collects per-order round-trip latencies in the line handler, split into four spans:
 * <ul>
 *   <li>d10 - time to process the request on the way out to the exchange (t0..t1)</li>
 *   <li>d21 - request+response network round trip, excluding the exchange's own processing time
 *       {@code d} (t1..t2 - d)</li>
 *   <li>d32 - time to process the response before sending it back to the originator (t2..t3)</li>
 *   <li>d30 - end to end: request in to response out (t0..t3)</li>
 * </ul>
 *
 * <p>Each span is recorded independently into its own rolling window (see {@link LatencyRecorder}):
 * the first {@code warmupCount} orders are discarded, then every {@code sampleCount} orders the
 * histogram is flipped and logged off-thread by a shared {@link StatsReporter}.
 *
 * <p><b>Threading:</b> {@code onReqOut} (d10), {@code onAckNakOut} (d32, d30) run on the processing
 * thread; {@code onAckNakIn} (d21) runs on the pipe thread. Each span therefore has a single writer
 * thread, satisfying the {@code SingleWriterRecorder} contract.
 */
public class OrderStatsLogger {
    private static final Logger log = LoggerFactory.getLogger(OrderStatsLogger.class);

    private static final long HIGHEST_TRACKABLE_VALUE = TimeUnit.MILLISECONDS.toNanos(200);
    private static final int NUMBER_OF_SIGNIFICANT_VALUE_DIGITS = 3;
    private static final int DEFAULT_WARMUP_COUNT = 1000;
    private static final int DEFAULT_SAMPLE_COUNT = 1000;

    private final Map<String, TimeStamps> _map = new ConcurrentHashMap<>();

    private final StatsReporter _reporter;
    private final LatencyRecorder _d10;
    private final LatencyRecorder _d21;
    private final LatencyRecorder _d32;
    private final LatencyRecorder _d30;

    public OrderStatsLogger() {
        this(DEFAULT_WARMUP_COUNT, DEFAULT_SAMPLE_COUNT);
    }

    public OrderStatsLogger(int warmupCount, int sampleCount) {
        this(warmupCount, sampleCount, HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    }

    public OrderStatsLogger(int warmupCount, int sampleCount, long highestTrackableValue, int significantValueDigits) {
        _reporter = new StatsReporter("OrderStatsReporter");
        _d10 = new LatencyRecorder("d10", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        _d21 = new LatencyRecorder("d21", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        _d32 = new LatencyRecorder("d32", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        _d30 = new LatencyRecorder("d30", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        ShutdownHook.registerShutdownAction(this::flushAndStop);
    }

    public void onReqIn(String ordId) {
        log.debug("1. onReqIn {}", ordId);
        _map.put(ordId, new TimeStamps().withT0(System.nanoTime()));
    }

    public void onReqOut(String ordId) {
        log.debug("2. onReqOut {}", ordId);
        TimeStamps ts = _map.get(ordId);
        if (ts != null) {
            long t1 = System.nanoTime();
            ts.withT1(t1);
            _d10.record(t1 - ts._t0);
        } else {
            log.error("onReqOut could not find ordId {}", ordId);
        }
    }

    public void onAckNakIn(String ordId, int d) {
        log.debug("3. onAckNakIn {} {}", ordId, d);
        TimeStamps ts = _map.get(ordId);
        if (ts != null) {
            long t2 = System.nanoTime();
            ts.withT2(t2);
            _d21.record(t2 - ts._t1 - d);
        } else {
            log.error("onAckNakIn could not find ordId {}", ordId);
        }
    }

    public int onAckNakOut(String ordId) {
        log.debug("4. onAckNakOut {}", ordId);
        TimeStamps ts = _map.remove(ordId);
        if (ts != null) {
            long t3 = System.nanoTime();
            _d32.record(t3 - ts._t2);
            _d30.record(t3 - ts._t0);
            return (int) (t3 - ts._t0);
        } else {
            log.error("onAckNakOut could not find ordId {}", ordId);
            return -1;
        }
    }

    private void flushAndStop() {
        _d10.flush();
        _d21.flush();
        _d32.flush();
        _d30.flush();
        _reporter.stop();
    }

    private static class TimeStamps {
        private long _t0;
        private long _t1;
        private long _t2;

        public TimeStamps withT0(long t0) {
            _t0 = t0;
            return this;
        }
        public TimeStamps withT1(long t1) {
            _t1 = t1;
            return this;
        }
        public TimeStamps withT2(long t2) {
            _t2 = t2;
            return this;
        }
    }
}
