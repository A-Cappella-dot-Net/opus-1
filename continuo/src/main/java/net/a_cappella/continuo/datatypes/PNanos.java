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
