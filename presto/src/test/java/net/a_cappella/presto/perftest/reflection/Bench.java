package net.a_cappella.presto.perftest.reflection;

public interface Bench {
    void setValue(Bean b, long value);
    long getValue(Bean b);
}
