package net.a_cappella.presto.perftest.reflection;

public class Bench1 implements Bench {

    @Override
    public void setValue(Bean b, long value) {
        b._value = value;
    }

    @Override
    public long getValue(Bean b) {
        return b._value;
    }

}
