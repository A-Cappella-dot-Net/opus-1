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

package net.a_cappella.madrigal.lh.om.strategy;

import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.lh.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.*;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.ADD;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.DEL;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.DAY;

public class SimulatedIocStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(SimulatedIocStrategy.class);

	@Override // IOrderRequestHandler
	public boolean isConflateRequests() {
		return false;
	}
	@Override // IOrderRequestHandler
	public boolean isProcessOnePendingRequestAtATime() {
		return false;
	}
	@Override
	public boolean isStrictRwt() { // will never be called since validation will fail first
		return false;
	}

	@Override // IOrderRequestHandler
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		String childOrdId = handler.newChildOrdId();

		OrderObj childAddRequest = handler.newAddRequest(childOrdId, request);
		childAddRequest.setTimeInForce(DAY);

		OrderHandler childHandler = handler.newChildOrderHandler(childAddRequest, request.getClOrdId(), handler.getRootHandler().getNativeStrategy());
		childHandler.handleAddRequest(childAddRequest);

        OrderObj childDelRequest = childHandler.newRequest(DEL, childOrdId, request, request.getClOrdId());
		childDelRequest.setTimeInForce(DAY);

		childHandler.handleDelRequest(childDelRequest);
	}

	@Override // IOrderRequestHandler
	public String validateRwtRequest(OrderObj request, OrderHandler handler) {
		return VAL_ERR_STRING_RWT_NOT_SUPPORTED;
	}
	@Override // IOrderRequestHandler
	public void handleRwtRequest(OrderObj request, OrderHandler handler) {
	}

	@Override // IOrderRequestHandler
	public String validateDelRequest(OrderObj request, OrderHandler handler) {
		return VAL_ERR_STRING_DEL_NOT_SUPPORTED;
	}
	@Override // IOrderRequestHandler
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
	}

	@Override // IOrderResponseHandler
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info(handler._level + " handleResponse "+response);
		// er for the only child order

		MadrigalOrdStatus status = response.getStatus();

		MadrigalReqType reqType = response.getReqType();
		if (ACK == status) {
			OrderObj orderState = handler._orderState;

			if (ADD == reqType) {
				handler.unPendMapped(orderState, response);
				orderState.setText(VAL_EMPTY_STRING);
				orderState.setStatus(ACK);
				return orderState;
			} else { // DEL
				orderState.resetLast();
				orderState.setText("Could not match IOC order");
				orderState.setStatus(DONE);
				orderState.setDone(true);
				handler.updateDone(true);
				return orderState;
			}
		} else if (NAK == status) {
			OrderObj nakResponse = handler._nakResponse;

			if (ADD == reqType) {
				handler.unPendMapped(nakResponse, response); 
				nakResponse.setText(response.getText());
				return nakResponse;
			} else { // DEL
				// DEL was rejected
				handler.unPendMapped(nakResponse, response);
				OrderObj orderState = handler._orderState;
				if (orderState.isDone()) {
					return null;
				}
				orderState.setDone(true);
				handler.updateDone(true);
				return orderState;
			}
		} else { // FILL or DONE
			OrderObj orderState = handler._orderState;
			orderState.updateFillDetails(response);
			orderState.copyResponseDetails(response);
			orderState.setText(VAL_EMPTY_STRING);
			orderState.setStatus(status);
			boolean done = orderState.getLeavesQty()<=0.0;
			orderState.setDone(done);
			handler.updateDone(done);
			return orderState;
		}
	}
}
