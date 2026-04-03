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
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.presto.monitor.IStaleable;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.*;
import static net.a_cappella.madrigal.common.constants.MadrigalUserStatus.Off;

public class EcnUserStatusObj extends ObjImpl implements IStaleable {
    private static final Logger log = LoggerFactory.getLogger(EcnUserStatusObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_USR_STATUS; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_USR_STATUS; }

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
                    new FieldMetaInfo("mode"),
                    new FieldMetaInfo("instance"),
                    new FieldMetaInfo("uid"),
                    new FieldMetaInfo("ecn"),
                    new FieldMetaInfo("ecnUid")
            ),
            Arrays.asList(
                    new FieldMetaInfo("op"),     // mode = REQUEST
                    new FieldMetaInfo("ecnPwd"), // mode = REQUEST
                    new FieldMetaInfo("status"), // mode = RESPONSE
                    new FieldMetaInfo("text"),   // mode = RESPONSE
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            256);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private MadrigalMode _mode;
    private int _instance = -1;
    private String _uid;
    private String _ecn;
    private String _ecnUid;

    private MadrigalLogOp _op;
    private String _ecnPwd;
    private MadrigalUserStatus _status;
    private String _text;
	private long _ts;

	@Override // IStaleable
	public void stale() {
		_status = Off;
		_text = "due to disconnect";
		_ts = System.currentTimeMillis();
	}
	public boolean isStale() {
		return _status == Off;
	}

	@Override // IPoolable
	public void reset() {
		super.reset();

		_mode = NULL_VAL;
		_instance = -1;
		_uid = null;
		_ecn = null;
		_ecnUid = null;
		_op = null;
		_ecnPwd = null;
		_status = null;
		_text = null;
		_ts = 0;
	}

	public void setRequest(int instance, String uid, String ecn, String ecnUid, String ecnPwd, MadrigalLogOp op, long ts) {
		_mode = REQUEST;
		_instance = instance;
        _uid = uid;
        _ecn = ecn;
        _ecnUid = ecnUid;
        _op = op;
        _ecnPwd = ecnPwd;
        _ts = ts;
	}

	public void setResponse(int instance, String uid, String ecn, String ecnUid, String ecnPwd, MadrigalLogOp op, MadrigalUserStatus status, String text, long ts) {
		_mode = RESPONSE;
		_instance = instance;
        _uid = uid;
        _ecn = ecn;
        _ecnUid = ecnUid;
        _ecnPwd = ecnPwd;
        _op = op;
        _status = status;
        _text = text;
        _ts = ts;
	}

    public MadrigalMode getMadrigalMode() {
        return _mode;
    }
    public void setMadrigalMode(MadrigalMode mode) {
        _mode = mode;
    }
    public int getInstance() {
    	return _instance;
    }
    public void setInstance(int instance) {
    	_instance = instance;
    }
    public String getUid() {
        return _uid;
    }
	public void setUid(String uid) {
		_uid = uid;
	}
    public String getEcn() {
        return _ecn;
    }
	public void setEcn(String ecn) {
		_ecn = ecn;
	}
    public String getEcnUid() {
        return _ecnUid;
    }
	public void setEcnUid(String ecnUid) {
		_ecnUid = ecnUid;
	}
    public MadrigalLogOp getOp() {
        return _op;
    }
	public void setOp(MadrigalLogOp op) {
		_op = op;
	}
    public String getEcnPwd() {
        return _ecnPwd;
    }
	public void setEcnPwd(String ecnPwd) {
		_ecnPwd = ecnPwd;
	}
    public MadrigalUserStatus getStatus() {
        return _status;
    }
    public void setStatus(MadrigalUserStatus status) {
        _status = status;
    }
    public String getText() {
        return _text;
    }
    public void setText(String text) {
        _text = text;
    }
    public long getTs() {
    	return _ts;
    }
    public void setTs(long ts) {
    	_ts = ts;
    }


	@Override
	public int getInt(String fieldName) throws Exception {
		if ("instance".equalsIgnoreCase(fieldName)) return _instance;
		return super.getInt(fieldName); // throws exception
	}
	@Override
	public void setInt(String fieldName, int value) throws Exception {
		if ("instance".equalsIgnoreCase(fieldName)) _instance = value;
		else super.setInt(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) return _uid;
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		if ("ecnUid".equalsIgnoreCase(fieldName)) return _ecnUid;
		if ("ecnPwd".equalsIgnoreCase(fieldName)) return _ecnPwd;
		if ("text".equalsIgnoreCase(fieldName)) return _text;
		return super.getString(fieldName); // throws exception
	}
	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) _uid = value;
		else if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		else if ("ecnUid".equalsIgnoreCase(fieldName)) _ecnUid = value;
		else if ("ecnPwd".equalsIgnoreCase(fieldName)) _ecnPwd = value;
		else if ("text".equalsIgnoreCase(fieldName)) _text = value;
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

	@Override
	public Enum<?> getEnum(String fieldName) throws Exception {
		if ("mode".equalsIgnoreCase(fieldName)) return _mode;
		if ("status".equalsIgnoreCase(fieldName)) return _status;
		if ("op".equalsIgnoreCase(fieldName)) return _op;
		return super.getEnum(fieldName); // throws exception
	}
	public void setEnum(String fieldName, Enum<?> value) throws Exception {
		if ("mode".equalsIgnoreCase(fieldName)) _mode = (MadrigalMode) value;
		else if ("status".equalsIgnoreCase(fieldName)) _status = (MadrigalUserStatus) value;
		else if ("op".equalsIgnoreCase(fieldName)) _op = (MadrigalLogOp) value;
		else super.setEnum(fieldName, value); // throws exception
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+
				_instance+" "+_uid+" "+_ecn+" "+_ecnUid+" "+_ecnPwd+" "+_op+" "+((REQUEST==_mode)?(""):(_status+" "+_text+" "))+Utils.formatMillis(_ts)+"}";
	}
}
