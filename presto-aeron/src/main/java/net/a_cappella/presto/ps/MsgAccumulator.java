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

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;

import java.util.ArrayList;
import java.util.List;

public class MsgAccumulator {
    private static final int INIT_LIST_SIZE = 1_000;

    private final List<SnSHandler> _handlersList = new ArrayList<>(INIT_LIST_SIZE);
    private final List<ObjKey> _keysList = new ArrayList<>(INIT_LIST_SIZE);

    public MsgAccumulator() {}

    public void accumulate(SnSHandler handler, Obj obj) {
        for (int i=0; i<_handlersList.size(); i++) {
            if (handler.equals(_handlersList.get(i)) &&
                    obj.getObjKey().equals(_keysList.get(i))) {
                _handlersList.remove(i);
                ObjKey key = _keysList.remove(i);
                key.getObj().stopUsing();
                break;
            }
        }
        _handlersList.add(handler);
        _keysList.add(obj.getObjKey());
        obj.startUsing();
    }

    public void notifyAndReset() {
        for (int i=0; i<_handlersList.size(); i++) {
            SnSHandler handler = _handlersList.get(i);
            ObjKey key = _keysList.get(i);
            Obj obj = key.getObj();
            handler.onMsg(obj);
            obj.stopUsing();
        }
        _handlersList.clear();
        _keysList.clear();
    }

    public boolean isEmpty() {
        return _handlersList.isEmpty();
    }
}
