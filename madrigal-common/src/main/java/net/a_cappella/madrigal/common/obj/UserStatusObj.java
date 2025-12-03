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
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.*;

public class UserStatusObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(UserStatusObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_USR_STATUS; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_USR_STATUS; }

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
                    new FieldMetaInfo("uid"),
                    new FieldMetaInfo("clId"),
					new FieldMetaInfo("reqId")
            ),
            Arrays.asList(
                    new FieldMetaInfo("op"),               // mode = REQUEST
                    new FieldMetaInfo("pwd"),              // mode = REQUEST
                    new FieldMetaInfo("rejectIfLoggedIn"), // mode = REQUEST & op = LOGIN
                    new FieldMetaInfo("forceLogout"),      // mode = REQUEST & op = LOGOUT
                    new FieldMetaInfo("status"),    // mode = RESPONSE
                    new FieldMetaInfo("reqStatus"), // mode = RESPONSE
                    new FieldMetaInfo("text"),      // mode = RESPONSE
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            256);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private MadrigalMode _mode;
    private String _uid;

    private String _clId;
	private int _reqId;
    private MadrigalLogOp _op;
    private String _pwd;
    private boolean _rejectIfLoggedIn;
    private boolean _forceLogout;
    private MadrigalUserStatus _status = MadrigalUserStatus.Off;
    private MadrigalUserStatus _reqStatus = MadrigalUserStatus.Off;
    private String _text;
	private long _ts;

	public UserStatusObj() {}

	public UserStatusObj(UserStatusObj obj) {
		_mode = obj._mode;
		_uid = obj._uid;
		_clId = obj._clId;
		_reqId = obj._reqId;
		_op = obj._op;
		_pwd = obj._pwd;
		_rejectIfLoggedIn = obj._rejectIfLoggedIn;
		_forceLogout = obj._forceLogout;
		_status = obj._status;
		_reqStatus = obj._reqStatus;
		_text = obj._text;
		_ts = obj._ts;
	}

	@Override // IPoolable
	public void reset() {
		super.reset();

		_mode = NULL_VAL;
		_uid = null;
		_clId = null;
		_reqId = -1;
		_op = null;
		_pwd = null;
		_rejectIfLoggedIn = false;
		_forceLogout = false;
		_status = null;
		_reqStatus = null;
		_text = null;
		_ts = 0;
	}

	public void setRequest(String uid, String clId, int reqId, MadrigalLogOp op, String pwd, boolean rejectIfLoggedIn, boolean forceLogout, long ts) {
		_mode = REQUEST;
        _uid = uid;
        _clId = clId;
		_reqId = reqId;
        _op = op;
        _pwd = pwd;
        _rejectIfLoggedIn = rejectIfLoggedIn;
        _forceLogout = forceLogout;
        _ts = ts;
	}

	public void setResponse(String uid, String clId, int reqId, MadrigalLogOp op, MadrigalUserStatus status, MadrigalUserStatus reqStatus, String text, long ts) {
		_mode = RESPONSE;
        _uid = uid;
        _clId = clId;
		_reqId = reqId;
        _op = op;
        _status = status;
        _reqStatus = reqStatus;
        _text = text;
        _ts = ts;
	}

    public MadrigalMode getMadrigalMode() {
        return _mode;
    }
    public void setMadrigalMode(MadrigalMode mode) {
        _mode = mode;
    }
    public String getUid() {
        return _uid;
    }
	public void setUid(String uid) {
		_uid = uid;
	}
    public String getClId() {
        return _clId;
    }
	public void setClId(String clId) {
		_clId = clId;
	}
	public int getReqId() {
		return _reqId;
	}
	public void setReqId(int reqId) {
		_reqId = reqId;
	}
    public MadrigalLogOp getOp() {
        return _op;
    }
	public void setOp(MadrigalLogOp op) {
		_op = op;
	}
    public String getPwd() {
        return _pwd;
    }
	public void setPwd(String pwd) {
		_pwd = pwd;
	}
	public boolean isRejectIfLoggedIn() {
    	return _rejectIfLoggedIn;
    }
	public void setRejectIfLoggedIn(boolean rejectIfLoggedIn) {
		_rejectIfLoggedIn = rejectIfLoggedIn;
	}
    public boolean isForceLogout() {
    	return _forceLogout;
    }
	public void setForceLogout(boolean forceLogout) {
		_forceLogout = forceLogout;
	}
    public MadrigalUserStatus getStatus() {
        return _status;
    }
    public void setStatus(MadrigalUserStatus status) {
        _status = status;
    }
    public MadrigalUserStatus getReqStatus() {
        return _reqStatus;
    }
    public void setReqStatus(MadrigalUserStatus reqStatus) {
        _reqStatus = reqStatus;
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
		if ("reqId".equalsIgnoreCase(fieldName)) return _reqId;
		return super.getInt(fieldName); // throws exception
	}
	@Override
	public void setInt(String fieldName, int value) throws Exception {
		if ("reqId".equalsIgnoreCase(fieldName)) _reqId = value;
		else super.setInt(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) return _uid;
		if ("pwd".equalsIgnoreCase(fieldName)) return _pwd;
		if ("clId".equalsIgnoreCase(fieldName)) return _clId;
		if ("text".equalsIgnoreCase(fieldName)) return _text;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) _uid = value;
		else if ("pwd".equalsIgnoreCase(fieldName)) _pwd = value;
		else if ("clId".equalsIgnoreCase(fieldName)) _clId = value;
		else if ("text".equalsIgnoreCase(fieldName)) _text = value;
		else super.setString(fieldName, value); // throws exception
	}

	@Override
	public boolean getBoolean(String fieldName) throws Exception {
		if ("forceLogout".equalsIgnoreCase(fieldName)) return _forceLogout;
		if ("rejectIfLoggedIn".equalsIgnoreCase(fieldName)) return _rejectIfLoggedIn;
		return super.getBoolean(fieldName); // throws exception
	}
	@Override
	public void setBoolean(String fieldName, boolean value) throws Exception {
		if ("forceLogout".equalsIgnoreCase(fieldName)) _forceLogout = value;
		else if ("rejectIfLoggedIn".equalsIgnoreCase(fieldName)) _rejectIfLoggedIn = value;
		else super.setBoolean(fieldName, value); // throws exception
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
		if ("reqStatus".equalsIgnoreCase(fieldName)) return _reqStatus;
		if ("op".equalsIgnoreCase(fieldName)) return _op;
		return super.getEnum(fieldName); // throws exception
	}

	public void setEnum(String fieldName, Enum<?> value) throws Exception {
		if ("mode".equalsIgnoreCase(fieldName)) _mode = (MadrigalMode) value;
		else if ("status".equalsIgnoreCase(fieldName)) _status = (MadrigalUserStatus) value;
		else if ("reqStatus".equalsIgnoreCase(fieldName)) _reqStatus = (MadrigalUserStatus) value;
		else if ("op".equalsIgnoreCase(fieldName)) _op = (MadrigalLogOp) value;
		else super.setEnum(fieldName, value); // throws exception
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+
				_uid+" "+_clId+":"+_reqId+" "+_op+" "+
				((REQUEST==_mode)?(_rejectIfLoggedIn+" "+_forceLogout):(_status+" "+_reqStatus+" "+_text))+" "+Utils.formatMillis(_ts)+"}";
	}
}
