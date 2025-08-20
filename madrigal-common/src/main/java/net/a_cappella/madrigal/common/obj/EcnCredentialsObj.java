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

public class EcnCredentialsObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(EcnCredentialsObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_CREDENTIALS; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_CREDENTIALS; }

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
                    new FieldMetaInfo("uid"),
                    new FieldMetaInfo("ecn")
            ),
            Arrays.asList(
                    new FieldMetaInfo("ecnUid"),
                    new FieldMetaInfo("ecnPwd"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            256);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _uid;
    private String _ecn;
    private String _ecnUid;
    private String _ecnPwd;
	private long _ts;

	public void reset() {
		super.reset();
		_uid = null;
		_ecn = null;
		_ecnUid = null;
		_ecnPwd = null;
	}

	public void set(String uid, String ecn, String ecnUid, String ecnPwd, long ts) {
        _uid = uid;
        _ecn = ecn;
        _ecnUid = ecnUid;
        _ecnPwd = ecnPwd;
        _ts = ts;
	}

	public String getUid() {
        return _uid;
    }
    public String getEcn() {
        return _ecn;
    }
    public String getEcnUid() {
        return _ecnUid;
    }
    public String getEcnPwd() {
        return _ecnPwd;
    }
    public long getTs() {
    	return _ts;
    }

    public void setUid(String uid) {
		_uid = uid;
	}
	public void setEcn(String ecn) {
		_ecn = ecn;
	}
	public void setEcnUid(String ecnUid) {
		_ecnUid = ecnUid;
	}
	public void setEcnPwd(String ecnPwd) {
		_ecnPwd = ecnPwd;
	}
	public void setTs(long ts) {
		_ts = ts;
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) return _uid;
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		if ("ecnUid".equalsIgnoreCase(fieldName)) return _ecnUid;
		if ("ecnPwd".equalsIgnoreCase(fieldName)) return _ecnPwd;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("uid".equalsIgnoreCase(fieldName)) _uid = value;
		else if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		else if ("ecnUid".equalsIgnoreCase(fieldName)) _ecnUid = value;
		else if ("ecnPwd".equalsIgnoreCase(fieldName)) _ecnPwd = value;
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
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+_uid+" "+_ecn+" "+_ecnUid+"/"+_ecnPwd+" "+Utils.formatMillis(_ts)+"}";
	}
}
