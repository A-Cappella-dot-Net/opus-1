package net.a_cappella.madrigal.common.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalOrderBook;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class EcnImbalanceObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(EcnImbalanceObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_IMBALANCE; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_IMBALANCE; }

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
                    new FieldMetaInfo("securityID"),
                    new FieldMetaInfo("book")
            ),
            Arrays.asList(
                    new FieldMetaInfo("auction"),
                    new FieldMetaInfo("side"),
                    new FieldMetaInfo("matched"),
                    new FieldMetaInfo("surplus"),
                    new FieldMetaInfo("price"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            128);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _ecn;
	private long _ts;

    private String _securityID;
    private MadrigalOrderBook _book;
    private boolean _auction;
    private MadrigalSide _side;
    private double _matched;
    private double _surplus;
    private double _price;

	@Override // IPoolable
	public void reset() {
		super.reset();
		_ecn = null;
		_ts = 0;
		_securityID = null;
		_book = null;
		_auction = false;
		_side = null;
		_matched = Double.NaN;
		_surplus = Double.NaN;
		_price = Double.NaN;
	}

	public void set(String ecn, long ts, String securityID, MadrigalOrderBook book, boolean auction, MadrigalSide side, double matched, double surplus, double price) {
        _ecn = ecn;
        _ts = ts;
		_securityID = securityID;
		_book = book;
		_auction = auction;
		_side = side;
		_matched = matched;
		_surplus = surplus;
		_price = price;
	}

    public String getEcn() {
		return _ecn;
	}
	public void setEcn(String ecn) {
		_ecn = ecn;
	}
	public long getTs() {
		return _ts;
	}
	public void setTs(long ts) {
		_ts = ts;
	}

	public String getSecurityID() {
		return _securityID;
	}
	public void setSecurityID(String securityID) {
		_securityID = securityID;
	}

	public MadrigalOrderBook getBook() {
		return _book;
	}
	public void setBook(MadrigalOrderBook book) {
		_book = book;
	}

	public boolean isAuction() {
		return _auction;
	}
	public void setAuction(boolean auction) {
		_auction = auction;
	}

	public MadrigalSide getSide() {
		return _side;
	}
	public void setSide(MadrigalSide side) {
		_side = side;
	}

	public double getMatched() {
		return _matched;
	}
	public void setMatched(double matched) {
		_matched = matched;
	}

	public double getSurplus() {
		return _surplus;
	}
	public void setSurplus(double surplus) {
		_surplus = surplus;
	}

	public double getPrice() {
		return _price;
	}
	public void setPrice(double price) {
		_price = price;
	}

	@Override
	public double getDouble(String fieldName) throws Exception {
		if ("matched".equalsIgnoreCase(fieldName)) return _matched;
		if ("surplus".equalsIgnoreCase(fieldName)) return _surplus;
		if ("price".equalsIgnoreCase(fieldName)) return _price;
		return super.getDouble(fieldName); // throws exception
	}
	@Override
	public void setDouble(String fieldName, double value) throws Exception {
		if ("matched".equalsIgnoreCase(fieldName)) _matched = value;
		else if ("surplus".equalsIgnoreCase(fieldName)) _surplus = value;
		else if ("price".equalsIgnoreCase(fieldName)) _price = value;
		else super.setDouble(fieldName, value); // throws exception
	}

	@Override
	public boolean getBoolean(String fieldName) throws Exception {
		if ("auction".equalsIgnoreCase(fieldName)) return _auction;
		return super.getBoolean(fieldName); // throws exception
	}
	@Override
	public void setBoolean(String fieldName, boolean value) throws Exception {
		if ("auction".equalsIgnoreCase(fieldName)) _auction = value;
		else super.setBoolean(fieldName, value); // throws exception
	}

	@Override
	public String getString(String fieldName) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) return _securityID;
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		return super.getString(fieldName); // throws exception
	}
	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) _securityID = value;
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

	@Override
	public Enum<?> getEnum(String fieldName) throws Exception {
		if ("book".equalsIgnoreCase(fieldName)) return _book;
		if ("side".equalsIgnoreCase(fieldName)) return _side;
		return super.getEnum(fieldName); // throws exception
	}
	public void setEnum(String fieldName, Enum<?> value) throws Exception {
		if ("book".equalsIgnoreCase(fieldName)) _book = (MadrigalOrderBook) value;
		else if ("side".equalsIgnoreCase(fieldName)) _side = (MadrigalSide) value;
		else super.setEnum(fieldName, value); // throws exception
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+
				"{"+_ecn+" "+_securityID+" "+_book+" "+_auction+" "+_side+" "+_matched+" "+_surplus+" "+_price+" "+Utils.formatMillis(_ts)+"}";
	}
}
