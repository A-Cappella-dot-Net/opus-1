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

public class FinalizeOrderObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(FinalizeOrderObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_FINALIZE_ORDER; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_FINALIZE_ORDER; }

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
                    new FieldMetaInfo("ecn"),
                    new FieldMetaInfo("ordId")
            ),
            Arrays.asList(
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            32);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

	private String _ecn;
    private String _ordId;
	private long _ts;

	public void reset() {
		super.reset();
		_ecn = null;
		_ordId = null;
		_ts = 0;
	}

	public void set(String ecn, String ordId, long ts) {
		_ecn = ecn;
        _ordId = ordId;
        _ts = ts;
	}

    public String getEcn() {
        return _ecn;
    }
    public void setEcn(String ecn) {
        _ecn = ecn;
    }
    public String getOrdId() {
        return _ordId;
    }
    public void setOrdId(String ordId) {
        _ordId = ordId;
    }
    public long getTs() {
    	return _ts;
    }
    public void setTs(long ts) {
    	_ts = ts;
    }

	@Override
	public String getString(String fieldName) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		if ("ordId".equalsIgnoreCase(fieldName)) return _ordId;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		if ("ordId".equalsIgnoreCase(fieldName)) _ordId = value;
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
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+_ecn+" "+_ordId+" "+Utils.formatMillis(_ts)+"}";
	}
}
