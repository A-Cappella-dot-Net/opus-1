package net.a_cappella.madrigal.om;

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.FinalizeOrderObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.common.utils.StringDelayer;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.structs.of.poolables.MapOfPoolable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.FILL;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.*;

public abstract class OrderManagerClient {
    private static final Logger log = LoggerFactory.getLogger(OrderManagerClient.class);

    private final PrestoClient _client;
    private final String _ecn;
    private final MapOfPoolable<String, OrderObj> _orderCache = new MapOfPoolable<>(new HashMap<>());
    private final Set<String> _subscribedUids = new HashSet<>();

    private final String _orderResponseSql = "select * from order where mode=RESPONSE and ecn='%s' and uid='%s'";
    private final String _finalizeOrderSql = "select * from finalize.order where onLoopback=true";

    private long _cleanerDelayMillis = 2_000;
    public void setCleanerDelay(long delay) {
    	_cleanerDelayMillis = delay;
    }
	private StringDelayer _cacheCleaner;

    public OrderManagerClient(PrestoClient client, String ecn) {
        _client = client;
        _ecn = ecn;
    }

    public void start() {
    	_cacheCleaner = new CacheCleaner(_cleanerDelayMillis);
        _cacheCleaner.start();

        try {
	    	_client.subscribe(_finalizeOrderSql, (obj, subsId) -> {
	            FinalizeOrderObj finalizeOrder = (FinalizeOrderObj) obj;
	            onFinalizeOrder(finalizeOrder);
	    	});
        } catch (Exception e) {
            log.error("", e);
        }
    }

	private void onFinalizeOrder(FinalizeOrderObj finalizeOrder) {
		String ordId = finalizeOrder.getOrdId();
        _orderCache.remove(ordId);
	}

    public void addUser(String uid) {
        if (_subscribedUids.add(uid)) {
            try {
            	_client.subscribe(String.format(_orderResponseSql, _ecn, uid), (obj, subsId) -> {
                    OrderObj response = (OrderObj) obj;
                    String ordId = response.getOrdId();
                    if (_orderCache.containsKey(ordId)) { // my order
                        boolean ftDone = response.isFtDone();
                        if (ftDone) {
                        	_cacheCleaner.add(ordId);
                        }
                        logFillSummary(response);
                        onOrderResponse(response);
                    } else {
                    	if (log.isDebugEnabled()) log.info("hmmm... did not find {} in the cache {}", ordId, obj);
                    }
            	});
            } catch (Exception e) {
                log.error(uid, e);
            }
        }
    }

    public abstract void onOrderResponse(OrderObj response);

    public String addOrder(String uid, String ecn, String ordId,
                          String instrId, MadrigalSide side, MadrigalOrdType ordType, MadrigalTimeInForce tif,
                          double price, double orderQty, double shownQty, int randomMax,
                          boolean useNative) {
    	if (_orderCache.containsKey(ordId)) {
            log.error("Ignoring duplicate order {}...", ordId);
            return null;
    	}

    	try {
        	OrderObj order = ObjectManager.getInstance().acquire(MadrigalConstants.TYPE_ORDER);
	        _orderCache.put(ordId, order);

	    	int ver = 0;
	    	String clOrdId = ordId + "-" + ver;
	        order.setAddRequest(ecn, uid, ordId, ver, clOrdId, instrId, ordType, tif, side, price, orderQty, shownQty, randomMax);
	        order.setUseNative(useNative);
			_client.serialize(order);

	        if (log.isDebugEnabled())
	            log.info("SUMMARY {} {} {} {} {}@{} {} {}", clOrdId, instrId, ADD, side, (int)order.getOrderQty(), Utils.frc(order.getPrice()), ordType, tif);

	        return clOrdId;
    	} catch (Exception x) {
    		log.error("", x);
    	}

    	return null;
    }

    public String delOrder(String ordId) {
        OrderObj order = _orderCache.get(ordId);
        if (order == null) {
            log.error("ordId {} not in cache...", ordId);
            return null;
        }
    	try {
	        int ver = order.getVer() + 1;
	        String clOrdId = ordId + "-" + ver;
	    	order.setDelRequest(ver, clOrdId);
			_client.serialize(order);

	        if (log.isDebugEnabled()) log.info("SUMMARY {} {} {}", clOrdId, DEL, order.getSide());

	        return clOrdId;
    	} catch (Exception x) {
    		log.error("", x);
    	} finally {
	        order.stopUsing();
    	}

    	return null;
    }

    public String rwtOrder(String ordId, double qtyShown, double qtyTot, int randomMax, double price) {
        OrderObj order = _orderCache.get(ordId);
        if (order == null) {
            log.error("ordId {} not in cache...", ordId);
            return null;
        }
    	try {
	        int ver = order.getVer() + 1;
	        String clOrdId = ordId + "-" + ver;
	    	order.setRwtRequest(ver, clOrdId, price, qtyTot, qtyShown, 0);
			_client.serialize(order);

			if (log.isDebugEnabled()) log.info("SUMMARY {} {} {} {}@{}", clOrdId, RWT, order.getSide(), (int)order.getOrderQty(), Utils.frc(order.getPrice()));

	        return clOrdId;
    	} catch (Exception x) {
    		log.error("", x);
    	} finally {
	        order.stopUsing();
    	}

    	return null;
    }

    private void logFillSummary(OrderObj er) {
        if (log.isDebugEnabled()) {
            MadrigalOrdStatus status = er.getStatus();

            String str = "";
            if (status == FILL) {
                str += ((int)er.getLastQty())+"@"+Utils.frc(er.getLastPx())+"/";
            }

            double qtyGoal = er.getOrderQty();
            if (Double.isNaN(qtyGoal)) qtyGoal = -1.0; // TODO ERs received after reconnect; will need to enrich
            str += ((int)er.getCumQty())+"/"+((int)qtyGoal);

            String text = er.getText();
            if (text == null) text = "";

            log.info("SUMMARY {} {} {} {}{}{} {} {}",
            		er.getClOrdId(), er.getReqType(), status, er.getSide(), (er.isDone()?" done":""), (er.isFtDone()?" ftDone":""), str, text);
        }
    }


    private class CacheCleaner extends StringDelayer {
    	private final FinalizeOrderObj _finalizeOrderObj = new FinalizeOrderObj();
    	public CacheCleaner(long delayInMillis) {
    		super(delayInMillis);
    	}
		@Override
		public void execute(String ordId) {
			_finalizeOrderObj.set("foo", ordId, System.currentTimeMillis());
			try {
				_client.loopback(_finalizeOrderObj);
			} catch (Exception e) {
				log.error("", e);
			}
		}
    }
}
