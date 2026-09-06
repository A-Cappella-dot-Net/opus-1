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

import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class ExchangeStatsLogger {
    private static final Logger log = LoggerFactory.getLogger(ExchangeStatsLogger.class);

    private static final long HIGHEST_TRACKABLE_VALUE = TimeUnit.MILLISECONDS.toNanos(200);
    private static final int NUMBER_OF_SIGNIFICANT_VALUE_DIGITS = 3;

    private final Histogram _h10 = new Histogram(HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);

    private final Map<String, TimeStamps> _map = new HashMap<>();

    public ExchangeStatsLogger() {
    }

    public void onReqIn(String ordId) {
        _map.put(ordId, new TimeStamps().withT0(System.nanoTime()));
    }

    public int onAckNakOut(String ordId) {
        TimeStamps ts = _map.remove(ordId);
        if (ts != null) {
            long t1 = System.nanoTime();
            _h10.recordValue(t1 - ts._t0);
            log.info("{} d10={}", ordId, t1 - ts._t0);
            return (int) (t1 - ts._t0);
        } else {
            log.error("could not find ordId {}", ordId);
            return -1;
        }
    }

    private static class TimeStamps {
        private long _t0;

        public TimeStamps withT0(long t0) {
            _t0 = t0;
            return this;
        }
    }
}
