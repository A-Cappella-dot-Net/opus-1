package net.a_cappella.madrigal.common.obj;

import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.presto.monitor.IStaleable;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;
import java.util.Date;

public class EcnPriceObj extends ObjImpl implements IStaleable {
    private static final Logger log = LoggerFactory.getLogger(EcnPriceObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_PRICE; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_PRICE; }

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
                    new FieldMetaInfo("instrId")
            ),
            Arrays.asList(
                    new FieldMetaInfo("bid0"),
                    new FieldMetaInfo("bid1"),
                    new FieldMetaInfo("bid2"),
                    new FieldMetaInfo("bid3"),
                    new FieldMetaInfo("bid4"),
                    new FieldMetaInfo("bidSize0"),
                    new FieldMetaInfo("bidSize1"),
                    new FieldMetaInfo("bidSize2"),
                    new FieldMetaInfo("bidSize3"),
                    new FieldMetaInfo("bidSize4"),
                    new FieldMetaInfo("offer0"),
                    new FieldMetaInfo("offer1"),
                    new FieldMetaInfo("offer2"),
                    new FieldMetaInfo("offer3"),
                    new FieldMetaInfo("offer4"),
                    new FieldMetaInfo("offerSize0"),
                    new FieldMetaInfo("offerSize1"),
                    new FieldMetaInfo("offerSize2"),
                    new FieldMetaInfo("offerSize3"),
                    new FieldMetaInfo("offerSize4"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP),
                    new FieldMetaInfo("tsx", FieldType.TIMESTAMP),
                    new FieldMetaInfo("stale")
            ),
            256);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _ecn;
    private String _instrId; // cusip

    private double _bid0 = Double.NaN;
    private double _bid1 = Double.NaN;
    private double _bid2 = Double.NaN;
    private double _bid3 = Double.NaN;
    private double _bid4 = Double.NaN;

    private double _bidSize0;
    private double _bidSize1;
    private double _bidSize2;
    private double _bidSize3;
    private double _bidSize4;

    private double _offer0 = Double.NaN;
    private double _offer1 = Double.NaN;
    private double _offer2 = Double.NaN;
    private double _offer3 = Double.NaN;
    private double _offer4 = Double.NaN;

    private double _offerSize0;
    private double _offerSize1;
    private double _offerSize2;
    private double _offerSize3;
    private double _offerSize4;

    private long _ts;
    private long _tsx;

    private boolean _stale = true;

	@Override // IStaleable
	public void stale() {
		_bid0 = Double.NaN;
		_bid1 = Double.NaN;
		_bid2 = Double.NaN;
		_bid3 = Double.NaN;
		_bid4 = Double.NaN;

		_bidSize0 = Double.NaN;
		_bidSize1 = Double.NaN;
		_bidSize2 = Double.NaN;
		_bidSize3 = Double.NaN;
		_bidSize4 = Double.NaN;

		_offer0 = Double.NaN;
		_offer1 = Double.NaN;
		_offer2 = Double.NaN;
		_offer3 = Double.NaN;
		_offer4 = Double.NaN;

		_offerSize0 = Double.NaN;
		_offerSize1 = Double.NaN;
		_offerSize2 = Double.NaN;
		_offerSize3 = Double.NaN;
		_offerSize4 = Double.NaN;

		_ts = System.currentTimeMillis();
		_tsx = 0;

		_stale = true;
	}

	public boolean isStale() {
		return _stale;
	}
	public void setStale(boolean stale) {
		_stale = stale;
	}

	@Override // IPoolable
	public void reset() {
		super.reset();

		_ecn = null;
		_instrId = null;

		_bid0 = Double.NaN;
		_bid1 = Double.NaN;
		_bid2 = Double.NaN;
		_bid3 = Double.NaN;
		_bid4 = Double.NaN;

		_bidSize0 = Double.NaN;
		_bidSize1 = Double.NaN;
		_bidSize2 = Double.NaN;
		_bidSize3 = Double.NaN;
		_bidSize4 = Double.NaN;

		_offer0 = Double.NaN;
		_offer1 = Double.NaN;
		_offer2 = Double.NaN;
		_offer3 = Double.NaN;
		_offer4 = Double.NaN;

		_offerSize0 = Double.NaN;
		_offerSize1 = Double.NaN;
		_offerSize2 = Double.NaN;
		_offerSize3 = Double.NaN;
		_offerSize4 = Double.NaN;

		_ts = 0;
		_tsx = 0;

		_stale = true;
	}

	public void set(String ecn, String instrId, MarketDataSnapshot mds) {
		_ecn = ecn;
		_instrId = instrId;

		_bid0 = mds._bidEntries[0]._price;
		_bid1 = mds._bidEntries[1]._price;
		_bid2 = mds._bidEntries[2]._price;
		_bid3 = mds._bidEntries[3]._price;
		_bid4 = mds._bidEntries[4]._price;
		_bidSize0 = mds._bidEntries[0]._size;
		_bidSize1 = mds._bidEntries[1]._size;
		_bidSize2 = mds._bidEntries[2]._size;
		_bidSize3 = mds._bidEntries[3]._size;
		_bidSize4 = mds._bidEntries[4]._size;
		_offer0 = mds._offerEntries[0]._price;
		_offer1 = mds._offerEntries[1]._price;
		_offer2 = mds._offerEntries[2]._price;
		_offer3 = mds._offerEntries[3]._price;
		_offer4 = mds._offerEntries[4]._price;
		_offerSize0 = mds._offerEntries[0]._size;
		_offerSize1 = mds._offerEntries[1]._size;
		_offerSize2 = mds._offerEntries[2]._size;
		_offerSize3 = mds._offerEntries[3]._size;
		_offerSize4 = mds._offerEntries[4]._size;

		_ts = System.currentTimeMillis();
		_tsx = mds.getTsx();

		_stale = false;
	}

    public String getEcn() {
        return _ecn;
    }
    public void setEcn(String ecn) {
        _ecn = ecn;
    }
    public String getInstrId() {
        return _instrId;
    }
    public void setInstrId(String instrId) {
        _instrId = instrId;
    }
    public double getBid0() {
    	return _bid0;
    }
    public void setBid0(double bid0) {
    	_bid0 = bid0;
    }
    public double getBid1() {
    	return _bid1;
    }
    public void setBid1(double bid1) {
    	_bid1 = bid1;
    }
    public double getBid2() {
    	return _bid2;
    }
    public void setBid2(double bid2) {
    	_bid2 = bid2;
    }
    public double getBid3() {
    	return _bid3;
    }
    public void setBid3(double bid3) {
    	_bid3 = bid3;
    }
    public double getBid4() {
    	return _bid4;
    }
    public void setBid4(double bid4) {
    	_bid4 = bid4;
    }
    public double getBidSize0() {
    	return _bidSize0;
    }
    public void setBidSize0(double bidSize0) {
    	_bidSize0 = bidSize0;
    }
    public double getBidSize1() {
    	return _bidSize1;
    }
    public void setBidSize1(double bidSize1) {
    	_bidSize1 = bidSize1;
    }
    public double getBidSize2() {
    	return _bidSize2;
    }
    public void setBidSize2(double bidSize2) {
    	_bidSize2 = bidSize2;
    }
    public double getBidSize3() {
    	return _bidSize3;
    }
    public void setBidSize3(double bidSize3) {
    	_bidSize3 = bidSize3;
    }
    public double getBidSize4() {
    	return _bidSize4;
    }
    public void setBidSize4(double bidSize4) {
    	_bidSize4 = bidSize4;
    }
    public double getOffer0() {
    	return _offer0;
    }
    public void setOffer0(double offer0) {
    	_offer0 = offer0;
    }
    public double getOffer1() {
    	return _offer1;
    }
    public void setOffer1(double offer1) {
    	_offer1 = offer1;
    }
    public double getOffer2() {
    	return _offer2;
    }
    public void setOffer2(double offer2) {
    	_offer2 = offer2;
    }
    public double getOffer3() {
    	return _offer3;
    }
    public void setOffer3(double offer3) {
    	_offer3 = offer3;
    }
    public double getOffer4() {
    	return _offer4;
    }
    public void setOffer4(double offer4) {
    	_offer4 = offer4;
    }
    public double getOfferSize0() {
    	return _offerSize0;
    }
    public void setOfferSize0(double offerSize0) {
    	_offerSize0 = offerSize0;
    }
    public double getOfferSize1() {
    	return _offerSize1;
    }
    public void setOfferSize1(double offerSize1) {
    	_offerSize1 = offerSize1;
    }
    public double getOfferSize2() {
    	return _offerSize2;
    }
    public void setOfferSize2(double offerSize2) {
    	_offerSize2 = offerSize2;
    }
    public double getOfferSize3() {
    	return _offerSize3;
    }
    public void setOfferSize3(double offerSize3) {
    	_offerSize3 = offerSize3;
    }
    public double getOfferSize4() {
    	return _offerSize4;
    }
    public void setOfferSize4(double offerSize4) {
    	_offerSize4 = offerSize4;
    }
	public long getTs() {
		return _ts;
	}
	public void setTs(long ts) {
		_ts = ts;
	}
	public long getTsx() {
		return _tsx;
	}
	public void setTsx(long tsx) {
		_tsx = tsx;
	}


	@Override
	public double getDouble(String fieldName) throws Exception {
		if ("bid0".equalsIgnoreCase(fieldName)) return _bid0;
		if ("bid1".equalsIgnoreCase(fieldName)) return _bid1;
		if ("bid2".equalsIgnoreCase(fieldName)) return _bid2;
		if ("bid3".equalsIgnoreCase(fieldName)) return _bid3;
		if ("bid4".equalsIgnoreCase(fieldName)) return _bid4;
		if ("bidSize0".equalsIgnoreCase(fieldName)) return _bidSize0;
		if ("bidSize1".equalsIgnoreCase(fieldName)) return _bidSize1;
		if ("bidSize2".equalsIgnoreCase(fieldName)) return _bidSize2;
		if ("bidSize3".equalsIgnoreCase(fieldName)) return _bidSize3;
		if ("bidSize4".equalsIgnoreCase(fieldName)) return _bidSize4;
		if ("offer0".equalsIgnoreCase(fieldName)) return _offer0;
		if ("offer1".equalsIgnoreCase(fieldName)) return _offer1;
		if ("offer2".equalsIgnoreCase(fieldName)) return _offer2;
		if ("offer3".equalsIgnoreCase(fieldName)) return _offer3;
		if ("offer4".equalsIgnoreCase(fieldName)) return _offer4;
		if ("offerSize0".equalsIgnoreCase(fieldName)) return _offerSize0;
		if ("offerSize1".equalsIgnoreCase(fieldName)) return _offerSize1;
		if ("offerSize2".equalsIgnoreCase(fieldName)) return _offerSize2;
		if ("offerSize3".equalsIgnoreCase(fieldName)) return _offerSize3;
		if ("offerSize4".equalsIgnoreCase(fieldName)) return _offerSize4;
		return super.getDouble(fieldName); // throws exception
	}
	@Override
	public void setDouble(String fieldName, double value) throws Exception {
		if ("bid0".equalsIgnoreCase(fieldName)) _bid0 = value;
		else if ("bid1".equalsIgnoreCase(fieldName)) _bid1 = value;
		else if ("bid2".equalsIgnoreCase(fieldName)) _bid2 = value;
		else if ("bid3".equalsIgnoreCase(fieldName)) _bid3 = value;
		else if ("bid4".equalsIgnoreCase(fieldName)) _bid4 = value;
		else if ("bidSize0".equalsIgnoreCase(fieldName)) _bidSize0 = value;
		else if ("bidSize1".equalsIgnoreCase(fieldName)) _bidSize1 = value;
		else if ("bidSize2".equalsIgnoreCase(fieldName)) _bidSize2 = value;
		else if ("bidSize3".equalsIgnoreCase(fieldName)) _bidSize3 = value;
		else if ("bidSize4".equalsIgnoreCase(fieldName)) _bidSize4 = value;
		else if ("offer0".equalsIgnoreCase(fieldName)) _offer0 = value;
		else if ("offer1".equalsIgnoreCase(fieldName)) _offer1 = value;
		else if ("offer2".equalsIgnoreCase(fieldName)) _offer2 = value;
		else if ("offer3".equalsIgnoreCase(fieldName)) _offer3 = value;
		else if ("offer4".equalsIgnoreCase(fieldName)) _offer4 = value;
		else if ("offerSize0".equalsIgnoreCase(fieldName)) _offerSize0 = value;
		else if ("offerSize1".equalsIgnoreCase(fieldName)) _offerSize1 = value;
		else if ("offerSize2".equalsIgnoreCase(fieldName)) _offerSize2 = value;
		else if ("offerSize3".equalsIgnoreCase(fieldName)) _offerSize3 = value;
		else if ("offerSize4".equalsIgnoreCase(fieldName)) _offerSize4 = value;
		else super.setDouble(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		if ("instrId".equalsIgnoreCase(fieldName)) return _instrId;
		return super.getString(fieldName); // throws exception
	}
	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		else if ("instrId".equalsIgnoreCase(fieldName)) _instrId = value;
		else super.setString(fieldName, value); // throws exception
	}

	@Override
	public boolean getBoolean(String fieldName) throws Exception {
		if ("stale".equalsIgnoreCase(fieldName)) return _stale;
		return _metaInfo.fieldMetaInfo(fieldName).getField().getBoolean(this);
	}
	@Override
	public void setBoolean(String fieldName, boolean value) throws Exception {
		if ("stale".equalsIgnoreCase(fieldName)) _stale = value;
		_metaInfo.fieldMetaInfo(fieldName).getField().setBoolean(this, value);
	}

	@Override
	public long getTimestamp(String fieldName) throws Exception {
		if ("ts".equalsIgnoreCase(fieldName)) return _ts;
		if ("tsx".equalsIgnoreCase(fieldName)) return _tsx;
		return super.getTimestamp(fieldName); // throws exception
	}
	@Override
	public void setTimestamp(String fieldName, long value) throws Exception {
		if ("ts".equalsIgnoreCase(fieldName)) _ts = value;
		else if ("tsx".equalsIgnoreCase(fieldName)) _tsx = value;
		else super.setTimestamp(fieldName, value); // throws exception
	}

	private String level(double sz, double px) {
		if (Double.isNaN(px)) {
			return ".";
		}
		return sz+"@"+Utils.frc(px);
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+
				"{"+_ecn+" "+_instrId+" ["+
				   level(_bidSize0, _bid0)+" "+level(_bidSize1, _bid1)+" "+level(_bidSize2, _bid2)+" "+level(_bidSize3, _bid3)+" "+level(_bidSize4, _bid4)+"] ["+
				   level(_offerSize0, _offer0)+" "+level(_offerSize1, _offer1)+" "+level(_offerSize2, _offer2)+" "+level(_offerSize3, _offer3)+" "+level(_offerSize4, _offer4)+"] "+
				   Utils.format("HH:mm:ss.SSS", new Date(_ts))+" "+Utils.format("HH:mm:ss.SSS", new Date(_tsx))+" "+_stale+"}";
	}
}
