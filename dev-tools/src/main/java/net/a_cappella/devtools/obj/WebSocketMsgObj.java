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

package net.a_cappella.devtools.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.obj.ObjImpl;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class WebSocketMsgObj extends ObjImpl {

    @Override
    public int getMsgType() { return DevToolsConstants.TYPE_WEBSOCKET_MSG; }
    @Override
    public String getDefaultSubject() { return DevToolsConstants.SUBJ_WEBSOCKET_MSG; }

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
            Arrays.asList(new FieldMetaInfo("remote")),
            Arrays.asList(new FieldMetaInfo("msg")));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _remote;
    private String _msg;

    public WebSocketMsgObj() {}

    public WebSocketMsgObj(WebSocketMsgObj obj) {
        super(obj);
        _remote = obj._remote;
        _msg = obj._msg;
    }

    public WebSocketMsgObj set(String remote, String msg) {
        _remote = remote;
        _msg = msg;
        return this;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _remote = null;
        _msg = null;
    }

    public String getRemote() {
        return _remote;
    }
    public void setRemote(String remote) {
        _remote = remote;
    }
    public String getMsg() {
        return _msg;
    }
    public void setMsg(String msg) {
        _msg = msg;
    }

    public String toString() {
        return super.toString()+" {"+_remote+" "+_msg+"} ";
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("remote".equalsIgnoreCase(fieldName)) return _remote;
        if ("msg".equalsIgnoreCase(fieldName)) return _msg;
        return super.getString(fieldName); // throws exception
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("remote".equalsIgnoreCase(fieldName)) _remote = value;
        if ("msg".equalsIgnoreCase(fieldName)) _msg = value;
        else super.setString(fieldName, value); // throws exception
    }

}
