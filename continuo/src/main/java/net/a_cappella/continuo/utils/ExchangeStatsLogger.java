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

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import net.a_cappella.continuo.ShutdownHook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Simplified stats logger for the exchange - the final stage in the pipeline. It measures a single
 * span, {@code d}: the time the exchange takes to acknowledge or reject a request (t0..t1). This is
 * the same quantity the line handler subtracts from its d21 network measurement.
 *
 * <p>Recording follows the same rolling-window scheme as {@link OrderStatsLogger} (warmup discard,
 * then flip-and-log off-thread every sample window). {@link #onAckNakOut} always returns the measured
 * value regardless of warmup, since the exchange transmits it to the line handler on every order.
 *
 * <p><b>Threading:</b> the exchange handles each order on a single thread, so both the map (a plain
 * {@link HashMap}) and the single {@code d} recorder are accessed by one thread only.
 */
public class ExchangeStatsLogger {
    private static final Logger log = LoggerFactory.getLogger(ExchangeStatsLogger.class);

    private static final long HIGHEST_TRACKABLE_VALUE = TimeUnit.MILLISECONDS.toNanos(200);
    private static final int NUMBER_OF_SIGNIFICANT_VALUE_DIGITS = 3;

    private final Map<String, TimeStamps> _map = new HashMap<>();

    private final StatsReporter _reporter;
    private final LatencyRecorder _d;

    public ExchangeStatsLogger(int warmupCount, int sampleCount) {
        this(warmupCount, sampleCount, HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    }

    public ExchangeStatsLogger(int warmupCount, int sampleCount, long highestTrackableValue, int significantValueDigits) {
        _reporter = new StatsReporter("ExchangeStatsReporter");
        _d = new LatencyRecorder("d", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        ShutdownHook.registerShutdownAction(this::flushAndStop);
    }

    public void onReqIn(String ordId) {
        _map.put(ordId, new TimeStamps().withT0(System.nanoTime()));
    }

    public int onAckNakOut(String ordId) {
        TimeStamps ts = _map.remove(ordId);
        if (ts != null) {
            long t1 = System.nanoTime();
            long d = t1 - ts._t0;
            _d.record(d);
            return (int) d;
        } else {
            log.error("could not find ordId {}", ordId);
            return -1;
        }
    }

    private void flushAndStop() {
        _d.flush();
        _reporter.stop();
    }

    private static class TimeStamps {
        private long _t0;

        public TimeStamps withT0(long t0) {
            _t0 = t0;
            return this;
        }
    }
}
