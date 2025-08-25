package net.a_cappella.madrigal.cukes.adaptors;

import io.cucumber.java.DataTableType;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.ICredentialsCache;
import net.a_cappella.madrigal.IInstrumentCache;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.Map;

import static com.google.common.base.Strings.nullToEmpty;
import static net.a_cappella.madrigal.CukeUtils.*;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.*;

public class CukeOrder {
    private static final Logger log = LoggerFactory.getLogger(CukeOrder.class);

    private MadrigalMode mode; // {REQUEST,RESPONSE}
    private MadrigalReqType reqType; // {ADD,DEL,RWT}

	// invariants
	private String ecn;
    private String ordId;
    private String uid;
    private String ecnUid;
    private String instrId;
    private String ecnInstrId;
    private MadrigalOrdType ordType;
    private MadrigalTimeInForce timeInForce;
    private MadrigalSide side;

	// ids
    private int ver;
    private String clOrdId;

    // requestGoal
    private double price;
    private double qty;
    private double shownQty;
    private int randomMax;

    // er fields
	private String fillId;
	private long execId;
	private String ecnOrdId;
    private MadrigalOrdStatus status;
    private String text;
    private boolean ftDone;
    private boolean done;
    private long ts;
    private long tsx;
    private double lastQty;
    private double lastPx = Double.NaN;

    // cumulative
    private double leavesQty;
    private double cumQty;
    private double avgPx;
    private boolean useNative;

    public CukeOrder() {

    }

	@DataTableType
	public static CukeOrder dttCukeOrder(Map<String, String> entry) {
		CukeOrder co = new CukeOrder();
		co.mode = parseMadrigalMode(entry.get("mode")); // {REQUEST,RESPONSE}
		co.reqType = MadrigalReqType.valueOf(entry.get("reqType")); // {ADD,DEL,RWT}

		// invariants
		co.ecn = entry.get("ecn");
		co.ordId = entry.get("ordId");
		co.uid = entry.get("uid");
		co.ecnUid = entry.get("ecnUid");
		co.instrId = entry.get("instrId");
		co.ecnInstrId = entry.get("ecnInstrId");
		co.ordType = parseMadrigalOrdType(entry.get("ordType"));
		co.timeInForce = parseMadrigalTimeInForce(entry.get("timeInForce"));
		co.side = parseMadrigalSide(entry.get("side"));

		// ids
		co.ver = parseVer(entry.get("ver"));
		co.clOrdId = entry.get("clOrdId");

		// requestGoal
		co.price = parseDoubleNaN(entry.get("price"));
		co.qty = parseDouble(entry.get("qty"));
		co.shownQty = parseDouble(entry.get("shownQty"));
		co.randomMax = parseInt(entry.get("randomMax"));

		// er fields
		co.fillId = nullToEmpty(entry.get("fillId"));
		co.execId = parseLong(entry.get("execId"));
		co.ecnOrdId = nullToEmpty(entry.get("ecnOrdId"));
		co.status = parseMadrigalOrdStatus(entry.get("status"));
		co.text = nullToEmpty(entry.get("text"));
		co.ftDone = Boolean.parseBoolean(entry.get("ftDone"));
		co.done = Boolean.parseBoolean(entry.get("done"));
		co.ts = parseLong(entry.get("ts"));
		co.tsx = parseLong(entry.get("tsx"));
		co.lastQty = parseDouble(entry.get("lastQty"));
		co.lastPx = parseDoubleNaN(entry.get("lastPx"));

		// cumulative
		co.leavesQty = parseDouble(entry.get("leavesQty"));
		co.cumQty = parseDouble(entry.get("cumQty"));
		co.avgPx = parseDoubleNaN(entry.get("avgPx"));
		co.useNative = Boolean.parseBoolean(entry.get("useNative"));

		return co;
	}

