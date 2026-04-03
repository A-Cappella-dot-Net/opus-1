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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class CredentialsObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(CredentialsObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_CREDENTIALS; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_CREDENTIALS; }

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
                    new FieldMetaInfo("uid")
            ),
            Arrays.asList(
                    new FieldMetaInfo("pwd"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            128);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _uid;
	private String _pwd;
	private long _ts;

	public void reset() {
		super.reset();
		_uid = null;
		_pwd = null;
		_ts = 0;
	}

	public void set(String uid, String pwd, long ts) {
		_uid = uid;
		_pwd = pwd;
		_ts = ts;
	}

	public String getUid() {
		return _uid;
	}
	public String getPwd() {
		return _pwd;
	}
	public long getTs() {
		return _ts;
	}

	public void setUid(String uid) {
		_uid = uid;
	}
	public void setPwd(String pwd) {
		_pwd = pwd;
	}
	public void setTs(long ts) {
		_ts = ts;
	}
	@Override
	public String getString(String fieldName) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) return _uid;
		if ("pwd".equalsIgnoreCase(fieldName)) return _pwd;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) _uid = value;
		else if ("pwd".equalsIgnoreCase(fieldName)) _pwd = value;
		else super.setString(fieldName, value); // throws exception
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

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+_uid+"/"+_pwd+" "+Utils.formatMillis(_ts)+"}";
	}
}
