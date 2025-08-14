package net.a_cappella.presto.perftest.reflection;

public class Bench13 implements Bench {

    @Override
    public void setValue(Bean b, long value) {
        b._value = value;
        try {
            b._field.setLong(b, value);
        } catch (IllegalArgumentException | IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    @Override
    public long getValue(Bean b) {
        try {
            b._field.getLong(b);
        } catch (IllegalArgumentException | IllegalAccessException e) {
            e.printStackTrace();
            return 0;
        }
        return b._value;
    }

}
