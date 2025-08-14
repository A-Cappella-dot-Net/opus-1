package net.a_cappella.presto.structs.of.poolables;

import net.a_cappella.continuo.managed.IPoolable;

import java.util.Map;

public class MapOfPoolable<K, V extends IPoolable> {
    protected Map<K, V> _map;

    public MapOfPoolable(Map<K, V> map) {
        _map = map;
    }

    public V get(K key) {
        V v = _map.get(key);
        if (v!=null) v.startUsing();
        return v;
    }

    public boolean containsKey(K key) {
        return _map.containsKey(key);
    }

    public boolean put(K key, V val) {
        val.startUsing();
        V curVal = _map.put(key,  val);
        if (curVal==null) {
            return false;
        } else {
            curVal.stopUsing();
            return true;
        }
    }

    public boolean remove(K key) {
        V obj = _map.remove(key);
        if (obj==null) {
            return false;
        } else {
            obj.stopUsing();
            return true;
        }
    }

    public void clear() {
        for (Map.Entry<K, V> entry : _map.entrySet()) {
            V obj = _map.remove(entry.getKey());
            if (obj!=null) obj.stopUsing();
        }
    }

    public String toString() {
        return _map.toString();
    }
}
