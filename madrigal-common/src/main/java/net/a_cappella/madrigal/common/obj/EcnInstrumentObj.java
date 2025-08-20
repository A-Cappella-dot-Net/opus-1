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

public class EcnInstrumentObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(EcnInstrumentObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_INSTRUMENT; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_INSTRUMENT; }

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
                    new FieldMetaInfo("securityID"),
                    new FieldMetaInfo("symbol"),
                    new FieldMetaInfo("ecn")
            ),
            Arrays.asList(
                    new FieldMetaInfo("maturityDate"),
                    new FieldMetaInfo("couponRate"),
                    new FieldMetaInfo("contractMultiplier"),
                    new FieldMetaInfo("minPriceIncrement"),
                    new FieldMetaInfo("minQty"),
                    new FieldMetaInfo("minQtyIncrement"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            256);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _securityID; // cusip
    private String _symbol; // exchange id
    private int _maturityDate;
    private double _couponRate;
    private double _minPriceIncrement;
    private double _contractMultiplier;
    private double _minQty;
    private double _minQtyIncrement;

    private String _ecn;
	private long _ts;

	@Override // IPoolable
	public void reset() {
		super.reset();

		_securityID = null;
		_symbol = null;
		_maturityDate = 0;
		_couponRate = Double.NaN;
		_contractMultiplier = Double.NaN;
		_minPriceIncrement = Double.NaN;
		_minQty = Double.NaN;
		_minQtyIncrement = Double.NaN;
		_ecn = null;
		_ts = 0;
	}

	public void set(String securityID, String symbol, int maturityDate, double couponRate,
			double contractMultiplier, double minPriceIncrement, double minQty, double minQtyIncrement,
			String ecn, long ts) {
		_securityID = securityID;
		_symbol = symbol;
		_maturityDate = maturityDate;
		_couponRate = couponRate;
		_contractMultiplier = contractMultiplier;
		_minPriceIncrement = minPriceIncrement;
		_minQty = minQty;
		_minQtyIncrement = minQtyIncrement;
        _ecn = ecn;
        _ts = ts;
	}

    public String getSecurityID() {
        return _securityID;
    }
    public String getSymbol() {
        return _symbol;
    }
    public int getMaturityDate() {
    	return _maturityDate;
    }
    public double getCouponRate() {
    	return _couponRate;
    }
    public double getContractMultiplier() {
    	return _contractMultiplier;
    }
    public double getMinPriceIncrement() {
    	return _minPriceIncrement;
    }
    public double getMinQty() {
    	return _minQty;
    }
    public double getMinQtyIncrement() {
    	return _minQtyIncrement;
    }
    public String getEcn() {
        return _ecn;
    }
	public long getTs() {
		return _ts;
	}

    public void setSecurityID(String securityID) {
		_securityID = securityID;
	}
	public void setSymbol(String symbol) {
		_symbol = symbol;
	}
	public void setMaturityDate(int maturityDate) {
		_maturityDate = maturityDate;
	}
	public void setCouponRate(double couponRate) {
		_couponRate = couponRate;
	}
	public void setContractMultiplier(double contractMultiplier) {
		_contractMultiplier = contractMultiplier;
	}
	public void setMinPriceIncrement(double minPriceIncrement) {
		_minPriceIncrement = minPriceIncrement;
	}
	public void setMinQty(double minQty) {
		_minQty = minQty;
	}
	public void setMinQtyIncrement(double minQtyIncrement) {
		_minQtyIncrement = minQtyIncrement;
	}
	public void setEcn(String ecn) {
		_ecn = ecn;
	}
	public void setTs(long ts) {
		_ts = ts;
	}

	@Override
	public int getInt(String fieldName) throws Exception {
		if ("maturityDate".equalsIgnoreCase(fieldName)) return _maturityDate;
		return super.getInt(fieldName); // throws exception
	}
	@Override
	public void setInt(String fieldName, int value) throws Exception {
		if ("maturityDate".equalsIgnoreCase(fieldName)) _maturityDate = value;
		else super.setInt(fieldName, value); // throws exception
	}

	@Override
	public double getDouble(String fieldName) throws Exception {
		if ("couponRate".equalsIgnoreCase(fieldName)) return _couponRate;
		if ("contractMultiplier".equalsIgnoreCase(fieldName)) return _contractMultiplier;
		if ("minPriceIncrement".equalsIgnoreCase(fieldName)) return _minPriceIncrement;
		if ("minQty".equalsIgnoreCase(fieldName)) return _minQty;
		if ("minQtyIncrement".equalsIgnoreCase(fieldName)) return _minQtyIncrement;
		return super.getDouble(fieldName); // throws exception
	}
	@Override
	public void setDouble(String fieldName, double value) throws Exception {
		if ("couponRate".equalsIgnoreCase(fieldName)) _couponRate = value;
		else if ("contractMultiplier".equalsIgnoreCase(fieldName)) _contractMultiplier = value;
		else if ("minPriceIncrement".equalsIgnoreCase(fieldName)) _minPriceIncrement = value;
		else if ("minQty".equalsIgnoreCase(fieldName)) _minQty = value;
		else if ("minQtyIncrement".equalsIgnoreCase(fieldName)) _minQtyIncrement = value;
		else super.setDouble(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) return _securityID;
		if ("symbol".equalsIgnoreCase(fieldName)) return _symbol;
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) _securityID = value;
		else if ("symbol".equalsIgnoreCase(fieldName)) _symbol = value;
		else if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
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
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+
				"{"+_ecn+" "+_symbol+" "+_securityID+" "+_maturityDate+" "+_couponRate+" "+_contractMultiplier+" "+
				_minPriceIncrement+" "+_minQty+" "+_minQtyIncrement+" "+Utils.formatMillis(_ts)+"}";
	}
}
