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

package net.a_cappella.continuo.obj.meta;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.a_cappella.continuo.obj.Obj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ObjMetaInfo {
    private static final Logger log = LoggerFactory.getLogger(ObjMetaInfo.class);

    private int _objType;
    private final List<FieldMetaInfo> _keys;
    private final List<FieldMetaInfo> _nonKeys;

    public static final Map<String, FieldMetaInfo> _headerFieldsMap = new HashMap<>();
    static {
        _headerFieldsMap.put("onLoopback", new FieldMetaInfo("onLoopback"));
        _headerFieldsMap.put("mine", new FieldMetaInfo("mine"));
        _headerFieldsMap.put("tsNanos", new FieldMetaInfo("tsNanos", FieldType.NANOS));
        _headerFieldsMap.put("subject", new FieldMetaInfo("subject"));
    }

    private final Map<String, FieldMetaInfo> _map = new HashMap<>(_headerFieldsMap);
    private final int _maxRecLen;

    public ObjMetaInfo(List<FieldMetaInfo> keys, List<FieldMetaInfo> nonKeys, int maxRecLen) {
        _keys = keys;
        _nonKeys = nonKeys;
        _maxRecLen = maxRecLen;
        for (FieldMetaInfo metaInfo : keys) {
            _map.put(metaInfo.getName(), metaInfo);
        }
        for (FieldMetaInfo metaInfo : nonKeys) {
            _map.put(metaInfo.getName(), metaInfo);
        }
    }

    public ObjMetaInfo(List<FieldMetaInfo> keys, List<FieldMetaInfo> nonKeys) {
        this(keys, nonKeys, 0);
    }

    public int getObjType() {
        return _objType;
    }
    public List<FieldMetaInfo> getKeys() {
        return _keys;
    }
    public List<FieldMetaInfo> getNonKeys() {
        return _nonKeys;
    }
    public FieldMetaInfo getFieldMetaInfo(String field) {
        return _map.get(field);
    }
    public FieldMetaInfo fieldMetaInfo(String field) throws Exception {
        FieldMetaInfo metaInfo = _map.get(field);
        if (metaInfo==null) throw new Exception("Field "+field+" is not defined");
        return metaInfo;
    }
    public int getMaxRecLen() {
        return _maxRecLen;
    }

    public void updateMetaInfoFromInstance(Obj obj) throws Exception {
        _objType = obj.getMsgType();
        for (FieldMetaInfo metaInfo : _map.values()) {
            metaInfo.setField(obj);
        }
    }

    public String toString() {
        return "{"+_objType+" "+_keys+","+_nonKeys+","+_maxRecLen+"}";
    }
}
