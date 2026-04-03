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

package net.a_cappella.presto.ps;

import java.util.ArrayList;
import java.util.List;

public class ThreeLists<V> {
    private final List<V> _list = new ArrayList<>();
    private final List<V> _listTBA = new ArrayList<>();
    private final List<V> _listTBR = new ArrayList<>();

    public List<V> get() {
        commit();
        return _list;
    }

    public void add(V value) {
        synchronized (this) {
            _listTBA.add(value);
        }
    }
    public void addAll(List<V> values) {
        synchronized (this) {
            _listTBA.addAll(values);
        }
    }
    public void remove(V value) {
        synchronized (this) {
            _listTBR.add(value);
        }
    }
    public void removeAll(List<V> values) {
        synchronized (this) {
            _listTBR.addAll(values);
        }
    }
    public void commit() {
        synchronized (this) {
            if (!_listTBA.isEmpty()) {
                _list.addAll(_listTBA);
                _listTBA.clear();
            }
            if (!_listTBR.isEmpty()) {
                _list.removeAll(_listTBR);
                _listTBR.clear();
            }
        }
    }
    public boolean isEmpty() {
        commit();
        return _list.isEmpty();
    }
}
