package net.a_cappella.presto.perftest.reflection;

public class Bench2 implements Bench {

    @Override
    public void setValue(Bean b, long value) {
        b.setValue(value);
    }

    @Override
    public long getValue(Bean b) {
        return b.getValue();
    }

}
