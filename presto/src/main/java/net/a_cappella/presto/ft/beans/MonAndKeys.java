package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.msg.FtMonitorMsg;

import java.nio.channels.SelectionKey;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class MonAndKeys {
    public FtMonitorMsg _mon;
    public Map<SelectionKey, Character> _keys;

    public MonAndKeys(FtMonitorMsg mon) {
        _mon = mon;
        _keys = new HashMap<>();
    }

    public String toString() {
        return "{"+_keys.entrySet().stream().map(e->keyHash(e.getKey())+"="+e.getValue()).collect(Collectors.joining(", ", "{", "}"))+"}";
    }
}
