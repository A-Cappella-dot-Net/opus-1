package net.a_cappella.continuo.datatypes;

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
        if ("now".equals(str)) return new PNanos(System.nanoTime());
        return new PNanos(str);
    }

    public String toString() {
        return Long.toString(_nanos);
    }
}
