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

public class MidFeedObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(MidFeedObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_MID_FEED; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_MID_FEED; }

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
                    new FieldMetaInfo("instrId")
            ),
            Arrays.asList(
                    new FieldMetaInfo("mid"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            128);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _instrId;
    private double _mid;
	private long _ts;

	public void reset() {
		super.reset();
		_instrId = null;
		_mid = Double.NaN;
	}

	public void set(String instrId, double mid, long ts) {
		_instrId = instrId;
        _mid = mid;
        _ts = ts;
	}

    public String getInstrId() {
        return _instrId;
    }
    public double getMid() {
        return _mid;
    }
    public long getTs() {
    	return _ts;
    }

    public void setInstrId(String instrId) {
		_instrId = instrId;
	}
	public void setMid(double mid) {
		_mid = mid;
	}
	public void setTs(long ts) {
		_ts = ts;
	}

	@Override
	public double getDouble(String fieldName) throws Exception {
		if ("mid".equalsIgnoreCase(fieldName)) return _mid;
		return super.getDouble(fieldName); // throws exception
	}

	@Override
	public void setDouble(String fieldName, double value) throws Exception {
		if ("mid".equalsIgnoreCase(fieldName)) _mid = value;
		else super.setDouble(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("instrId".equalsIgnoreCase(fieldName)) return _instrId;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("instrId".equalsIgnoreCase(fieldName)) _instrId = value;
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
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+_instrId+" "+Utils.frc(_mid)+" "+Utils.formatMillis(_ts)+"}";
	}
}
