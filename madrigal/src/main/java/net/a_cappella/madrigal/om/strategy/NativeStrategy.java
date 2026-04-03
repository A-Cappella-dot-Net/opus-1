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

package net.a_cappella.madrigal.om.strategy;

import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.IOrderManagerAdaptor;
import net.a_cappella.madrigal.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.DONE;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.DEL;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.RWT;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.IOC;

public class NativeStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(NativeStrategy.class);

	private final boolean _conflateRequests;
	@Override
	public boolean isConflateRequests() {
		return _conflateRequests;
	}
	private final boolean _processOnePendingRequestAtATime;
	@Override
	public boolean isProcessOnePendingRequestAtATime() {
		return _processOnePendingRequestAtATime;
	}
	private final boolean _strictRwt;
	@Override
	public boolean isStrictRwt() {
		return _strictRwt;
	}

	private final IOrderManagerAdaptor _adaptor;

	public NativeStrategy(boolean conflateRequests, boolean processOnePendingRequestAtATime, boolean strictRwt, IOrderManagerAdaptor adaptor) {
		_conflateRequests = conflateRequests;
		_processOnePendingRequestAtATime = processOnePendingRequestAtATime;
		_strictRwt = strictRwt;
		_adaptor = adaptor;
	}

	@Override
	public String validateRwtRequest(OrderObj request, OrderHandler handler) {
		if (IOC == request.getTimeInForce()) {
			return VAL_ERR_STRING_RWT_NOT_SUPPORTED;
		}
		return super.validateAddRequest(request, handler);
	}

	@Override
	public String validateDelRequest(OrderObj request, OrderHandler handler) {
		if (IOC == request.getTimeInForce()) {
			return VAL_ERR_STRING_DEL_NOT_SUPPORTED;
		}
		return null;
	}

	@Override
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		handler.getRootHandler().getService().getLeafHandlers().put(request.getOrdId(), handler);

		String uid = request.getEcnUid();
		String clOrdId = request.getClOrdId();
		String xClOrdId = handler.getAndMapNextXClOrdId(clOrdId);
		String symbol = request.getEcnInstrId();
		MadrigalOrdType ordType = request.getOrdType();
		MadrigalTimeInForce tif = request.getTimeInForce();
		MadrigalSide side = request.getSide();
		double px = request.getPrice();
		double qty = request.getOrderQty();
		double qtyShown = Math.min(request.getShownQty(), qty);

		_adaptor.sendNewOrderSingle(uid, xClOrdId, symbol, ordType, tif, side, px, qtyShown, qty);
	}

	@Override
	public void handleRwtRequest(OrderObj request, OrderHandler handler) {
		String uid = request.getEcnUid();
		String ecnOrdId = handler._orderState.getEcnOrdId();
		String clOrdId = request.getClOrdId();
		String xClOrdId = handler.getAndMapNextXClOrdId(clOrdId);
		String origXClOrdId = handler.getLatestAckedXClOrdId();
		String symbol = request.getEcnInstrId();
		MadrigalOrdType ordType = request.getOrdType();
		MadrigalTimeInForce tif = request.getTimeInForce();
		MadrigalSide side = request.getSide();
		double px = request.getPrice();
		double qty = request.getOrderQty();
		double qtyShown = Math.min(request.getShownQty(), qty);

		_adaptor.sendOrderCancelReplaceRequest(uid, ecnOrdId, xClOrdId, origXClOrdId, symbol, px, qtyShown, qty, ordType, tif, side);
	}

	@Override
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
		handleDelRequest0(request, handler);
		handler.initCancelRetryLogic();
	}
	private void handleDelRequest0(OrderObj request, OrderHandler handler) {
		String uid = request.getEcnUid();
		String ecnOrdId = handler._orderState.getEcnOrdId();
		String clOrdId = request.getClOrdId();
		String xClOrdId = handler.getAndMapNextXClOrdId(clOrdId);
		String origXClOrdId = handler.getLatestAckedXClOrdId();
		String symbol = request.getEcnInstrId();
		MadrigalSide side = request.getSide();
		double qty = request.getOrderQty();

		_adaptor.sendOrderCancelRequest(uid, ecnOrdId, xClOrdId, origXClOrdId, symbol, side, qty);
	}

	@Override
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleResponse {}", handler._level, response);

		MadrigalOrdStatus status = response.getStatus();
		MadrigalReqType reqType = response.getReqType();

		OrderObj orderState = handler._orderState;

		switch (status) {
		case ACK:
			if (!handler.unPendMapped(orderState, response)) {
				if (DEL != reqType) return null; // should not happen
				// non solicited cancel
				orderState.setStatus(DONE);
				orderState.setText(response.getText());
			} else {
				orderState.setStatus(ACK);
			}
			orderState.resetLast();
			handler.saveLatestAckedXClOrdId(orderState);

			if (RWT == reqType || DEL == reqType) {
				handler.updateDone(response.isDone());
			}
			return orderState;
		case NAK:
			OrderObj nakResponse = handler._nakResponse;

			if (!handler.unPendMapped(nakResponse, response)) return null;

			switch (reqType) {
			case ADD:
				handler.updateDone(response.isDone());
				break;
			case RWT:
				if (response.isDone()) {
					nakResponse.setText(VAL_ERR_STRING_ALREADY_COMPLETED); // replace exchange error text with our own
				}
				nakResponse.updateCumulatives(orderState);
				handler.updateDone(response.isDone());
				break;
			case DEL:
				if (response.isDone()) {
					log.info("{} DEL failed but done!", handler._level);
					nakResponse.setText(VAL_ERR_STRING_ALREADY_COMPLETED); // replace exchange error text with our own
					nakResponse.copyRequestGoal(orderState);
					nakResponse.updateCumulatives(orderState);
					handler.updateDone(true);
				} else if (handler.okToRetryCancel()) {
					response.setDelRequest(nakResponse.getVer(), nakResponse.getClOrdId());
					response.setEcnUid(nakResponse.getEcnUid());
					response.setEcnInstrId(nakResponse.getEcnInstrId());
					response.setSide(nakResponse.getSide());
					response.setOrderQty(nakResponse.getOrderQty());
					handler.pend(response);

					log.info("{} DEL failed, retrying...", handler._level);
					handleDelRequest0(response, handler);
					return null;
				} else {
					log.info("{} DEL failed, passing to parent...", handler._level);
					handler._delSent = false;
					handler._delNaked = true;
				}
				break;
			default:
				break;
			}
			return nakResponse;
		case DONE:
		case FILL:
			response.setReqType(orderState.getReqType());

			orderState.updateFillDetails(response);
			orderState.copyResponseDetails(response);
			orderState.setText(response.getText());
			orderState.setStatus(status);
			handler.updateDone(response.isDone());
			return orderState;
		default:
			log.error("{} Unknown Response status {} in {}", handler._level, status, response);
			return null;
		}
	}
}