	private CukeOrder(
            MadrigalMode mode, // {REQUEST,RESPONSE}
            MadrigalReqType reqType, // {ADD,DEL,RWT}

            // invariants
            String ecn,
            String ordId,
            String uid,
            String ecnUid,
            String instrId,
            String ecnInstrId,
            MadrigalOrdType ordType,
            MadrigalTimeInForce timeInForce,
            MadrigalSide side,

            // ids
            int ver,
            String clOrdId,

            // requestGoal
            double price,
            double qty,
            double shownQty,
            int randomMax,

            // er fields
            String fillId,
            long execId,
            String ecnOrdId,
            MadrigalOrdStatus status,
            String text,
            boolean ftDone,
            boolean done,
            long ts,
            long tsx,
            double lastQty,
            double lastPx,

            // cumulative
            double leavesQty,
            double cumQty,
            double avgPx,
            boolean useNative
    ) {
        this.mode = mode; // {REQUEST,RESPONSE}
        this.reqType = reqType; // {ADD,DEL,RWT}

        // invariants
        this.ecn = ecn;
        this.ordId = ordId;
        this.uid = uid;
        this.ecnUid = ecnUid;
        this.instrId = instrId;
        this.ecnInstrId = ecnInstrId;
        this.ordType = ordType;
        this.timeInForce = timeInForce;
        this.side = side;

        // ids
        this.ver = ver;
        this.clOrdId = clOrdId;

        // requestGoal
        this.price = price;
        this.qty = qty;
        this.shownQty = shownQty;
        this.randomMax = randomMax;

        // er fields
        this.fillId = fillId;
        this.execId = execId;
        this.ecnOrdId = ecnOrdId;
        this.status = status;
        this.text = text;
        this.ftDone = ftDone;
        this.done = done;
        this.ts = ts;
        this.tsx = tsx;
        this.lastQty = lastQty;
        this.lastPx = lastPx;

        // cumulative
        this.leavesQty = leavesQty;
        this.cumQty = cumQty;
        this.avgPx = avgPx;
        this.useNative = useNative;
    }

    public MadrigalMode getMadMsgType() {
		return mode;
	}
	public MadrigalReqType getReqType() {
		return reqType;
	}
	public String getEcn() {
		return ecn;
	}
	public String getOrdId() {
		return ordId;
	}
	public String getUid() {
		return uid;
	}
	public String getEcnUid() {
		return ecnUid;
	}
	public String getInstrId() {
		return instrId;
	}
	public String getEcnInstrId() {
		return ecnInstrId;
	}
	public MadrigalOrdType getOrdType() {
		return ordType;
	}
	public MadrigalTimeInForce getTimeInForce() {
		return timeInForce;
	}
	public MadrigalSide getSide() {
		return side;
	}
	public long getVer() {
		return ver;
	}
	public String getClOrdId() {
		return clOrdId;
	}
	public double getPrice() {
		return price;
	}
	public double getQty() {
		return qty;
	}
	public double getShownQty() {
		return shownQty;
	}
	public int getRandomMax() {
		return randomMax;
	}
	public String getFillId() {
		return fillId;
	}
	public long getExecId() {
		return execId;
	}
	public String getEcnOrdId() {
		return ecnOrdId;
	}
	public MadrigalOrdStatus getStatus() {
		return status;
	}
	public String getText() {
		return text;
	}
	public boolean isFtDone() {
		return ftDone;
	}
	public boolean isDone() {
		return done;
	}
	public long getTs() {
		return ts;
	}
	public long getTsx() {
		return tsx;
	}
	public double getLastQty() {
		return lastQty;
	}
	public double getLastPx() {
		return lastPx;
	}
	public double getLeavesQty() {
		return leavesQty;
	}
	public double getCumQty() {
		return cumQty;
	}
	public double getAvgPx() {
		return avgPx;
	}
	public boolean isUseNative() {
		return useNative;
	}

	public CukeOrder defaults() {
		ecn = (ecn==null) ? "ecn" : ecn;
		uid = (uid==null) ? "uid" : uid;
		instrId = (instrId==null) ? "instrId" : instrId;
		return this;
	}

	public CukeOrder defaults(MadrigalMode mode) {
		this.mode = mode;
		clOrdId = ordId+"-"+ver;

		defaults();
		ecnUid = (ecnUid==null) ? "ecnUid" : ecnUid;
		ecnInstrId = (ecnInstrId==null) ? "ecnInstrId" : ecnInstrId;
		return this;
	}

	public CukeOrder ecnDefaults() {
		ecn = (ecn==null) ? "ecn" : ecn;
		uid = (uid==null) ? "uid" : uid;
		instrId = (instrId==null) ? "instrId" : instrId;
		ecnUid = (ecnUid==null) ? "ecnUid" : ecnUid;
		ecnInstrId = (ecnInstrId==null) ? "ecnInstrId" : ecnInstrId;
		return this;
	}

	public OrderObj adaptResponse() {
		OrderObj resp = new OrderObj();
		String[] comps = clOrdId.split("-");
		ordId = comps[0];
		ver = Integer.parseInt(comps[1]);
		resp.setResponse(
				reqType,
				ecn,
				fillId,
				ecnOrdId,
				ordId, ver, clOrdId,
				status,
				lastQty, lastPx, leavesQty, cumQty, avgPx,
				text, done, System.currentTimeMillis());
		resp.setExecId(execId);
        return resp;
	}

