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

import org.HdrHistogram.SingleWriterRecorder;

/**
 * Records one latency metric into a rolling window.
 *
 * <p>The first {@code warmup} values are discarded, then every {@code window} values a fresh, empty
 * histogram is flipped in and the accumulated interval is handed to a {@link StatsReporter} for
 * off-thread logging. The flip is done by {@code SingleWriterRecorder.getIntervalHistogram()}, which
 * returns a new histogram each call and coordinates with the recording thread via a WriterReaderPhaser,
 * so recording stays lock-free and there is no reuse hazard across the recorder and the reporter thread.
 *
 * <p><b>Threading:</b> {@link #record} must be called from a single, consistent thread (the
 * {@code SingleWriter} contract). Different {@code LatencyRecorder} instances may use different threads.
 */
public class LatencyRecorder {
    private final String _name;
    private final StatsReporter _reporter;
    private final long _warmup;
    private final long _window;
    private final long _highestTrackableValue;
    private final SingleWriterRecorder _recorder;

    private long _count = 0; // only ever touched by the single recording thread

    public LatencyRecorder(String name, StatsReporter reporter, long warmup, long window,
                           long highestTrackableValue, int numberOfSignificantValueDigits) {
        _name = name;
        _reporter = reporter;
        _warmup = warmup;
        _window = window;
        _highestTrackableValue = highestTrackableValue;
        _recorder = new SingleWriterRecorder(highestTrackableValue, numberOfSignificantValueDigits);
    }

    /** Record one sample (nanoseconds). Must be called from this recorder's single writer thread. */
    public void record(long valueNanos) {
        long n = ++_count;
        if (n <= _warmup) return; // discard warmup samples

        // Clamp into the trackable range so a rare outlier (e.g. a GC pause) can never throw or
        // trigger an inline resize on the recording thread; it still shows up at the ceiling.
        if (valueNanos < 0) valueNanos = 0;
        else if (valueNanos > _highestTrackableValue) valueNanos = _highestTrackableValue;

        _recorder.recordValue(valueNanos);

        if ((n - _warmup) % _window == 0) {
            _reporter.submit(_name, _recorder.getIntervalHistogram()); // flip empty in, hand old off
        }
    }

    /** Emit whatever has accumulated in the current (partial) window. Safe to call from any thread. */
    public void flush() {
        _reporter.submit(_name, _recorder.getIntervalHistogram());
    }
}
