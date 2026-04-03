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

package net.a_cappella.continuo.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.managed.IPoolable;
import net.a_cappella.continuo.msg.ITypedMsg;
import net.a_cappella.continuo.msg.Rtg;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.ps.IMergeManager;

import java.lang.reflect.Constructor;
import java.util.Map;
import java.util.Set;

public interface Obj extends ITypedMsg, IPoolable {

    // static fields
    void setStaticFields(Constructor<? extends Coder> coderConstructor, ObjPriority priority) throws Exception;
    Constructor<? extends Coder> getCoderConstructor();
    // meta info
    ObjMetaInfo getObjMetaInfo();
    void setObjMetaInfo(ObjMetaInfo metaInfo);
    // priority
    ObjPriority getPriority();
    // routing
    Rtg getRtg();
    void copyRoutingFields(Obj obj);

    // header fields
    String getDefaultSubject();
    void setSubject(String subject);
    String getSubject();
    void setPubType(PubType pubType);
    PubType getPubType();
    long getSerialId();
    void setSerialId(long serialId);
    long getSeqNo();
    void setSeqNo(long seqNo);
    // performance fields
    long getTsNanos();
    void setTsNanos(long tsNanos);
    short getMine();
    short setMine(short mine);
    boolean isBackPressured();
    boolean setBackPressured(boolean backPressured);
    boolean isOnLoopback();
    boolean setOnLoopback(boolean onLoopback);

    // routing
    void setRequestId(long requestId);
    long getRequestId();

    // unique identifier
    ObjKey getObjKey();

    // typed accessors used in SnS sql evaluation; less efficient than named accessors
    short getShort(String fieldName) throws Exception;
    void setShort(String fieldName, short value) throws Exception;
    int getInt(String fieldName) throws Exception;
    void setInt(String fieldName, int value) throws Exception;
    long getLong(String fieldName) throws Exception;
    void setLong(String fieldName, long value) throws Exception;
    float getFloat(String fieldName) throws Exception;
    void setFloat(String fieldName, float value) throws Exception;
    double getDouble(String fieldName) throws Exception;
    void setDouble(String fieldName, double value) throws Exception;
    boolean getBoolean(String fieldName) throws Exception;
    void setBoolean(String fieldName, boolean value) throws Exception;
    char getChar(String fieldName) throws Exception;
    void setChar(String fieldName, char value) throws Exception;
    String getString(String fieldName) throws Exception;
    void setString(String fieldName, String value) throws Exception;

    long getTimestamp(String fieldName) throws Exception;
    void setTimestamp(String fieldName, long value) throws Exception;
    long getNanos(String fieldName) throws Exception;
    void setNanos(String fieldName, long value) throws Exception;
    int getTime(String fieldName) throws Exception;
    void setTime(String fieldName, int value) throws Exception;
    int getDate(String fieldName) throws Exception;
    void setDate(String fieldName, int value) throws Exception;

    Enum<?> getEnum(String fieldName) throws Exception;
    void setEnum(String fieldName, Enum<?> value) throws Exception;

    Object getAdHoc(String key);
    void setAdHoc(String key, Object value);

    // uniform accessors used in graphical tools; less efficient than typed accessors
    int getNumFields();
    FieldMetaInfo getFieldMetaInfo(int i);
    Object get(String fieldName);
    Object get(int i);
    void set(Map<String, Object> map) throws Exception;

    // ad hocs
    boolean hasAdHocs();
    Map<String, Object> getAdHocs();
    void setAdHocs(Map<String, Object> adHocs);
    void addAdHocs(Map<String, Object> adHocs);
    Set<String> getAdHocFields();

    IMergeManager newMergeManager();
}