	public OrderObj adaptUnprocessedFill() {
		OrderObj resp = new OrderObj();
		String[] comps = clOrdId.split("-");
		ordId = comps[0];
		ver = Integer.parseInt(comps[1]);
		resp.setResponse(
				reqType,
				MadrigalConstants.LH_ECN_PREFIX + ecn,
				fillId,
				ecnOrdId,
				ordId, ver, clOrdId,
				status,
				lastQty, lastPx, leavesQty, cumQty, avgPx,
				text, done, System.currentTimeMillis());
		resp.setUid(uid);
		resp.setEcnUid(ecnUid);
		resp.setInstrId(instrId);
		resp.setEcnInstrId(ecnInstrId);
		resp.setExecId(execId);

		return resp;
	}

	public OrderObj adaptState(ICredentialsCache credentialsCache, IInstrumentCache instrumentCache) {
		OrderObj state = new OrderObj();
		clOrdId = ordId + "-" + ver;

		// request fields
		state.setUid(uid);
        state.setInstrId(instrId);
		state.setOrdType(ordType);
		state.setTimeInForce(timeInForce);
		state.setSide(side);
		state.setPrice(price);
		state.setOrderQty(qty);
		state.setShownQty(shownQty);
		state.setRandomMax(randomMax);
		state.setUseNative(useNative);
        state.setEcnUid(credentialsCache.getEcnCredentials(uid).getEcnUid());
        state.setEcnInstrId(instrumentCache.getEcnInstrId(instrId));

        // response fields
		state.setResponse(
				reqType,
				ecn,
				fillId,
				ecnOrdId,
				ordId, ver, clOrdId,
				status,
				lastQty, lastPx, leavesQty, cumQty, avgPx,
				text, done, System.currentTimeMillis());
		state.setExecId(execId);

        return state;
	}

	public OrderObj adaptRequest(Map<String, OrderObj> orderCache, ICredentialsCache credentialsCache, IInstrumentCache instrumentCache) {
		if (reqType == ADD) {
			if (orderCache.containsKey(ordId)) {
	            log.error("Ignoring duplicate order "+ordId+"...");
	            return null;
	    	}

        	OrderObj order = new OrderObj();
	        orderCache.put(ordId, order);
	        log.info("added "+ordId+" to cache...");

	    	String clOrdId = ordId + "-" + ver;
	        order.setAddRequest(ecn, uid, ordId, ver, clOrdId, instrId, ordType, timeInForce, side, price, qty, shownQty, randomMax);
	        order.setUseNative(useNative);

	        order.setEcnUid(credentialsCache.getEcnCredentials(uid).getEcnUid());
	        order.setEcnInstrId(instrumentCache.getEcnInstrId(instrId));

	        return order;
		} else if (reqType == DEL) {
	        OrderObj order = orderCache.get(ordId);
	        if (order == null) {
                log.info("ordId "+ordId+" not in cache...");
               	order = new OrderObj();
    	    	String clOrdId = ordId + "-" + ver;
    	        order.setAddRequest(ecn, uid, ordId, ver, clOrdId, instrId, ordType, timeInForce, side, price, qty, shownQty, randomMax);
    	        order.setUseNative(useNative);

    	        order.setEcnUid(credentialsCache.getEcnCredentials(uid).getEcnUid());
    	        order.setEcnInstrId(instrumentCache.getEcnInstrId(instrId));
    	        order.setReqType(DEL);
	        }
	        OrderObj newOrder = new OrderObj(order);
	        orderCache.put(ordId, newOrder);

	        String clOrdId = ordId + "-" + ver;
	    	newOrder.setDelRequest(ver, clOrdId);
	    	newOrder.setFillId(fillId);
	    	newOrder.setExecId(execId);
	    	newOrder.setEcnOrdId(ecnOrdId);

	    	return newOrder;
		} else if (reqType == RWT) {
	        OrderObj order = orderCache.get(ordId);
	        if (order == null) {
                log.info("ordId "+ordId+" not in cache...");
               	order = new OrderObj();
    	    	String clOrdId = ordId + "-" + ver;
    	        order.setAddRequest(ecn, uid, ordId, ver, clOrdId, instrId, ordType, timeInForce, side, price, qty, shownQty, randomMax);
    	        order.setUseNative(useNative);

    	        order.setEcnUid(credentialsCache.getEcnCredentials(uid).getEcnUid());
    	        order.setEcnInstrId(instrumentCache.getEcnInstrId(instrId));
    	    	order.setFillId(fillId);
    	    	order.setExecId(execId);
    	    	order.setEcnOrdId(ecnOrdId);
    	        order.setReqType(RWT);
	        }
	        OrderObj newOrder = new OrderObj(order);
	        orderCache.put(ordId, newOrder);

	        String clOrdId = ordId + "-" + ver;
	        newOrder.setRwtRequest(ver, clOrdId, price, qty, shownQty, 0);

	    	return newOrder;
		} else {
			return null;
		}
	}







