package net.a_cappella.mcache;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderState;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

public class EcnOrderStateCache {
    private static final Logger log = LoggerFactory.getLogger(EcnOrderStateCache.class);

    private final Map<String, OrderState> _cacheByOrdId = new HashMap<>();
    private final OrderObj _hwm = new OrderObj();

    public EcnOrderStateCache(String ecn) {
		_hwm.setEcn(ecn);
		_hwm.setMadrigalMode(MadrigalMode.NULL_VAL);
		_hwm.setReqType(MadrigalReqType.NULL_VAL);
    }

    public void onSubscriptionMessage(OrderObj ord, boolean snapComplete) { // build up the cache
		// REQUESTs are serialized
		// RESPONSEs can be but are not necessarily serialized
		long seqNo = ord.getSeqNo();
		if (seqNo>0) _hwm.setSeqNo(seqNo);

		String ordId = ord.getOrdId();
		MadrigalMode mode = ord.getMadrigalMode();
		switch (mode) {
		case REQUEST:
			_cacheByOrdId.computeIfAbsent(ordId, id -> new OrderState()).onRequest(ord, snapComplete);
			break;
		case RESPONSE:
			String ecn = ord.getEcn();
			if (ecn.startsWith(MadrigalConstants.LH_ECN_PREFIX)) {
				if (MadrigalOrdStatus.FILL == ord.getStatus()) { // only unprocessed FILLs here
					int ultPos = ordId.indexOf("~");
					if (ultPos > 0) ordId = ordId.substring(0, ultPos);
					_cacheByOrdId.computeIfAbsent(ordId, id -> new OrderState()).onUnprocessedFill(ord, snapComplete);
				}
			} else {
				_cacheByOrdId.computeIfAbsent(ordId, id -> new OrderState()).onResponse(ord, snapComplete);
			}

			// only RESPONSE messages contain an execId field
			long execId = ord.getExecId();
			_hwm.setExecId(execId);
			break;
		default:
		}
	}

	public void publishSnapRecords(Consumer<Obj> consumer) {
		_cacheByOrdId.values().forEach(orderState -> orderState.publishStateSnapshot(consumer));
	}

	public void publishHighWaterMark(Consumer<Obj> consumer) {
		consumer.accept(_hwm);
		long seqNo = _hwm.getSeqNo(); // updated by consumer
		long execId = _hwm.getExecId();
		log.info("================== publishHighWaterMark seqNo={} execId={}", seqNo, execId);
	}

	public Obj getHighWaterMark() {
		return _hwm;
	}

	public void initHighWaterMark(OrderObj hwm) {
		long seqNo = hwm.getSeqNo();
		long execId = hwm.getExecId();
		log.info("================== initHighWaterMark seqNo={} execId={}", seqNo, execId);
		_hwm.setSeqNo(seqNo);
		_hwm.setExecId(execId);
	}

	public void onFinalizeOrder(String ordId) {
		OrderState orderState = _cacheByOrdId.remove(ordId);
		if (orderState != null) {
			orderState.finalizeOrderState();
		}
	}

	public void log() {
		_cacheByOrdId.forEach((ordId, ordState) -> {
			log.info("=================================\n  {}", ordId);
			ordState.log();
		});
	}

}
