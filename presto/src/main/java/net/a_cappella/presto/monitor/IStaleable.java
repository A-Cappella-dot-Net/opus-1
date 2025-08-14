package net.a_cappella.presto.monitor;

public interface IStaleable {
    void stale();
    boolean isStale();
}
