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

import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.hash.TIntObjectHashMap;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Coder;

import java.lang.reflect.Constructor;

public class SharedCoders {
    public TIntObjectMap<Coder> _codersByObjType = new TIntObjectHashMap<>();

    public Coder getCoder(int objType) {
        Coder cod = _codersByObjType.get(objType);
        if (cod == null) {
            Constructor<? extends Coder> codCtor = ObjectManager.getInstance().getCoderConstructor(objType);
            try {
                cod = codCtor.newInstance();
                _codersByObjType.put(objType, cod);
            } catch (Exception x) {
                throw new RuntimeException("Could not create Coder object "+objType, x);
            }
        }
        return cod;
    }
}
