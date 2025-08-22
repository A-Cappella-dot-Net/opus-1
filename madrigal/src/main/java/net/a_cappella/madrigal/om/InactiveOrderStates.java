package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class InactiveOrderStates {
    private static final Logger log = LoggerFactory.getLogger(InactiveOrderStates.class);

    private final OrderManagerService _service;
    private final Map<String, OrderState> _byOrdId = new HashMap<>(); // (ordId, state)
	private final Map<String, Map<String, OrderState>> _byEcnUid = new HashMap<>(); // (ecnUid, (ordId, state))

	public InactiveOrderStates(OrderManagerService service) {
		_service = service;
	}

	public void onSubscriptionMessage(OrderObj order, boolean snapComplete) {
		String ordId = order.getOrdId();
		String ecnUid = order.getEcnUid();
		MadrigalMode mode = order.getMadrigalMode();
		switch (mode) {
		case REQUEST:
			onRequest(ordId, ecnUid, order, snapComplete);
			break;
		case RESPONSE:
			String ecn = order.getEcn();
			if (ecn.startsWith(MadrigalConstants.LH_ECN_PREFIX)) {
				if (MadrigalOrdStatus.FILL == order.getStatus()) { // only unprocessed FILLs here
					int ultPos = ordId.indexOf("~");
					if (ultPos > 0) ordId = ordId.substring(0, ultPos);

					onUnprocessedFill(ordId, ecnUid, order, snapComplete);
				}
			} else {
				onResponse(ordId, ecnUid, order, snapComplete);
			}
			break;
		default:
		}
		
	}

	private void onRequest(String ordId, String ecnUid, OrderObj request, boolean snapComplete) {
		OrderState state = _byOrdId.computeIfAbsent(ordId, id -> new OrderState());
		_byEcnUid.computeIfAbsent(ecnUid, id -> new HashMap<>()).put(ordId, state);

		state.onRequest(request, snapComplete);
	}

	private void onResponse(String ordId, String ecnUid, OrderObj response, boolean snapComplete) {
		OrderState state = _byOrdId.computeIfAbsent(ordId, id -> new OrderState());
		_byEcnUid.computeIfAbsent(ecnUid, id -> new HashMap<>()).put(ordId, state);

		state.onResponse(response, snapComplete);
	}

	private void onUnprocessedFill(String ordId, String ecnUid, OrderObj response, boolean snapComplete) {
		OrderState state = _byOrdId.computeIfAbsent(ordId, id -> new OrderState());
		_byEcnUid.computeIfAbsent(ecnUid, id -> new HashMap<>()).put(ordId, state);

		state.onUnprocessedFill(response, snapComplete);
	}

	public void activateOrders(String ecnUid, ActiveOrderHandlers activeHandlers) {
		Map<String, OrderState> byOrdId = _byEcnUid.remove(ecnUid);

		if (byOrdId != null) byOrdId.forEach((ordId, ordState) -> {
			activateOrder(ecnUid, ordId, ordState, activeHandlers);
			_byOrdId.remove(ordId);
		});
	}

	private void activateOrder(String ecnUid, String ordId, OrderState ordState, ActiveOrderHandlers activeHandlers) {
		OrderObj state = ordState.getState();
		_service.populateEcnIds(state);
		RootOrderHandler rootHandler = activeHandlers.add(state);
		log.info("=== activating order {} {} {}", ecnUid, ordId, rootHandler.getImmutables());
		rootHandler.activateOrder(state, ordState.getQueuedList(), ordState.getUnprocessedFills());
	}

	public void log() {
		_byOrdId.forEach((ordId, ordState) -> {
			log.info("=== inactive order {}", ordId);
			ordState.log();
		});
	}

}
