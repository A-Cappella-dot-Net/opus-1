/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

