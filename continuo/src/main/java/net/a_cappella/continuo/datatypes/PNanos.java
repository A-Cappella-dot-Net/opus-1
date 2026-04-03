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

package net.a_cappella.continuo.datatypes;

import java.time.Clock;
import java.time.Instant;

public class PNanos {
    public long _nanos;

    public PNanos(long nanos) {
        _nanos = nanos;
    }

    public PNanos(String nanos) {
        _nanos = Long.parseLong(nanos);
    }

    public long getNanos() {
        return _nanos;
    }

    public static PNanos parsePNanos(String str) {
        if ("now".equals(str)) {
            Instant timestamp = Clock.systemUTC().instant();
            long totalNanos = timestamp.getEpochSecond() * 1_000_000_000L + timestamp.getNano();
            return new PNanos(totalNanos);
        }
        return new PNanos(str);
    }

    public String toString() {
        return Long.toString(_nanos);
    }
}
