package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class TestObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_TEST; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_TEST; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) throws Exception {
        _codCtor = codCtor;
        _priority = priority;
        _staticMetaInfo.updateMetaInfoFromInstance(this);
    }

    private static Constructor<? extends Coder> _codCtor;
    @Override
    public Constructor<? extends Coder> getCoderConstructor() {
        return _codCtor;
    }

    private static ObjPriority _priority;
    @Override
    public ObjPriority getPriority() {
        return _priority;
    }

    private static final ObjMetaInfo _staticMetaInfo = new ObjMetaInfo(
            Arrays.asList(
                    new FieldMetaInfo("aShort"),
                    new FieldMetaInfo("anInt"),
                    new FieldMetaInfo("aChar")
            ),
            Arrays.asList(
                    new FieldMetaInfo("aBoolean"),
                    new FieldMetaInfo("aLong"),
                    new FieldMetaInfo("aFloat"),
                    new FieldMetaInfo("aDouble"),
                    new FieldMetaInfo("aString"),
                    new FieldMetaInfo("anEnum"),
                    new FieldMetaInfo("aTimestamp", FieldType.TIMESTAMP),
                    new FieldMetaInfo("aNanos", FieldType.NANOS),
                    new FieldMetaInfo("aTime", FieldType.TIME),
                    new FieldMetaInfo("aDate", FieldType.DATE)
            ));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    public short _aShort;
    public int _anInt;
    public long _aLong;
    public char _aChar;
    public String _aString;
    public long _aTimestamp;
    public long _aNanos;
    public int _aTime;
    public int _aDate;
    public float _aFloat;
    public double _aDouble;
    public boolean _aBoolean;
    public MyEnum _anEnum = MyEnum.ZERO;

    public TestObj() {}

    public TestObj(TestObj obj) {
        super(obj);
        _aShort = obj._aShort;
        _anInt = obj._anInt;
        _aLong = obj._aLong;
        _aChar = obj._aChar;
        _aString = obj._aString;
        _aTimestamp = obj._aTimestamp;
        _aNanos = obj._aNanos;
        _aTime = obj._aTime;
        _aDate = obj._aDate;
        _aFloat = obj._aFloat;
        _aDouble = obj._aDouble;
        _aBoolean = obj._aBoolean;
        _anEnum = obj._anEnum;
    }

    public void set(short aShort, int anInt, long aLong, char aChar, String aString, long aTimestamp, long aNanos,
                    int aTime, int aDate, float aFloat, double aDouble, boolean aBoolean, MyEnum anEnum) {
        _aShort = aShort;
        _anInt = anInt;
        _aLong = aLong;
        _aChar = aChar;
        _aString = aString;
        _aTimestamp = aTimestamp;
        _aNanos = aNanos;
        _aTime = aTime;
        _aDate = aDate;
        _aFloat = aFloat;
        _aDouble = aDouble;
        _aBoolean = aBoolean;
        _anEnum = anEnum;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _aShort = 0;
        _anInt = 0;
        _aLong = 0;
        _aChar = '\0';
        _aString = null;
        _aTimestamp = 0;
        _aNanos = 0;
        _aTime = 0;
        _aDate = 0;
        _aFloat = 0.0f;
        _aDouble = 0.0;
        _aBoolean = false;
        _anEnum = MyEnum.ZERO;
    }



    @Override
    public char getChar(String fieldName) throws Exception {
        if ("aChar".equalsIgnoreCase(fieldName)) return _aChar;
        return super.getChar(fieldName); // throws exception
    }
    @Override
    public void setChar(String fieldName, char value) throws Exception {
        if ("aChar".equalsIgnoreCase(fieldName)) _aChar = value;
        else super.setChar(fieldName, value); // throws exception
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("aString".equalsIgnoreCase(fieldName)) return _aString;
        return super.getString(fieldName); // throws exception
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("aString".equalsIgnoreCase(fieldName)) _aString = value;
        else super.setString(fieldName, value); // throws exception
    }

    @Override
    public short getShort(String fieldName) throws Exception {
        if ("aShort".equalsIgnoreCase(fieldName)) return _aShort;
        return super.getShort(fieldName); // throws exception
    }
    @Override
    public void setShort(String fieldName, short value) throws Exception {
        if ("aShort".equalsIgnoreCase(fieldName)) _aShort = value;
        else super.setShort(fieldName, value); // throws exception
    }

    @Override
    public int getInt(String fieldName) throws Exception {
        if ("anInt".equalsIgnoreCase(fieldName)) return _anInt;
        return super.getInt(fieldName); // throws exception
    }
    @Override
    public void setInt(String fieldName, int value) throws Exception {
        if ("anInt".equalsIgnoreCase(fieldName)) _anInt = value;
        else super.setInt(fieldName, value); // throws exception
    }

    @Override
    public long getLong(String fieldName) throws Exception {
        if ("aLong".equalsIgnoreCase(fieldName)) return _aLong;
        return super.getLong(fieldName); // throws exception
    }
    @Override
    public void setLong(String fieldName, long value) throws Exception {
        if ("aLong".equalsIgnoreCase(fieldName)) _aLong = value;
        else super.setLong(fieldName, value); // throws exception
    }

    @Override
    public float getFloat(String fieldName) throws Exception {
        if ("aFloat".equalsIgnoreCase(fieldName)) return _aFloat;
        return super.getFloat(fieldName); // throws exception
    }
    @Override
    public void setFloat(String fieldName, float value) throws Exception {
        if ("aFloat".equalsIgnoreCase(fieldName)) _aFloat = value;
        else super.setFloat(fieldName, value); // throws exception
    }

    @Override
    public double getDouble(String fieldName) throws Exception {
        if ("aDouble".equalsIgnoreCase(fieldName)) return _aDouble;
        return super.getDouble(fieldName); // throws exception
    }
    @Override
    public void setDouble(String fieldName, double value) throws Exception {
        if ("aDouble".equalsIgnoreCase(fieldName)) _aDouble = value;
        else super.setDouble(fieldName, value); // throws exception
    }

    @Override
    public boolean getBoolean(String fieldName) throws Exception {
        if ("aBoolean".equalsIgnoreCase(fieldName)) return _aBoolean;
        return super.getBoolean(fieldName); // throws exception
    }
    @Override
    public void setBoolean(String fieldName, boolean value) throws Exception {
        if ("aBoolean".equalsIgnoreCase(fieldName)) _aBoolean = value;
        else super.setBoolean(fieldName, value); // throws exception
    }

    @Override
    public long getTimestamp(String fieldName) throws Exception {
        if ("aTimestamp".equalsIgnoreCase(fieldName)) return _aTimestamp;
        return super.getLong(fieldName); // throws exception
    }
    @Override
    public void setTimestamp(String fieldName, long value) throws Exception {
        if ("aTimestamp".equalsIgnoreCase(fieldName)) _aTimestamp = value;
        else super.setTimestamp(fieldName, value); // throws exception
    }

    @Override
    public long getNanos(String fieldName) throws Exception {
        if ("aNanos".equalsIgnoreCase(fieldName)) return _aNanos;
        return super.getLong(fieldName); // throws exception
    }
    @Override
    public void setNanos(String fieldName, long value) throws Exception {
        if ("aNanos".equalsIgnoreCase(fieldName)) _aNanos = value;
        else super.setNanos(fieldName, value); // throws exception
    }

    @Override
    public int getTime(String fieldName) throws Exception {
        if ("aTime".equalsIgnoreCase(fieldName)) return _aTime;
        return super.getInt(fieldName); // throws exception
    }
    @Override
    public void setTime(String fieldName, int value) throws Exception {
        if ("aTime".equalsIgnoreCase(fieldName)) _aTime = value;
        else super.setTime(fieldName, value); // throws exception
    }

    @Override
    public int getDate(String fieldName) throws Exception {
        if ("aDate".equalsIgnoreCase(fieldName)) return _aDate;
        return super.getInt(fieldName); // throws exception
    }
    @Override
    public void setDate(String fieldName, int value) throws Exception {
        if ("aDate".equalsIgnoreCase(fieldName)) _aDate = value;
        else super.setDate(fieldName, value); // throws exception
    }

    @Override
    public Enum<?> getEnum(String fieldName) throws Exception {
        if ("anEnum".equalsIgnoreCase(fieldName)) return _anEnum;
        return super.getEnum(fieldName); // throws exception
    }
    @Override
    public void setEnum(String fieldName, Enum<?> value) throws Exception {
        if ("anEnum".equalsIgnoreCase(fieldName)) _anEnum = (MyEnum) value;
        else super.setEnum(fieldName, value); // throws exception
    }


    @Override
    public int hashCode() {
        final int prime = 31;
        int result = super.hashCode();
        result = prime * result + (_aBoolean ? 1231 : 1237);
        result = prime * result + _aChar;
        result = prime * result + _aDate;
        long temp;
        temp = Double.doubleToLongBits(_aDouble);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        result = prime * result + Float.floatToIntBits(_aFloat);
        result = prime * result + (int) (_aLong ^ (_aLong >>> 32));
        result = prime * result + (int) (_aNanos ^ (_aNanos >>> 32));
        result = prime * result + _aShort;
        result = prime * result + ((_aString == null) ? 0 : _aString.hashCode());
        result = prime * result + _aTime;
        result = prime * result + (int) (_aTimestamp ^ (_aTimestamp >>> 32));
        result = prime * result + ((_anEnum == null) ? 0 : _anEnum.hashCode());
        result = prime * result + _anInt;
        return result;
    }
    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (!super.equals(obj))
            return false;
        if (getClass() != obj.getClass())
            return false;
        TestObj other = (TestObj) obj;
        if (_aBoolean != other._aBoolean)
            return false;
        if (_aChar != other._aChar)
            return false;
        if (_aDate != other._aDate)
            return false;
        if (Double.doubleToLongBits(_aDouble) != Double.doubleToLongBits(other._aDouble))
            return false;
        if (Float.floatToIntBits(_aFloat) != Float.floatToIntBits(other._aFloat))
            return false;
        if (_aLong != other._aLong)
            return false;
        if (_aNanos != other._aNanos)
            return false;
        if (_aShort != other._aShort)
            return false;
        if (_aString == null) {
            if (other._aString != null)
                return false;
        } else if (!_aString.equals(other._aString))
            return false;
        if (_aTime != other._aTime)
            return false;
        if (_aTimestamp != other._aTimestamp)
            return false;
        if (_anEnum != other._anEnum)
            return false;
        if (_anInt != other._anInt)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return super.toString()+
                " short="+_aShort+
                " int="+_anInt+
                " long="+_aLong+
                " char="+_aChar+
                " string="+_aString+
                " timestamp="+_aTimestamp+
                " nanos="+_aNanos+
                " time="+_aTime+
                " date="+_aDate+
                " float="+_aFloat+
                " double="+_aDouble+
                " boolean="+_aBoolean+
                " enum="+_anEnum;
    }
}
