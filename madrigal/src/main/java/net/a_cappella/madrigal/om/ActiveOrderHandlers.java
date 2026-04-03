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

package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class ActiveOrderHandlers {
    private static final Logger log = LoggerFactory.getLogger(ActiveOrderHandlers.class);

	private final OrderManagerService _orderManagerService;
	private final String _ecn;

	private final Map<String, RootOrderHandler> _byOrdId = new HashMap<>(); // (ordId, rootHandler)
	private final Map<String, Map<String, RootOrderHandler>> _byEcnUid = new HashMap<>(); // (ecnUid, (ordId, rootHandler))

	public ActiveOrderHandlers(OrderManagerService orderManagerService, String ecn) {
		_orderManagerService = orderManagerService;
		_ecn = ecn;
	}

	public RootOrderHandler add(OrderObj order) {
        String ordId = order.getOrdId();
        if (_byOrdId.containsKey(ordId)) return null;

        String ecnUid = order.getEcnUid();

        RootOrderHandler rootOrderHandler = new RootOrderHandler(_orderManagerService, _ecn, order);
        _byOrdId.put(ordId, rootOrderHandler);
        _byEcnUid.computeIfAbsent(ecnUid, eui -> new HashMap<>()).put(ordId, rootOrderHandler);

        return rootOrderHandler;
	}

	public RootOrderHandler get(String ordId) {
		return _byOrdId.get(ordId);
	}

	public RootOrderHandler finalizeOrder(String ordId) {
		RootOrderHandler rootOrderHandler = _byOrdId.remove(ordId);
		if (rootOrderHandler != null) {
			String ecnUid = rootOrderHandler.getImmutables().getEcnUid();
			_byEcnUid.get(ecnUid).remove(ordId);
		}
		return rootOrderHandler;
	}

	public void clear() {
		// TODO
	}

	public void cancelAllActiveOrders(String ecnUid) {
		Map<String, RootOrderHandler> byOrdId = _byEcnUid.get(ecnUid);

		if (byOrdId != null) byOrdId.forEach((ordId, rootOrderHandler) -> {
			OrderObj _delRequest = new OrderObj();
			int ver = 0;
	        String clOrdId = ordId + "-" + ver;
			_delRequest.setDelRequest(ver, clOrdId);
			rootOrderHandler.handleDelRequest(_delRequest);
		});
	}

	public void log(String ecnUid) {
		Map<String, RootOrderHandler> byOrdId = _byEcnUid.get(ecnUid);

		if (byOrdId != null) byOrdId.forEach((ordId, rootOrderHandler) -> {
			log.info("=== active order {} {}", ecnUid, ordId);
			log.info(rootOrderHandler.getImmutables().toString());
		});
	}

	public void log() {
		for (RootOrderHandler rootOrderHandler : _byOrdId.values()) {
			log.info(rootOrderHandler.getImmutables().toString());
		}
	}
}
