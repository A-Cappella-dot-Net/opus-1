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

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ft.constants.FtMsgOp;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class FtMemberObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_FT_MEMBER; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_FT_MEMBER; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) throws Exception {
        _codCtor = codCtor;
        _priority = priority;
        _staticMetaInfo.updateMetaInfoFromInstance(this);
    }

    private static Constructor<? extends Coder> _codCtor;
    @Override
    public Constructor<? extends Coder> getCoderConstructor() {
        return _codCtor;
    }

    private static ObjPriority _priority;
    @Override
    public ObjPriority getPriority() {
        return _priority;
    }

    private static final ObjMetaInfo _staticMetaInfo = new ObjMetaInfo(
            Arrays.asList(
                    new FieldMetaInfo("groupName"),
                    new FieldMetaInfo("instance")
            ),
            Arrays.asList(
                    new FieldMetaInfo("action"),
                    new FieldMetaInfo("stripeNo"),
                    new FieldMetaInfo("ofStripes"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _groupName;
    private int _instance;
    private FtMsgOp _action;
    private int _stripeNo;
    private int _ofStripes;
    private long _ts;

    public FtMemberObj() {}

    public FtMemberObj(FtMemberObj obj) {
        super(obj);
        _groupName = obj._groupName;
        _instance = obj._instance;
        _action = obj._action;
        _stripeNo = obj._stripeNo;
        _ofStripes = obj._ofStripes;
    }

    public FtMemberObj set(String groupName, int instance, FtMsgOp action, int stripeNo, int ofStripes, long ts) {
        _groupName = groupName;
        _instance = instance;
        _action = action;
        _stripeNo = stripeNo;
        _ofStripes = ofStripes;
        _ts = ts;
        return this;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _groupName = null;
        _instance = 0;
        _action = null;
        _stripeNo = 0;
        _ofStripes = 0;
        _ts = 0;
    }

    public String getGroupName() {
        return _groupName;
    }
    public void setGroupName(String groupName) {
        _groupName = groupName;
    }
    public int getInstance() {
        return _instance;
    }
    public void setInstance(int instance) {
        _instance = instance;
    }
    public FtMsgOp getAction() {
        return _action;
    }
    public void setAction(FtMsgOp action) {
        _action = action;
    }
    public int getStripeNo() {
        return _stripeNo;
    }
    public void setStripeNo(int stripeNo) {
        _stripeNo = stripeNo;
    }
    public int getOfStripes() {
        return _ofStripes;
    }
    public void setOfStripes(int ofStripes) {
        _ofStripes = ofStripes;
    }
    public long getTs() {
        return _ts;
    }
    public void setTs(long ts) {
        _ts = ts;
    }

    public String toString() {
        return super.toString()+" {"+_groupName+" "+_instance+" => "+_action+" "+ _stripeNo +"/"+ _ofStripes +" "+ Utils.formatMillis(_ts)+"} ";
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("groupName".equalsIgnoreCase(fieldName)) return _groupName;
        return super.getString(fieldName); // throws exception
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("groupName".equalsIgnoreCase(fieldName)) _groupName = value;
        else super.setString(fieldName, value); // throws exception
    }

    @Override
    public int getInt(String fieldName) throws Exception {
        if ("instance".equalsIgnoreCase(fieldName)) return _instance;
        if ("stripeNo".equalsIgnoreCase(fieldName)) return _stripeNo;
        if ("ofStripes".equalsIgnoreCase(fieldName)) return _ofStripes;
        return super.getInt(fieldName); // throws exception
    }
    @Override
    public void setInt(String fieldName, int value) throws Exception {
        if ("instance".equalsIgnoreCase(fieldName)) _instance = value;
        if ("stripeNo".equalsIgnoreCase(fieldName)) _stripeNo = value;
        if ("ofStripes".equalsIgnoreCase(fieldName)) _ofStripes = value;
        else super.setInt(fieldName, value); // throws exception
    }

    @Override
    public long getTimestamp(String fieldName) throws Exception {
        if ("ts".equalsIgnoreCase(fieldName)) return _ts;
        return super.getTimestamp(fieldName); // throws exception
    }
    @Override
    public void setTimestamp(String fieldName, long value) throws Exception {
        if ("ts".equalsIgnoreCase(fieldName)) _ts = value;
        else super.setTimestamp(fieldName, value); // throws exception
    }

    @Override
    public Enum<?> getEnum(String fieldName) throws Exception {
        if ("action".equalsIgnoreCase(fieldName)) return _action;
        return super.getEnum(fieldName); // throws exception
    }
    @Override
    public void setEnum(String fieldName, Enum<?> value) throws Exception {
        if ("action".equalsIgnoreCase(fieldName)) _action = (FtMsgOp) value;
        else super.setEnum(fieldName, value); // throws exception
    }
}
