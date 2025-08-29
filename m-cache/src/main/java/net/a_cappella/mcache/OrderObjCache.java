package net.a_cappella.mcache;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.obj.FinalizeOrderObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.presto.obj.CacheCmdObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

public class OrderObjCache implements IObjCache {
    private static final Logger log = LoggerFactory.getLogger(OrderObjCache.class);

    private boolean _snapComplete = false;
	private final Map<String, EcnOrderStateCache> _statesByEcn = new HashMap<>();

	public void setSnapComplete(boolean snapComplete) {
		_snapComplete = snapComplete;
	}

	@Override
	public void onSubscriptionMessage(Obj obj, long subsId) { // add OrderObj to the cache
		OrderObj ord = (OrderObj) obj;
		String ecn = ord.getEcn();
		if (ecn.startsWith(MadrigalConstants.LH_ECN_PREFIX)) {
			// ord.getMadrigalMode() == MadrigalMode.RESPONSE
			if (ord.getStatus() != MadrigalOrdStatus.FILL) return; // only interested in unprocessed FILLs
			ecn = ecn.substring(MadrigalConstants.LH_ECN_PREFIX.length());
		}
		_statesByEcn.computeIfAbsent(ecn, e -> new EcnOrderStateCache(e)).onSubscriptionMessage(ord, _snapComplete);
	}

	@Override
	public void initHighWaterMark(Obj hwm) {
		OrderObj ord = (OrderObj) hwm;
		String ecn = ord.getEcn();
		_statesByEcn.computeIfAbsent(ecn, e -> new EcnOrderStateCache(e)).initHighWaterMark(ord);
	}

	@Override
	public void publishSnapRecords(Consumer<Obj> consumer) {
		if (_snapComplete) { // only if the state has been properly initialized
			_statesByEcn.values().forEach(ecnOrdState -> ecnOrdState.publishSnapRecords(consumer));
		}
	}
	public void publishSnapRecords(String ecn, Consumer<Obj> consumer) {
		if (_snapComplete) { // only if the state has been properly initialized
			EcnOrderStateCache ecnOrderState = _statesByEcn.get(ecn);
			if (ecnOrderState!=null) {
				ecnOrderState.publishSnapRecords(consumer); // optimized case
			}
		}
	}

	public void publishHighWaterMark(Consumer<Obj> consumer) {
		if (_snapComplete) { // only if the state has been properly initialized
			_statesByEcn.values().forEach(ecnOrdState -> ecnOrdState.publishHighWaterMark(consumer));
		}
	}
	public void publishHighWaterMark(String ecn, Consumer<Obj> consumer) {
		if (_snapComplete) { // only if the state has been properly initialized
			EcnOrderStateCache ecnOrderState = _statesByEcn.get(ecn);
			if (ecnOrderState!=null) {
				ecnOrderState.publishHighWaterMark(consumer);
			}
		}
	}

	public Obj getHighWaterMark(String ecn) {
		EcnOrderStateCache ecnOrderState = _statesByEcn.get(ecn);
		return (ecnOrderState==null) ? null : ecnOrderState.getHighWaterMark();
	}

	@Override
	public void onCacheCmdMessage(CacheCmdObj obj) {
    	String command = obj.getCommand();
    	switch (command) {
    	case ManagedCache.CMD_CLEAN:
    		break;
    	case ManagedCache.CMD_LOG:
    		log();
    		break;
    	default:
    		log.warn("Unrecognized command {}", command);
    	}
	}

	public void onFinalizeOrder(FinalizeOrderObj finalizeOrder) {
        String ecn = finalizeOrder.getEcn().substring(MadrigalConstants.LH_ECN_PREFIX.length());
        String ordId = finalizeOrder.getOrdId();
        EcnOrderStateCache ecnOrderStateCache = _statesByEcn.get(ecn);
        if (ecnOrderStateCache != null) {
        	ecnOrderStateCache.onFinalizeOrder(ordId);
        }
	}

	@Override
	public void log() {
		_statesByEcn.forEach((ecn, ecnOrdState) -> {
			log.info("---------------------------------\n  {}", ecn);
			ecnOrdState.log();
		});
	}

}