	public static CukeOrder adapt(OrderObj order) {
		CukeOrder cukeOrder = new CukeOrder();
		
		cukeOrder.mode = order.getMadrigalMode();
		cukeOrder.reqType = order.getReqType();

		// invariants
		cukeOrder.ecn = order.getEcn();
		cukeOrder.ordId = order.getOrdId();
		cukeOrder.uid = order.getUid();
		cukeOrder.ecnUid = order.getEcnUid();
		cukeOrder.instrId = order.getInstrId();
		cukeOrder.ecnInstrId = order.getEcnInstrId();
		cukeOrder.ordType = order.getOrdType();
		cukeOrder.timeInForce = order.getTimeInForce();
		cukeOrder.side = order.getSide();

		// ids
		cukeOrder.ver = order.getVer();
		cukeOrder.clOrdId = order.getClOrdId();

	    // requestGoal
		cukeOrder.price = order.getPrice();
		cukeOrder.qty = order.getOrderQty();
		cukeOrder.shownQty = order.getShownQty();
		cukeOrder.randomMax = order.getRandomMax();

	    // er fields
		cukeOrder.fillId = emptyStringIfNull(order.getFillId());
		cukeOrder.execId = order.getExecId();
		cukeOrder.ecnOrdId = emptyStringIfNull(order.getEcnOrdId());
		cukeOrder.status = order.getStatus();
		cukeOrder.text = emptyStringIfNull(order.getText());
		cukeOrder.ftDone = order.isFtDone();
		cukeOrder.done = order.isDone();
		cukeOrder.ts = order.getTs();
		cukeOrder.tsx = order.getTsx();
		cukeOrder.lastQty = order.getLastQty();
		cukeOrder.lastPx = order.getLastPx();

	    // cumulative
		cukeOrder.leavesQty = order.getLeavesQty();
		cukeOrder.cumQty = order.getCumQty();
		cukeOrder.avgPx = order.getAvgPx();
		cukeOrder.useNative = (cukeOrder.mode==MadrigalMode.RESPONSE) ? false : order.isUseNative();

	    return cukeOrder;
	}

