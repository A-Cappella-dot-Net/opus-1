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

package net.a_cappella.cembalo.generator;

import java.util.List;

public class FieldDef {
    public int _tag;
    public String _name;
    public char _type;
    public List<FieldDef> _group;

    public FieldDef(String[] comps) {
        String[] tagName = comps[0].split("=");
        _tag = Integer.parseInt(tagName[0]);
        _name = tagName[1];
        _type = comps[1].charAt(0);
    }

    public String valuesToString() {
        return "";
    }

    public String toString() {
        String group = (_group==null)?"":(" => "+_group);
        return _tag+"="+_name+"|"+_type+valuesToString()+group;
    }
}
