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

import gnu.trove.map.TDoubleObjectMap;
import gnu.trove.map.hash.TDoubleObjectHashMap;

public class FloatFieldDef extends FieldDef {
    // _type == 'F'
    public TDoubleObjectMap<String> _values;

    public FloatFieldDef(String[] comps) {
        super(comps);
        if (comps.length>2) {
            _values = new TDoubleObjectHashMap<>();
            String[] valNames = comps[2].split(",");
            for (String valName : valNames) {
                String[] valNam = valName.split("=");
                double val = Double.parseDouble(valNam[0]);
                String name = valNam[1];
                _values.put(val, name);
            }
        }
    }

    public String valuesToString() {
        return (_values==null)?"":("|"+_values);
    }
}