	private static String emptyStringIfNull(String str) {
		return (str==null) ? "" : str;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		long temp;
		result = prime * result + ((clOrdId == null) ? 0 : clOrdId.hashCode());
		result = prime * result + ((ecn == null) ? 0 : ecn.hashCode());
		result = prime * result
				+ ((ecnInstrId == null) ? 0 : ecnInstrId.hashCode());
		result = prime * result
				+ ((fillId == null) ? 0 : fillId.hashCode());
		result = prime * result + (int) (execId ^ (execId >>> 32));
		result = prime * result
				+ ((ecnOrdId == null) ? 0 : ecnOrdId.hashCode());
		result = prime * result
				+ ((ecnUid == null) ? 0 : ecnUid.hashCode());
		result = prime * result + ((instrId == null) ? 0 : instrId.hashCode());
		result = prime * result + ((ordId == null) ? 0 : ordId.hashCode());
		temp = Double.doubleToLongBits(qty);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(price);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + randomMax;
		result = prime * result + ((reqType == null) ? 0 : reqType.hashCode());
		temp = Double.doubleToLongBits(shownQty);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + ((side == null) ? 0 : side.hashCode());
		result = prime * result
				+ ((ordType == null) ? 0 : ordType.hashCode());
		result = prime * result
				+ ((timeInForce == null) ? 0 : timeInForce.hashCode());
		result = prime * result + ((uid == null) ? 0 : uid.hashCode());
		result = prime * result + (ver ^ (ver >>> 32));

		result = prime * result + ((mode == null) ? 0 : mode.hashCode());

		if (mode==REQUEST) {
			result = prime * result + (useNative ? 1231 : 1237);
		} else {
			result = prime * result + ((status == null) ? 0 : status.hashCode());
			temp = Double.doubleToLongBits(lastQty);
			result = prime * result + (int) (temp ^ (temp >>> 32));
			temp = Double.doubleToLongBits(lastPx);
			result = prime * result + (int) (temp ^ (temp >>> 32));
			temp = Double.doubleToLongBits(leavesQty);
			result = prime * result + (int) (temp ^ (temp >>> 32));
			temp = Double.doubleToLongBits(cumQty);
			result = prime * result + (int) (temp ^ (temp >>> 32));
			temp = Double.doubleToLongBits(avgPx);
			result = prime * result + (int) (temp ^ (temp >>> 32));
			result = prime * result + ((text == null) ? 0 : text.hashCode());
			result = prime * result + (ftDone ? 1231 : 1237);
			result = prime * result + (done ? 1231 : 1237);
		}

		return result;
	}
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		CukeOrder other = (CukeOrder) obj;
		if (clOrdId == null) {
			if (other.clOrdId != null)
				return false;
		} else if (!clOrdId.equals(other.clOrdId))
			return false;
		if (ecn == null) {
			if (other.ecn != null)
				return false;
		} else if (!ecn.equals(other.ecn))
			return false;
		if (ecnInstrId == null) {
			if (other.ecnInstrId != null)
				return false;
		} else if (!ecnInstrId.equals(other.ecnInstrId))
			return false;
		if (execId != other.execId)
			return false;
		if (fillId == null) {
			if (other.fillId != null)
				return false;
		} else if (!fillId.equals(other.fillId))
			return false;
		if (ecnOrdId == null) {
			if (other.ecnOrdId != null)
				return false;
		} else if (!ecnOrdId.equals(other.ecnOrdId))
			return false;
		if (ecnUid == null) {
			if (other.ecnUid != null)
				return false;
		} else if (!ecnUid.equals(other.ecnUid))
			return false;
		if (instrId == null) {
			if (other.instrId != null)
				return false;
		} else if (!instrId.equals(other.instrId))
			return false;
		if (ordId == null) {
			if (other.ordId != null)
				return false;
		} else if (!ordId.equals(other.ordId))
			return false;
		if (Double.doubleToLongBits(qty) != Double
				.doubleToLongBits(other.qty))
			return false;
		if (Double.doubleToLongBits(price) != Double
				.doubleToLongBits(other.price))
			return false;
		if (randomMax != other.randomMax)
			return false;
		if (reqType != other.reqType)
			return false;
		if (Double.doubleToLongBits(shownQty) != Double
				.doubleToLongBits(other.shownQty))
			return false;
		if (side != other.side)
			return false;
		if (ordType != other.ordType)
			return false;
		if (timeInForce != other.timeInForce)
			return false;
		if (uid == null) {
			if (other.uid != null)
				return false;
		} else if (!uid.equals(other.uid))
			return false;
		if (ver != other.ver)
			return false;

		if (mode != other.mode)
			return false;

		if (mode==REQUEST) {
			if (useNative != other.useNative)
				return false;
		} else {
			if (status != other.status)
				return false;
			if (Double.doubleToLongBits(lastQty) != Double
					.doubleToLongBits(other.lastQty))
				return false;
			if (Double.doubleToLongBits(lastPx) != Double
					.doubleToLongBits(other.lastPx))
				return false;
			if (Double.doubleToLongBits(leavesQty) != Double
					.doubleToLongBits(other.leavesQty))
				return false;
			if (Double.doubleToLongBits(cumQty) != Double
					.doubleToLongBits(other.cumQty))
				return false;
			if (Utils.cmp(avgPx, other.avgPx)!=0) return false;
			if (text == null) {
				if (other.text != null)
					return false;
			} else if (!text.equals(other.text))
				return false;
			if (ftDone != other.ftDone)
				return false;
			if (done != other.done)
				return false;
		}

		return true;
	}
	public String toString() {
		return "{"+
				reqType+" "+((REQUEST==mode)?(useNative):(status+" "))+
				ecn+" "+uid+"/"+ecnUid+" "+ordId+"-"+ver+"/"+clOrdId+"/"+ecnOrdId+"/"+fillId+"/"+execId+" "+
				instrId+"/"+ecnInstrId+" "+
				ordType+" "+timeInForce+" "+side+" "+price+" "+qty+"/"+shownQty+"/"+randomMax+" "+
				((REQUEST==mode)?(useNative):
					(lastQty+"@"+lastPx+"/"+leavesQty+"/"+cumQty+"@"+avgPx+" "+text+" "+ftDone+" "+done))+" "+
				Utils.format("yy-MM-dd HH:mm:ss.SSS", new Date(ts))+" "+Utils.format("yy-MM-dd HH:mm:ss.SSS", new Date(tsx))+
				"}";
	}
}
