package net.a_cappella.presto.structs.of.poolables;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;

import java.util.Collection;
import java.util.Map;
import java.util.function.Predicate;

public class MapOfObjByObjKey {
    protected Map<ObjKey, Obj> _map;

    public MapOfObjByObjKey(Map<ObjKey, Obj> map) {
        _map = map;
    }

    public Collection<Obj> values() {
        return _map.values();
    }

    public boolean put(ObjKey key, Obj val) {
        Obj curVal = _map.remove(key);
        if (curVal!=null) curVal.stopUsing();
        val.startUsing();
        _map.put(key,  val);
        return curVal!=null;
    }

    public boolean remove(ObjKey key) {
        Obj obj = _map.remove(key);
        if (obj==null) {
            return false;
        } else {
            obj.stopUsing();
            return true;
        }
    }

    public boolean removeIf(Predicate<? super Obj> filter) {
        return _map.entrySet().removeIf(entry -> {
            Obj v = entry.getValue();
            boolean remove = filter.test(v);
            if (remove) {
                v.stopUsing();
            }
            return remove;
        });
    }

    public void clear() {
        _map.forEach((key, obj) -> {
            _map.remove(key);
            obj.stopUsing();
        });
    }

    public String toString() {
        return _map.toString();
    }
}

