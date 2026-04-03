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

package net.a_cappella.presto.obj;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Objects;

public class ObjKeyImpl implements ObjKey {

    private static final Logger log = LoggerFactory.getLogger(ObjKeyImpl.class);

    private final Obj _obj;

    public ObjKeyImpl(Obj obj) {
        _obj = obj;
    }

    @Override
    public Obj getObj() {
        return _obj;
    }

    @Override
    public int hashCode() {
        List<FieldMetaInfo> keys = _obj.getObjMetaInfo().getKeys();
        final int prime = 31;
        int result = 17;

        for (int i=0; i<keys.size(); i++) {
            FieldMetaInfo fmi = keys.get(i);
            try {
                switch (fmi.getType()) {
                    case CHAR:
                        result = prime * result + _obj.getChar(fmi.getName());
                        break;
                    case STRING:
                        String aString = _obj.getString(fmi.getName());
                        result = prime * result + ((aString == null) ? 0 : aString.hashCode());
                        break;
                    case SHORT:
                        result = prime * result + _obj.getShort(fmi.getName());
                        break;
                    case INT:
                        result = prime * result + _obj.getInt(fmi.getName());
                        break;
                    case LONG:
                        long aLong = _obj.getLong(fmi.getName());
                        result = prime * result + (int) (aLong ^ (aLong >>> 32));
                        break;
                    case FLOAT:
                        result = prime * result + Float.floatToIntBits(_obj.getFloat(fmi.getName()));
                        break;
                    case DOUBLE:
                        long temp;
                        temp = Double.doubleToLongBits(_obj.getDouble(fmi.getName()));
                        result = prime * result + (int) (temp ^ (temp >>> 32));
                        break;
                    case BOOLEAN:
                        result = prime * result + (_obj.getBoolean(fmi.getName()) ? 1231 : 1237);
                        break;
                    case TIMESTAMP:
                        long aTimestamp = _obj.getTimestamp(fmi.getName());
                        result = prime * result + (int) (aTimestamp ^ (aTimestamp >>> 32));
                        break;
                    case NANOS:
                        long aNanos = _obj.getNanos(fmi.getName());
                        result = prime * result + (int) (aNanos ^ (aNanos >>> 32));
                        break;
                    case TIME:
                        int aTime = _obj.getTime(fmi.getName());
                        result = prime * result + aTime;
                        break;
                    case DATE:
                        result = prime * result + _obj.getDate(fmi.getName());
                        break;
                    case ENUM:
                        Enum<?> anEnum = _obj.getEnum(fmi.getName());
                        result = prime * result + ((anEnum == null) ? 0 : anEnum.hashCode());
                        break;
                    case UNKNOWN:
                }
            } catch (Exception x) {
                log.error("Error computing hashCode for "+this, x);
            }
        }

        return result;
    }
    @Override
    public boolean equals(Object object) {
        if (this == object)
            return true;
        if (getClass() != object.getClass())
            return false;
        List<FieldMetaInfo> keys = _obj.getObjMetaInfo().getKeys();
        Obj obj = ((ObjKeyImpl) object)._obj;

        for (int i=0; i<keys.size(); i++) {
            FieldMetaInfo fmi = keys.get(i);
            try {
                switch (fmi.getType()) {
                    case CHAR:
                        if (_obj.getChar(fmi.getName()) != obj.getChar(fmi.getName())) return false;
                        break;
                    case STRING:
                        if (!Objects.equals(_obj.getString(fmi.getName()), obj.getString(fmi.getName()))) return false;
                        break;
                    case SHORT:
                        if (_obj.getShort(fmi.getName()) != obj.getShort(fmi.getName())) return false;
                        break;
                    case INT:
                        if (_obj.getInt(fmi.getName()) != obj.getInt(fmi.getName())) return false;
                        break;
                    case LONG:
                        if (_obj.getLong(fmi.getName()) != obj.getLong(fmi.getName())) return false;
                        break;
                    case FLOAT:
                        if (_obj.getFloat(fmi.getName()) != obj.getFloat(fmi.getName())) return false;
                        break;
                    case DOUBLE:
                        if (_obj.getDouble(fmi.getName()) != obj.getDouble(fmi.getName())) return false;
                        break;
                    case BOOLEAN:
                        if (_obj.getBoolean(fmi.getName()) != obj.getBoolean(fmi.getName())) return false;
                        break;
                    case TIMESTAMP:
                        if (_obj.getTimestamp(fmi.getName()) != obj.getTimestamp(fmi.getName())) return false;
                        break;
                    case NANOS:
                        if (_obj.getNanos(fmi.getName()) != obj.getNanos(fmi.getName())) return false;
                        break;
                    case TIME:
                        if (_obj.getTime(fmi.getName()) != obj.getTime(fmi.getName())) return false;
                        break;
                    case DATE:
                        if (_obj.getDate(fmi.getName()) != obj.getDate(fmi.getName())) return false;
                        break;
                    case ENUM:
                        if (_obj.getEnum(fmi.getName()) != obj.getEnum(fmi.getName())) return false;
                        break;
                    case UNKNOWN:
                }
            } catch (Exception x) {
                log.error("Error computing equals for "+this, x);
            }
        }
        return true;
    }

