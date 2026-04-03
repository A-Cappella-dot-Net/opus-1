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

public class MsgDef {
    private String _msgType;
    private String _name;
    private List<FieldDef> _fields;

    public MsgDef(String msgType, String name, List<FieldDef> fields) {
        _msgType = msgType;
        _name = name;
        _fields = fields;
    }

    public String getMsgType() {
        return _msgType;
    }
    public void setMsgType(String msgType) {
        _msgType = msgType;
    }

    public String getName() {
        return _name;
    }
    public void setName(String name) {
        _name = name;
    }

    public List<FieldDef> getFields() {
        return _fields;
    }
    public void setFields(List<FieldDef> fields) {
        _fields = fields;
    }

    public String toString() {
        return "{"+_msgType+"="+_name+"|"+_fields+"}";
    }
}
