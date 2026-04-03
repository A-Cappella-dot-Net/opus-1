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