    @Override
    public String toString() {
        List<FieldMetaInfo> keys = _obj.getObjMetaInfo().getKeys();
        StringBuilder sb = new StringBuilder();
        sb.append('<');
        for (int i=0; i<keys.size(); i++) {
            FieldMetaInfo fmi = keys.get(i);
            String name = fmi.getName();
            if (i>0) sb.append(", ");
            sb.append(name).append("=");
            try {
                switch (fmi.getType()) {
                    case CHAR:
                        sb.append(_obj.getChar(name));
                        break;
                    case STRING:
                        sb.append(_obj.getString(name));
                        break;
                    case SHORT:
                        sb.append(_obj.getShort(name));
                        break;
                    case INT:
                        sb.append(_obj.getInt(name));
                        break;
                    case LONG:
                        sb.append(_obj.getLong(name));
                        break;
                    case FLOAT:
                        sb.append(_obj.getFloat(name));
                        break;
                    case DOUBLE:
                        sb.append(_obj.getDouble(fmi.getName()));
                        break;
                    case BOOLEAN:
                        sb.append(_obj.getBoolean(fmi.getName()));
                        break;
                    case TIMESTAMP:
                        sb.append(_obj.getTimestamp(fmi.getName()));
                        break;
                    case NANOS:
                        sb.append(_obj.getNanos(fmi.getName()));
                        break;
                    case TIME:
                        sb.append(_obj.getTime(fmi.getName()));
                        break;
                    case DATE:
                        sb.append(_obj.getDate(fmi.getName()));
                        break;
                    case ENUM:
                        sb.append(_obj.getEnum(fmi.getName()));
                        break;
                    case UNKNOWN:
                }
            } catch (Exception x) {
                log.error("Error generating toString", x);
            }
        }
        sb.append('>');
        return sb.toString();
    }

    @Override
    public int compareTo(Object object) {
        if (this == object) return 0;
        if (getClass() != object.getClass()) return getClass().getName().compareTo(object.getClass().getName());

        List<FieldMetaInfo> keys = _obj.getObjMetaInfo().getKeys();
        Obj obj = ((ObjKeyImpl) object)._obj;
        int cmp = 0;

        for (int i=0; i<keys.size(); i++) {
            FieldMetaInfo fmi = keys.get(i);
            try {
                switch (fmi.getType()) {
                    case CHAR:
                        cmp = Character.compare(_obj.getChar(fmi.getName()), obj.getChar(fmi.getName()));
                        break;
                    case STRING:
                        cmp = _obj.getString(fmi.getName()).compareTo(obj.getString(fmi.getName()));
                        break;
                    case SHORT:
                        cmp = Short.compare(_obj.getShort(fmi.getName()), obj.getShort(fmi.getName()));
                        break;
                    case INT:
                        cmp = Integer.compare(_obj.getInt(fmi.getName()), obj.getInt(fmi.getName()));
                        break;
                    case LONG:
                        cmp = Long.compare(_obj.getLong(fmi.getName()), obj.getLong(fmi.getName()));
                        break;
                    case FLOAT:
                        cmp = Float.compare(_obj.getFloat(fmi.getName()), obj.getFloat(fmi.getName()));
                        break;
                    case DOUBLE:
                        cmp = Double.compare(_obj.getDouble(fmi.getName()), obj.getDouble(fmi.getName()));
                        break;
                    case BOOLEAN:
                        cmp = Boolean.compare(_obj.getBoolean(fmi.getName()), obj.getBoolean(fmi.getName()));
                        break;
                    case TIMESTAMP:
                        cmp = Long.compare(_obj.getTimestamp(fmi.getName()), obj.getTimestamp(fmi.getName()));
                        break;
                    case NANOS:
                        cmp = Long.compare(_obj.getNanos(fmi.getName()), obj.getNanos(fmi.getName()));
                        break;
                    case TIME:
                        cmp = Integer.compare(_obj.getTime(fmi.getName()), obj.getTime(fmi.getName()));
                        break;
                    case DATE:
                        cmp = Integer.compare(_obj.getDate(fmi.getName()), obj.getDate(fmi.getName()));
                        break;
                    case ENUM:
                        cmp = Integer.compare(_obj.getEnum(fmi.getName()).ordinal(), obj.getEnum(fmi.getName()).ordinal());
                        break;
                    case UNKNOWN:
                }
            } catch (Exception x) {
                log.error("Error computing compareTo for "+this, x);
                throw new RuntimeException(x);
            }
            if (cmp != 0) {
                return cmp;
            }
        }
        return cmp;
    }
}
