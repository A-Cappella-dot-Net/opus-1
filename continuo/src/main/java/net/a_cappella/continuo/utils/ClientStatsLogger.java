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

import net.a_cappella.continuo.ShutdownHook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class ClientStatsLogger {
    private static final Logger log = LoggerFactory.getLogger(ClientStatsLogger.class);

    private static final long HIGHEST_TRACKABLE_VALUE = TimeUnit.MILLISECONDS.toNanos(200);
    private static final int NUMBER_OF_SIGNIFICANT_VALUE_DIGITS = 3;

    private final Map<String, TimeStamps> _map = new HashMap<>();

    private final StatsReporter _reporter;
    private final LatencyRecorder _d;

    public ClientStatsLogger(int warmupCount, int sampleCount) {
        this(warmupCount, sampleCount, HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    }

    public ClientStatsLogger(int warmupCount, int sampleCount, long highestTrackableValue, int significantValueDigits) {
        _reporter = new StatsReporter("ClientStatsReporter");
        _d = new LatencyRecorder("d", _reporter, warmupCount, sampleCount, highestTrackableValue, significantValueDigits);
        ShutdownHook.registerShutdownAction(this::flushAndStop);
    }

    public void onReqOut(String ordId) {
        _map.put(ordId, new TimeStamps().withT0(System.nanoTime()));
    }

    public void onAckNakIn(String ordId, int d) {
        TimeStamps ts = _map.remove(ordId);
        if (ts != null) {
            long t1 = System.nanoTime();
            _d.record(t1 - ts._t0 - d);
        } else {
            log.error("could not find ordId {}", ordId);
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
