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
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.presto.obj.ObjImpl;
import net.a_cappella.presto.ps.QueuedMergeManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.*;

public class OrderObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(OrderObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ORDER; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ORDER; }

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
                    new FieldMetaInfo("ecn"),
                    new FieldMetaInfo("uid"),
                    new FieldMetaInfo("ordId"),
                    new FieldMetaInfo("instrId")
            ),
            Arrays.asList(
                    new FieldMetaInfo("reqType"),
                    new FieldMetaInfo("ver"),
                    new FieldMetaInfo("clOrdId"),
                    new FieldMetaInfo("ordType"),
                    new FieldMetaInfo("timeInForce"),
                    new FieldMetaInfo("side"),
                    new FieldMetaInfo("price"),
                    new FieldMetaInfo("orderQty"),
                    new FieldMetaInfo("shownQty"),
                    new FieldMetaInfo("randomMax"),
                    new FieldMetaInfo("useNative"),
                    new FieldMetaInfo("status"),
                    new FieldMetaInfo("ecnOrdId"),
                    new FieldMetaInfo("fillId"),
                    new FieldMetaInfo("execId"),
                    new FieldMetaInfo("lastQty"),
                    new FieldMetaInfo("lastPx"),
                    new FieldMetaInfo("leavesQty"),
                    new FieldMetaInfo("cumQty"),
                    new FieldMetaInfo("avgPx"),
                    new FieldMetaInfo("text"),
                    new FieldMetaInfo("ftDone"),
                    new FieldMetaInfo("done"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP),
                    new FieldMetaInfo("tsx", FieldType.TIMESTAMP)
            ),
            512);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    // meta
    private MadrigalMode _mode; // {REQUEST,RESPONSE}
    private MadrigalReqType _reqType; // {ADD,DEL,RWT}

	// invariants
	private String _ecn;
    private String _ordId;
    private String _uid;
    private String _ecnUid;
    private String _instrId;
    private String _ecnInstrId;
    private MadrigalOrdType _ordType = MadrigalOrdType.NULL_VAL; // {LIMIT, MARKET}
    private MadrigalTimeInForce _timeInForce = MadrigalTimeInForce.NULL_VAL; // {DAY, IOC, AtOpen, AtClose}
    private MadrigalSide _side = MadrigalSide.NULL_VAL; // {Buy, Sell}

	// ids
    private int _ver;
    private String _clOrdId;

    // requestGoal
    private double _price;
    private double _orderQty;
    private double _shownQty;
    private int _randomMax;

    // response fields
    private MadrigalOrdStatus _status = MadrigalOrdStatus.NULL_VAL; // {ACK, NAK, FILL, DONE, CXL}
	private String _ecnOrdId;
    private String _fillId;
    private long _execId;
    private String _text;
    private boolean _ftDone;
    private boolean _done;
    private long _ts;
    private long _tsx;
    private double _lastQty;
    private double _lastPx = Double.NaN;

    // cumulative
    private double _leavesQty;
    private double _cumQty;
    private double _avgPx;

    // useNative=true => use the native order strategy
    //   * more efficient for supported functionality
    //   * if order is iceberg and iceberg is not supported natively by the exchange then the result is exchange dependent
    //       (a) order can be rejected
    //       (b) order can be accepted but shown the entire size
    // useNative=false => use the simulated order strategy
    //   * during the life of the order I will need to use functionality not supported natively, e.g.
    //       (a) optimized rwt
    //       (b) iceberg
    //       (c) randomized iceberg
    private boolean _useNative;

    public OrderObj() {
		super();
	}

    public OrderObj(OrderObj other) {
    	super();
    	set(other);
    }

    public void set(OrderObj other) {
    	// meta
		_mode = other._mode;
		_reqType = other._reqType;

		// invariants
        _ecn = other._ecn;
		_uid = other._uid;
		_ecnUid = other._ecnUid;
		_instrId = other._instrId;
		_ecnInstrId = other._ecnInstrId;
		_ordType = other._ordType;
		_timeInForce = other._timeInForce;
		_side = other._side;

        // ids
		_ordId = other._ordId;
		_ver = other._ver;
		_clOrdId = other._clOrdId;

        // requestGoal
		_price = other._price;
		_orderQty = other._orderQty;
		_shownQty = other._shownQty;
		_randomMax = other._randomMax;

        // response fields
		_ecnOrdId = other._ecnOrdId;
		_fillId = other._fillId;
		_execId = other._execId;
		_status = other._status;
		_text = other._text;
		_ftDone = other._ftDone;
		_done = other._done;
		_ts = other._ts;
		_tsx = other._tsx;
		_lastQty = other._lastQty;
		_lastPx = other._lastPx;

        // cumulative
        _leavesQty = other._leavesQty;
		_cumQty = other._cumQty;
        _avgPx = other._avgPx;

		// misc
		_useNative = other._useNative;
    }

    @Override // IPoolable
	public void reset() {
		super.reset();

    	// meta
		_mode = null;
		_reqType = null;

		// invariants
		_ecn = null;
		_uid = null;
		_ecnUid = null;
		_instrId = null;
		_ecnInstrId = null;
		_ordType = MadrigalOrdType.NULL_VAL;
		_timeInForce = MadrigalTimeInForce.NULL_VAL;
		_side = MadrigalSide.NULL_VAL;

		// ids
		_ordId = null;
		_ver = 0;
		_clOrdId = null;

		// requestGoal
		_price = Double.NaN;
		_orderQty = Double.NaN;
		_shownQty = Double.NaN;
		_randomMax = 0;

		// response fields
		_ecnOrdId = null;
		_fillId = null;
		_execId = 0L;
		_status = MadrigalOrdStatus.NULL_VAL;
		_text = null;
		_ftDone = false;
		_done = false;
		_ts = 0;
		_tsx = 0;
		_lastQty = 0.0;
		_lastPx = Double.NaN;

        // cumulative
		_leavesQty = Double.NaN;
		_cumQty = 0.0;
		_avgPx = 0.0;

		// misc
		_useNative = false;
	}

	public void setAddRequest(String ecn, String uid, String ordId, int ver, String clOrdId, String instrId, MadrigalOrdType ordType, MadrigalTimeInForce timeInForce, MadrigalSide side, double price, double orderQty, double shownQty, int randomMax) {
    	// meta
		_mode = REQUEST;
		_reqType = ADD;

		// invariants
		_ecn = ecn;
        _ordId = ordId;
        _uid = uid;
		_ecnUid = null;
        _instrId = instrId;
		_ecnInstrId = null;
		_ordType = ordType;
        _timeInForce = timeInForce;
        _side = side;

        // ids
        _ver = ver;
        _clOrdId = clOrdId;

        // requestGoal
        _price = price;
        _orderQty = orderQty;
        _shownQty = shownQty;
        _randomMax = randomMax;

        // response fields
        _ts = System.currentTimeMillis();
		_tsx = 0;
	}

	public void setRwtRequest(int ver, String clOrdId, double price, double orderQty, double shownQty, int randomMax) {
    	// meta
		_mode = REQUEST;
		_reqType = RWT;

    	// ids
        _ver = ver;
        _clOrdId = clOrdId;

        // requestGoal
        _price = price;
        _orderQty = orderQty;
        _shownQty = shownQty;
        _randomMax = randomMax;

        // response fields
        _ts = System.currentTimeMillis();
		_tsx = 0;
	}

	public void setDelRequest(int ver, String clOrdId) {
    	// meta
		_mode = REQUEST;
		_reqType = DEL;

    	// ids
        _ver = ver;
        _clOrdId = clOrdId;

        // response fields
        _ts = System.currentTimeMillis();
		_tsx = 0;
	}

	public void setResponse(MadrigalReqType reqType,
			String ecn, String fillId, String ecnOrdId, String ordId, int ver, String clOrdId,
			MadrigalOrdStatus status, double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx,
			String text, boolean done, long tsx) {
		// meta
		_mode = RESPONSE;
		_reqType = reqType;

		// invariants
        _ecn = ecn;

        // ids
        _ordId = ordId;
        _ver = ver;
        _clOrdId = clOrdId;

        // response fields
        _fillId = fillId;
        _ecnOrdId = ecnOrdId;
        _status = status;
        _text = text;
        _ftDone = false;
        _done = done;
        _ts = System.currentTimeMillis();
        _tsx = tsx;
        _lastQty = lastQty;
        _lastPx = lastPx;

        // cumulative
        _leavesQty = leavesQty;
        _cumQty = cumQty;
        _avgPx = avgPx;
	}

	public void setMeta(MadrigalMode madMsgType, MadrigalReqType reqType) {
		_mode = madMsgType;
		_reqType = reqType;
	}

	public void copyInvariants(OrderObj other) {
		_ecn = other._ecn;
	    _ordId = other._ordId;
		_uid = other._uid;
		_ecnUid = other._ecnUid;
		_instrId = other._instrId;
		_ecnInstrId = other._ecnInstrId;
		_ordType = other._ordType;
		_timeInForce = other._timeInForce;
		_side = other._side;
	}
	public void setIds(String ordId) {
		_ordId = ordId;
		_ver = -1;
	}
	public void setIds(int ver) {
		_ver = ver;
		_clOrdId = _ordId+"-"+_ver;
	}
	public void copyIds(OrderObj order) {
		_ver = order._ver;
		_clOrdId = order._clOrdId;
	}
	public void copyRequestGoal(OrderObj req) {
		_price = req._price;
		_orderQty = req._orderQty;
		_shownQty = req._shownQty;
		_randomMax = req._randomMax;
	}
    public void copyResponseDetails(OrderObj response) {
    	_fillId = response._fillId;
        _ecnOrdId = response._ecnOrdId;
		_ts = response._ts;
		_tsx = response._tsx;
    }
    public void updateFillDetails(OrderObj response) {
		_lastQty = response._lastQty;
		if (_lastQty>0) {
	        _lastPx = response._lastPx;

	        _avgPx = (_avgPx*_cumQty + _lastQty*_lastPx) / (_cumQty+_lastQty);
			_leavesQty -= _lastQty;
			_cumQty += _lastQty;
		} else {
	        _lastPx = Double.NaN;
		}
    }
	public void resetLast() {
        _lastQty = 0.0;
        _lastPx = Double.NaN;
	}
	public void setLast(OrderObj response) {
        _lastQty = response._lastQty;
        _lastPx = response._lastPx;
	}
	public void resetCumulatives() {
        _cumQty = 0.0;
        _avgPx = 0.0;
        _leavesQty = _orderQty;
	}
	public void copyCumulatives(OrderObj order) {
        _cumQty = order._cumQty;
        _avgPx = order._avgPx;
        _leavesQty = order._leavesQty;
	}
	public void updateCumulatives(OrderObj order) {
        _cumQty = order._cumQty;
        _avgPx = order._avgPx;
        _leavesQty = _orderQty - _cumQty;
	}
	public void updateCumulatives() {
        _leavesQty = _orderQty - _cumQty;
	}
	public boolean isIceberg() {
		return _orderQty > _shownQty;
	}



    public MadrigalMode getMadrigalMode() {
        return _mode;
    }
    public void setMadrigalMode(MadrigalMode madMsgType) {
        _mode = madMsgType;
    }
    public MadrigalReqType getReqType() {
        return _reqType;
    }
    public void setReqType(MadrigalReqType reqType) {
        _reqType = reqType;
    }
    public String getEcn() {
        return _ecn;
    }
    public void setEcn(String ecn) {
        _ecn = ecn;
    }
    public String getUid() {
        return _uid;
    }
    public void setUid(String uid) {
        _uid = uid;
    }
    public String getEcnUid() {
    	return _ecnUid;
    }
    public void setEcnUid(String ecnUid) {
    	_ecnUid = ecnUid;
    }
    public String getOrdId() {
        return _ordId;
    }
    public void setOrdId(String ordId) {
        _ordId = ordId;
    }
    public int getVer() {
    	return _ver;
    }
    public void setVer(int ver) {
    	_ver = ver;
    }
    public String getClOrdId() {
        return _clOrdId;
    }
    public void setClOrdId(String clOrdId) {
        _clOrdId = clOrdId;
    }
    public String getFillId() {
        return _fillId;
    }
    public void setFillId(String fillId) {
        _fillId = fillId;
    }
    public long getExecId() {
        return _execId;
    }
    public void setExecId(long execId) {
        _execId = execId;
    }
    public String getEcnOrdId() {
        return _ecnOrdId;
    }
    public void setEcnOrdId(String ecnOrdId) {
        _ecnOrdId = ecnOrdId;
    }
    public String getInstrId() {
    	return _instrId;
    }
    public void setInstrId(String instrId) {
    	_instrId = instrId;
    }
    public String getEcnInstrId() {
    	return _ecnInstrId;
    }
    public void setEcnInstrId(String ecnInstrId) {
    	_ecnInstrId = ecnInstrId;
    }
    public MadrigalOrdType getOrdType() {
        return _ordType;
    }
    public void setOrdType(MadrigalOrdType ordType) {
        _ordType = ordType;
    }
    public MadrigalTimeInForce getTimeInForce() {
        return _timeInForce;
    }
    public void setTimeInForce(MadrigalTimeInForce timeInForce) {
        _timeInForce = timeInForce;
    }
    public MadrigalSide getSide() {
        return _side;
    }
    public void setSide(MadrigalSide side) {
        _side = side;
    }
    public double getPrice() {
    	return _price;
    }
    public void setPrice(double price) {
    	_price = price;
    }
    public double getOrderQty() {
        return _orderQty;
    }
    public void setOrderQty(double orderQty) {
        _orderQty = orderQty;
    }
    public double getShownQty() {
    	return _shownQty;
    }
    public void setShownQty(double shownQty) {
    	_shownQty = shownQty;
    }
    public int getRandomMax() {
    	return _randomMax;
    }
    public void setRandomMax(int randomMax) {
    	_randomMax = randomMax;
    }
    public MadrigalOrdStatus getStatus() {
        return _status;
    }
    public void setStatus(MadrigalOrdStatus status) {
        _status = status;
    }
    public double getLastQty() {
    	return _lastQty;
    }
    public void setLastQty(double lastQty) {
    	_lastQty = lastQty;
    }
    public double getLastPx() {
    	return _lastPx;
    }
    public void setLastPx(double lastPx) {
    	_lastPx = lastPx;
    }
    public double getLeavesQty() {
    	return _leavesQty;
    }
    public void setLeavesQty(double leavesQty) {
    	_leavesQty = leavesQty;
    }
    public double getCumQty() {
    	return _cumQty;
    }
    public void setCumQty(double cumQty) {
    	_cumQty = cumQty;
    }
    public double getAvgPx() {
    	return _avgPx;
    }
    public void setAvgPx(double avgPx) {
    	_avgPx = avgPx;
    }
    public String getText() {
        return _text;
    }
    public void setText(String text) {
        _text = text;
    }
    public boolean isFtDone() {
    	return _ftDone;
    }
    public void setFtDone(boolean ftDone) {
    	_ftDone = ftDone;
    }
    public boolean isDone() {
    	return _done;
    }
    public void setDone(boolean done) {
    	_done = done;
    }
    public void updateDone(boolean done) {
    	_done |= done;
    }
    public boolean isUseNative() {
    	return _useNative;
    }
    public void setUseNative(boolean useNative) {
    	_useNative = useNative;
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
	public 	IMergeManager newMergeManager() {
		return new QueuedMergeManager(new OrderSnapHighWaterMark());
	}




    @Override
	public String getString(String fieldName) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		if ("uid".equalsIgnoreCase(fieldName)) return _uid;
		if ("ordId".equalsIgnoreCase(fieldName)) return _ordId;
		if ("clOrdId".equalsIgnoreCase(fieldName)) return _clOrdId;
		if ("fillId".equalsIgnoreCase(fieldName)) return _fillId;
		if ("ecnOrdId".equalsIgnoreCase(fieldName)) return _ecnOrdId;
		if ("instrId".equalsIgnoreCase(fieldName)) return _instrId;
		if ("text".equalsIgnoreCase(fieldName)) return _text;
		return super.getString(fieldName); // throws exception
	}

	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		else if ("uid".equalsIgnoreCase(fieldName)) _uid = value;
		else if ("ordId".equalsIgnoreCase(fieldName)) _ordId = value;
		else if ("clOrdId".equalsIgnoreCase(fieldName)) _clOrdId = value;
		else if ("fillId".equalsIgnoreCase(fieldName)) _fillId = value;
		else if ("ecnOrdId".equalsIgnoreCase(fieldName)) _ecnOrdId = value;
		else if ("instrId".equalsIgnoreCase(fieldName)) _instrId = value;
		else if ("text".equalsIgnoreCase(fieldName)) _text = value;
		else super.setString(fieldName, value); // throws exception
	}

	@Override
	public int getInt(String fieldName) throws Exception {
		if ("randomMax".equalsIgnoreCase(fieldName)) return _randomMax;
		if ("ver".equalsIgnoreCase(fieldName)) return _ver;
		return super.getInt(fieldName); // throws exception
	}
	@Override
	public void setInt(String fieldName, int value) throws Exception {
		if ("randomMax".equalsIgnoreCase(fieldName)) _randomMax = value;
		else if ("ver".equalsIgnoreCase(fieldName)) _ver = value;
		else super.setInt(fieldName, value); // throws exception
	}

	@Override
	public long getLong(String fieldName) throws Exception {
		if ("execId".equalsIgnoreCase(fieldName)) return _execId;
		return super.getLong(fieldName); // throws exception
	}
	@Override
	public void setLong(String fieldName, long value) throws Exception {
		if ("execId".equalsIgnoreCase(fieldName)) _execId = value;
		else super.setLong(fieldName, value); // throws exception
	}

	@Override
	public double getDouble(String fieldName) throws Exception {
		if ("price".equalsIgnoreCase(fieldName)) return _price;
		if ("orderQty".equalsIgnoreCase(fieldName)) return _orderQty;
		if ("shownQty".equalsIgnoreCase(fieldName)) return _shownQty;
		if ("lastQty".equalsIgnoreCase(fieldName)) return _lastQty;
		if ("lastPx".equalsIgnoreCase(fieldName)) return _lastPx;
		if ("leavesQty".equalsIgnoreCase(fieldName)) return _leavesQty;
		if ("cumQty".equalsIgnoreCase(fieldName)) return _cumQty;
		if ("avgPx".equalsIgnoreCase(fieldName)) return _avgPx;
		return super.getDouble(fieldName); // throws exception
	}
	@Override
	public void setDouble(String fieldName, double value) throws Exception {
		if ("price".equalsIgnoreCase(fieldName)) _price = value;
		else if ("orderQty".equalsIgnoreCase(fieldName)) _orderQty = value;
		else if ("shownQty".equalsIgnoreCase(fieldName)) _shownQty = value;
		else if ("lastQty".equalsIgnoreCase(fieldName)) _lastQty = value;
		else if ("lastPx".equalsIgnoreCase(fieldName)) _lastPx = value;
		else if ("leavesQty".equalsIgnoreCase(fieldName)) _leavesQty = value;
		else if ("cumQty".equalsIgnoreCase(fieldName)) _cumQty = value;
		else if ("avgPx".equalsIgnoreCase(fieldName)) _avgPx = value;
		else super.setDouble(fieldName, value); // throws exception
	}

	@Override
	public boolean getBoolean(String fieldName) throws Exception {
		if ("ftDone".equalsIgnoreCase(fieldName)) return _ftDone;
		if ("done".equalsIgnoreCase(fieldName)) return _done;
		if ("useNative".equalsIgnoreCase(fieldName)) return _useNative;
		return super.getBoolean(fieldName); // throws exception
	}
	@Override
	public void setBoolean(String fieldName, boolean value) throws Exception {
		if ("ftDone".equalsIgnoreCase(fieldName)) _ftDone = value;
		else if ("done".equalsIgnoreCase(fieldName)) _done = value;
		else if ("useNative".equalsIgnoreCase(fieldName)) _useNative = value;
		else super.setBoolean(fieldName, value); // throws exception
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

	@Override
	public Enum<?> getEnum(String fieldName) throws Exception {
		if ("mode".equalsIgnoreCase(fieldName)) return _mode;
		if ("reqType".equalsIgnoreCase(fieldName)) return _reqType;
		if ("status".equalsIgnoreCase(fieldName)) return _status;
		if ("ordType".equalsIgnoreCase(fieldName)) return _ordType;
		if ("timeInForce".equalsIgnoreCase(fieldName)) return _timeInForce;
		if ("side".equalsIgnoreCase(fieldName)) return _side;
		return super.getEnum(fieldName); // throws exception
	}

	public void setEnum(String fieldName, Enum<?> value) throws Exception {
		if ("mode".equalsIgnoreCase(fieldName)) _mode = (MadrigalMode) value;
		else if ("reqType".equalsIgnoreCase(fieldName)) _reqType = (MadrigalReqType) value;
		else if ("status".equalsIgnoreCase(fieldName)) _status = (MadrigalOrdStatus) value;
		else if ("ordType".equalsIgnoreCase(fieldName)) _ordType = (MadrigalOrdType) value;
		else if ("timeInForce".equalsIgnoreCase(fieldName)) _timeInForce = (MadrigalTimeInForce) value;
		else if ("side".equalsIgnoreCase(fieldName)) _side = (MadrigalSide) value;
		else super.setEnum(fieldName, value); // throws exception
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+
				getSeqNo() + "::: "+
				_reqType+" "+_mode+" "+((REQUEST==_mode)?"":(_status+" "))+
				_ecn+" "+_uid+"/"+_ecnUid+" "+_ordId+"-"+_ver+"/"+_clOrdId+"=>"+_ecnOrdId+"/"+_fillId+"/"+_execId+" "+
				_instrId+"/"+_ecnInstrId+" "+
				_ordType+" "+_timeInForce+" "+_side+" "+_orderQty+"/"+_shownQty+"/"+_randomMax+"@"+_price+" "+
				((REQUEST==_mode)?(_useNative):
					(_lastQty+"@"+_lastPx+"/"+_leavesQty+"/"+_cumQty+"@"+_avgPx+" "+_text+" "+_ftDone+" "+_done))+" "+
				Utils.formatMillis(_ts)+" "+Utils.formatMillis(_tsx)+
				"}";
	}
}
