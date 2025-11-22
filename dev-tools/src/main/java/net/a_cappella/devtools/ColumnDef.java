package net.a_cappella.devtools;

import java.util.Date;

public class ColumnDef {
    public static final int DEFAULT_WIDTH_SHORT = 40;
    public static final int DEFAULT_WIDTH_INT = 80;
    public static final int DEFAULT_WIDTH_LONG = 100;

    public static final int DEFAULT_WIDTH_DECIMAL = 120;

    public static final int DEFAULT_WIDTH_DATETIME_SHORT = 80;
    public static final int DEFAULT_WIDTH_DATETIME_ISO = 180;
    public static final int DEFAULT_WIDTH_DATETIME_DATE = 80;
    public static final int DEFAULT_WIDTH_DATETIME_TIME = 80;

    public static final int DEFAULT_WIDTH_BOOLEAN = 50;

    public static final int DEFAULT_WIDTH_STRING = 150;
    public static final int DEFAULT_WIDTH_CHAR = 20;
    public static final int DEFAULT_WIDTH_ENUM = 50;

    public String name;
    public String type; // "string", "number", "boolean", etc.
    public String align; // right,left,center
    public int width;
    public String format; // short, ISO, locale, date, time
    public int decimals;

    public ColumnDef(String name, String type, String align, int width, String format, int decimals) {
        this.name = name;
        this.type = type;
        this.align = align;
        this.width = width;
        this.format = format;
        this.decimals = decimals;
    }

    public ColumnDef(String name, String type, String align, int width) {
        this(name, type, align, width, null, 0);
    }
    public ColumnDef(String name, String type, String align, int width, int decimals) {
        this(name, type, align, width, null, decimals);
    }
    public ColumnDef(String name, String type, String align, int width, String format) {
        this(name, type, align, width, format, 0);
    }

    public ColumnDef(String name, String type, int width) { // default align,format,decimals
        this(name, type, null, width, null, 0);
    }
    public ColumnDef(String name, String type, int width, int decimals) { // default align,format
        this(name, type, null, width, null, decimals);
    }
    public ColumnDef(String name, String type, int width, String format) { // default align,decimals
        this(name, type, null, width, format, 0);
    }

    public void resize(int newWidth) {
        this.width = newWidth;
    }

    public static ColumnDef newAdHocCol(String columnName, Object adHocValue) {
        if (adHocValue instanceof Integer || adHocValue instanceof Long) {
            return new ColumnDef(columnName, "integer", DEFAULT_WIDTH_INT); // "align":"right"
        } else if (adHocValue instanceof Float || adHocValue instanceof Double) {
            return new ColumnDef(columnName, "decimal", DEFAULT_WIDTH_DECIMAL); // "align":"right", "decimals":2
        } else if (adHocValue instanceof Date) {
            return new ColumnDef(columnName, "datetime", DEFAULT_WIDTH_DATETIME_ISO, "ISO"); // "format":"short"
        } else if (adHocValue instanceof Boolean) {
            return new ColumnDef(columnName, "boolean", DEFAULT_WIDTH_BOOLEAN);
        }
        return new ColumnDef(columnName, "string", DEFAULT_WIDTH_STRING);
    }

    public String toString() {
        return "(" + name + " " + type + " " + align + " " + width + " " + format + " " + decimals + ")";
    }
}
