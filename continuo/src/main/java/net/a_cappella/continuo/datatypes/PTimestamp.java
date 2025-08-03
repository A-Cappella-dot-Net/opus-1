package net.a_cappella.continuo.datatypes;

import net.a_cappella.continuo.utils.Utils;

import java.text.ParseException;
import java.util.Date;

public class PTimestamp {
    private final Date _date;

    public PTimestamp(long timestamp) {
        _date = new Date(timestamp);
    }

    public PTimestamp(String yyyMMddHHmmssSSS) throws ParseException {
        _date = new Date(Utils.parse("yyyy-MM-dd HH:mm:ss.SSS", yyyMMddHHmmssSSS).getTime());
    }

    public long getTimestamp() {
        return _date.getTime();
    }
    public void setTimestamp(long ts) {
        _date.setTime(ts);
    }

    public static PTimestamp parsePTimestamp(String str) {
        if ("now".equals(str)) return new PTimestamp(System.currentTimeMillis());
        try {
            return new PTimestamp(str);
        } catch (ParseException x) {
            return null;
        }
    }

    public String toString() {
        return Utils.format("yyyy-MM-dd HH:mm:ss.SSS", _date);
    }
}
