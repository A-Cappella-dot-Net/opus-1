package net.a_cappella.continuo.obj.meta;

public class TypeMetaInfo {
    public static final int TYPE_UNKNOWN = 0;
    public static final int TYPE_CHAR = 1;
    public static final int TYPE_STRING = 2;
    public static final int TYPE_SHORT = 3;
    public static final int TYPE_INT = 4;
    public static final int TYPE_LONG = 5;
    public static final int TYPE_FLOAT = 6;
    public static final int TYPE_DOUBLE = 7;
    public static final int TYPE_BOOLEAN = 8;
    public static final int TYPE_TIMESTAMP = 9;
    public static final int TYPE_NANOS = 10;
    public static final int TYPE_TIME = 11;
    public static final int TYPE_DATE = 12;
    public static final int TYPE_ENUM = 13;

    public static int getCode(String sType) {
        if ("char".equalsIgnoreCase(sType)) return TYPE_CHAR;
        if ("string".equalsIgnoreCase(sType)) return TYPE_STRING;
        if ("short".equalsIgnoreCase(sType)) return TYPE_SHORT;
        if ("int".equalsIgnoreCase(sType)) return TYPE_INT;
        if ("long".equalsIgnoreCase(sType)) return TYPE_LONG;
        if ("float".equalsIgnoreCase(sType)) return TYPE_FLOAT;
        if ("double".equalsIgnoreCase(sType)) return TYPE_DOUBLE;
        if ("boolean".equalsIgnoreCase(sType)) return TYPE_BOOLEAN;
        if ("timestamp".equalsIgnoreCase(sType)) return TYPE_TIMESTAMP;
        if ("nanos".equalsIgnoreCase(sType)) return TYPE_NANOS;
        if ("time".equalsIgnoreCase(sType)) return TYPE_TIME;
        if ("date".equalsIgnoreCase(sType)) return TYPE_DATE;
        if ("enum".equalsIgnoreCase(sType)) return TYPE_ENUM;
        return TYPE_UNKNOWN;
    }
}
