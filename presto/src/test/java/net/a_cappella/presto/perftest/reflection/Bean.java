package net.a_cappella.presto.perftest.reflection;

import java.lang.reflect.Field;

public class Bean {
    public Field _field;

    public long _value;
    public long getValue()             { return _value; }
    public void setValue( long value ) { _value = value; }

    public long _value1;
    public long getValue1()             { return _value1; }
    public void setValue1( long value ) { _value1 = value; }

    public long _value2;
    public long getValue2()             { return _value2; }
    public void setValue2( long value ) { _value2 = value; }

    public long _value3;
    public long getValue3()             { return _value3; }
    public void setValue3( long value ) { _value3 = value; }

    public long _value4;
    public long getValue4()             { return _value4; }
    public void setValue4( long value ) { _value4 = value; }

    public long _value5;
    public long getValue5()             { return _value5; }
    public void setValue5( long value ) { _value5 = value; }

    public long _value6;
    public long getValue6()             { return _value6; }
    public void setValue6( long value ) { _value6 = value; }

    public long _value7;
    public long getValue7()             { return _value7; }
    public void setValue7( long value ) { _value7 = value; }

    public long _value8;
    public long getValue8()             { return _value8; }
    public void setValue8( long value ) { _value8 = value; }

    public long _value9;
    public long getValue9()             { return _value9; }
    public void setValue9( long value ) { _value9 = value; }

    public long _value0;
    public long getValue0()             { return _value0; }
    public void setValue0( long value ) { _value0 = value; }

    public Bean() {
        try {
            _field = this.getClass().getDeclaredField( "_value" );
        } catch (NoSuchFieldException | SecurityException e) {
            e.printStackTrace();
        }
    }
}
