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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

public class OrderStatsLogger {
    private static final Logger log = LoggerFactory.getLogger(OrderStatsLogger.class);

    private static final long HIGHEST_TRACKABLE_VALUE = TimeUnit.MILLISECONDS.toNanos(200);
    private static final int NUMBER_OF_SIGNIFICANT_VALUE_DIGITS = 3;

    private final Histogram _h10 = new Histogram(HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    private final Histogram _h21 = new Histogram(HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    private final Histogram _h32 = new Histogram(HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);
    private final Histogram _h30 = new Histogram(HIGHEST_TRACKABLE_VALUE, NUMBER_OF_SIGNIFICANT_VALUE_DIGITS);

    private final Map<String, TimeStamps> _map = new ConcurrentHashMap<>();

    public OrderStatsLogger() {
    }

    public void onReqIn(String ordId) {
        log.info("1. onReqIn {}", ordId);
        _map.put(ordId, new TimeStamps().withT0(System.nanoTime()));
    }

    public void onReqOut(String ordId) {
        log.info("2. onReqOut {}", ordId);
        TimeStamps ts = _map.get(ordId);
        if (ts != null) {
            long t1 = System.nanoTime();
            ts.withT1(t1);
            _h10.recordValue(t1 - ts._t0);
            log.info("{} d10={}", ordId, t1 - ts._t0);
        } else {
            log.error("onReqOut could not find ordId {}", ordId);
        }
    }

    public void onAckNakIn(String ordId, int d) {
        log.info("3. onAckNakIn {} {}", ordId, d);
        TimeStamps ts = _map.get(ordId);
        if (ts != null) {
            long t2 = System.nanoTime();
            ts.withT2(t2);
            _h21.recordValue(t2 - ts._t1 - d);
            log.info("{} d21={}", ordId, t2 - ts._t1 - d);
        } else {
            log.error("onAckNakIn could not find ordId {}", ordId);
        }
    }

    public int onAckNakOut(String ordId) {
        log.info("4. onAckNakOut {}", ordId);
        TimeStamps ts = _map.remove(ordId);
        if (ts != null) {
            long t3 = System.nanoTime();
            _h32.recordValue(t3 - ts._t2);
            _h30.recordValue(t3 - ts._t0);
            log.info("{} d32={}", ordId, t3 - ts._t2);
            log.info("{} d30={}", ordId, t3 - ts._t0);
            return (int) (t3 - ts._t0);
        } else {
            log.error("onAckNakOut could not find ordId {}", ordId);
            return -1;
        }
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
