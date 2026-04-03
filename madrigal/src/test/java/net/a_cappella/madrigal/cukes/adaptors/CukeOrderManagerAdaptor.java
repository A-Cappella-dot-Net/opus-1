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

package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.om.IOrderManagerAdaptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class CukeOrderManagerAdaptor implements IOrderManagerAdaptor {
    private static final Logger log = LoggerFactory.getLogger(CukeOrderManagerAdaptor.class);

    private final Map<String, CukeEcnOrder> _ecnOrdersMap = new HashMap<>();

	@Override
	public void connectToExchange() {
    	_ecnOrdersMap.clear();
	}

	@Override
	public void disconnectFromExchange() {
	}

	@Override
	public void sendNewOrderSingle(String uid, String clOrdID, String symbol,
                                   MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side,
                                   double px, double qtyShown, double qty) {
    	CukeEcnOrder order = new CukeEcnOrder(uid, clOrdID, symbol, ordType, tif, side, px, qty, qtyShown);
    	if (log.isDebugEnabled()) log.debug("sendNewOrderSingle "+order);
		_ecnOrdersMap.put(clOrdID, order);
	}

	@Override
	public void sendOrderCancelRequest(String uid, String ecnOrdId,
			String clOrdId, String origClOrdId, String symbol,
			MadrigalSide side,
			double qty) {
    	CukeEcnOrder order = new CukeEcnOrder(uid, ecnOrdId, clOrdId, origClOrdId, symbol, side, qty);
    	if (log.isDebugEnabled()) log.debug("sendOrderCancelRequest "+order);
		_ecnOrdersMap.put(clOrdId, order);
	}

	@Override
	public void sendOrderCancelReplaceRequest(String uid, String ecnOrdId,
			String clOrdId, String origClOrdId, String symbol, double px,
			double qtyShown, double qty,
			MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side) {
    	CukeEcnOrder order = new CukeEcnOrder(uid, ecnOrdId, clOrdId, origClOrdId, symbol, px, qtyShown, qty, ordType, tif, side);
    	if (log.isDebugEnabled()) log.debug("sendOrderCancelReplaceRequest "+order);
		_ecnOrdersMap.put(clOrdId, order);
	}

	public void verifyOrder(CukeEcnOrder order) {
		if (log.isDebugEnabled()) log.debug("verifyOrder "+order);
		assertEquals(order, _ecnOrdersMap.remove(order.getClOrdID()), "order mismatch "+_ecnOrdersMap.keySet());
	}

	public void verifyNoOrders() {
		assertTrue(_ecnOrdersMap.isEmpty(), "No ECN orders expected but these "+_ecnOrdersMap.keySet()+" were found...");
	}

	public void verifyOrdersCount(int expectedSize) {
		assertEquals(expectedSize, _ecnOrdersMap.size(), "orders count");
	}
}
