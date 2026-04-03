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
