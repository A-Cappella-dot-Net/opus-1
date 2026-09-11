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

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;

import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Background thread that logs completed interval histograms handed off by {@link LatencyRecorder}s,
 * so that percentile computation and I/O never run on the latency-critical recording threads.
 *
 * <p>{@link #submit} is called from the recording threads (one per metric); the histogram passed in
 * is a fresh interval snapshot produced by {@code SingleWriterRecorder.getIntervalHistogram()} and is
 * never touched again by the recorder, so it can be read here without further synchronization.
 */
public class StatsReporter {
    private static final Logger log = LoggerFactory.getLogger(StatsReporter.class);

    private static final class Sample {
        private final String _name;
        private final Histogram _histogram;
        private Sample(String name, Histogram histogram) {
            _name = name;
            _histogram = histogram;
        }
    }

    private static final Sample POISON = new Sample(null, null);

    private final BlockingQueue<Sample> _queue = new LinkedBlockingQueue<>();
    private final Thread _thread;

    public StatsReporter(String threadName) {
        _thread = new Thread(this::run, threadName);
        _thread.setDaemon(true);
        _thread.start();
    }

    /** Hand off a completed interval snapshot for asynchronous logging. Called on a recording thread. */
    public void submit(String name, Histogram interval) {
        _queue.add(new Sample(name, interval));
    }

    /** Signal the reporter to drain everything already submitted, then wait (briefly) for it to exit. */
    public void stop() {
        _queue.add(POISON);
        try {
            _thread.join(2000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void run() {
        try {
            for (;;) {
                Sample s = _queue.take();
                if (s == POISON) break;
                logSample(s);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void logSample(Sample s) {
        Histogram h = s._histogram;
        log.info("{} n={} min={} mean={} p50={} p90={} p99={} p99.9={} max={} (ns)",
                s._name,
                h.getTotalCount(),
                h.getMinValue(),
                (long) h.getMean(),
                h.getValueAtPercentile(50.0),
                h.getValueAtPercentile(90.0),
                h.getValueAtPercentile(99.0),
                h.getValueAtPercentile(99.9),
                h.getMaxValue());
    }
}
