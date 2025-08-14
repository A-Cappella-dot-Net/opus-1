package net.a_cappella.presto.perftest.reflection;

public class Bench3 implements Bench {

    @Override
    public void setValue(Bean b, long value) {
        try {
            b._field.setLong(b, value);
        } catch (IllegalArgumentException | IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    @Override
    public long getValue(Bean b) {
        try {
            return b._field.getLong(b);
        } catch (IllegalArgumentException | IllegalAccessException e) {
            e.printStackTrace();
            return 0;
        }
    }

}
