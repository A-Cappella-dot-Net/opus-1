package net.a_cappella.presto.utils.map;

import java.nio.channels.SelectionKey;
import java.util.HashMap;
import java.util.Iterator;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class SelectionKeyHashMap<T> extends HashMap<SelectionKey, T> implements SelectionKeyMap<T> {

    public String toString() {
        Iterator<Entry<SelectionKey, T>> i = entrySet().iterator();
        if (! i.hasNext())
            return "{}";

        StringBuilder sb = new StringBuilder();
        sb.append('{');
        for (;;) {
            Entry<SelectionKey, T> e = i.next();
            SelectionKey key = e.getKey();
            T value = e.getValue();
            sb.append(keyHash(key));
            sb.append('=');
            sb.append(value);
            if (! i.hasNext())
                return sb.append('}').toString();
            sb.append(',').append(' ');
        }
    }
}
