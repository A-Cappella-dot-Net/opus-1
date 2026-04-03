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

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.IOC;

public class SniperStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(SniperStrategy.class);

	@Override // IOrderRequestHandler
	public boolean isConflateRequests() {
		return true;
	}
	@Override // IOrderRequestHandler
	public boolean isProcessOnePendingRequestAtATime() {
		return false;
	}

	private final boolean _strictRwt;
	@Override
	public boolean isStrictRwt() {
		return _strictRwt;
	}

	public SniperStrategy(boolean strictRwt) {
		_strictRwt = strictRwt;
	}

	@Override // IOrderRequestHandler
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleAddRequest {}", handler._level, request);

		handler.unPend(request);
		// ack the order right away
		request.setStatus(ACK);
		handler.enqueueAckNakResponse(request);

		EcnPriceObj ecnPrice = handler.registerAsPriceListener();
		if (ecnPrice != null) {
			handleEcnPrice(ecnPrice, handler, request);
		}
	}

	@Override // IOrderRequestHandler
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleDelRequest {}", handler._level, request);

		OrderObj deferredRequest = handler.removeDeferredReq();
		if (deferredRequest!=null) {
			conflateRequests(request, deferredRequest, handler);
		} else if (!handler.allChildrenCompleted()) {
			handler.addToDeferredReqsTail(request);
		} else { // no active children
			// ACK the request right away
			handler.unPend(request);
			request.setDone(true);
			if (handler._orderState.getLeavesQty()==0.0) {
				request.setStatus(NAK);
				request.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
			} else {
				request.setStatus(ACK);
			}
			handler.enqueueAckNakResponse(request);
		}
	}

	@Override // IOrderRequestHandler
	public void handleRwtRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleRwtRequest {}", handler._level, request);
		OrderObj deferredRequest = handler.removeDeferredReq();
		if (deferredRequest!=null) {
			conflateRequests(request, deferredRequest, handler);
		} else if (handler._orderState.isDone()) {
            handler.unPend(request);
			request.setDone(false);
			request.setStatus(NAK);
			request.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
			handler.enqueueAckNakResponse(request);
		} else if (!handler.allChildrenCompleted()) {
			handler.addToDeferredReqsTail(request);
		} else { // no active children
			double requested = request.getOrderQty();
			double filled = handler._orderState.getCumQty();

			if (log.isDebugEnabled()) log.info("{} handleRwtRequest {}/{} {}", handler._level, requested, filled, request);

			if (requested < filled) {
				if (_strictRwt) {
					// reject the request
	                handler.unPend(request);
	                request.setDone(false);
					request.setStatus(NAK);
					request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
					handler.enqueueAckNakResponse(request);
				} else {
					// accept the request, stop filling, and conclude order
					handler.unPend(request);
					request.setDone(true);
					request.setStatus(ACK);
					request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE); // expect overfill
					handler.enqueueAckNakResponse(request);
				}
			} else if (requested == filled) {
				// accept the request, stop filling, and conclude order
				handler.unPend(request);
				request.setDone(true);
				request.setStatus(ACK);
				handler.enqueueAckNakResponse(request);
			} else { // requested > filled
				// accept the request and keep filling
				handler.unPend(request);
				request.setDone(false);
				request.setStatus(ACK);
				handler.enqueueAckNakResponse(request);

				// the potentially amended price may be executable now
				EcnPriceObj ecnPrice = handler.getRootHandler().getService().getMdCache().get(request.getInstrId());
				if (ecnPrice != null) {
					handleEcnPrice(ecnPrice, handler, request);
				}
			}
		}
	}

	@Override // IOrderResponseHandler
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleResponse {}", handler._level, response);
		OrderObj orderState = null;
		if (response.getLastQty() > 0.0) {
			// transfer the fill details to the parent
			orderState = handler._orderState;
			orderState.updateFillDetails(response);
			orderState.copyResponseDetails(response);
			orderState.setText(VAL_EMPTY_STRING);
			orderState.setStatus(MadrigalOrdStatus.FILL);
			boolean done = orderState.getLeavesQty() <= 0.0;
			orderState.updateDone(done);
			handler.updateDone(done);
		} else {
			handler._orderState.resetLast(); // the DONE message needs to have lastQty==0.0
		}
		if (response.isFtDone()) {
			OrderObj deferredRequest = handler.removeDeferredReq();
			if (deferredRequest!=null) {
				handleDeferredRequest(deferredRequest, handler);
			} else {
				if (handler._orderState.getLeavesQty() > 0.0) {
					EcnPriceObj ecnPrice = handler.getRootHandler().getService().getMdCache().get(response.getInstrId());
					if (ecnPrice != null) {
						handleEcnPrice(ecnPrice, handler, handler._orderState);
					}
				}
			}
		}
		return orderState;
	}

	@Override
	public void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj request) {
		if (handler.isDone()) return;
		if (log.isDebugEnabled()) log.info("{} handleEcnPrice {} {}", handler._level, request.getClOrdId(), ecnPrice);
		if (handler.allChildrenCompleted()) {
			double price = request.getPrice();
			MadrigalSide side = request.getSide();

			double tobQty = tradableSize(side, price, ecnPrice);
			if (tobQty > 0.0) {
				// send new IOC order for size min (remaining, tob.size+maxRandom) and price = request.price
				String childOrdId = handler.newChildOrdId();

				OrderObj childRequest = handler.newAddRequest(childOrdId, request);
				int randMax = request.getRandomMax();
				double childQty = Math.min(request.getOrderQty() - handler._orderState.getCumQty(), tobQty + randMax);
				childRequest.setTimeInForce(IOC);
	        	childRequest.setOrderQty(childQty);
	        	childRequest.setShownQty(childQty);

				OrderHandler childHandler = handler.newChildOrderHandler(childRequest, request.getClOrdId(), handler.getRootHandler().getService().getOmsParams().getIocStrategy(handler.getRootHandler().getImmutables().isUseNative()));
	        	childHandler.handleAddRequest(childRequest);
			}
		}
	}

	@Override
	public void onFtDone(OrderHandler handler) {
		handler.unRegisterAsPriceListener();
	}

	private double tradableSize(MadrigalSide side, double price, EcnPriceObj ecnPrice) {
		if (side == MadrigalSide.Buy) {
			double tobPrice = ecnPrice.getOffer0();
			double tobSize = ecnPrice.getOfferSize0();
			if (!Double.isNaN(tobPrice) && Utils.cmp(price, tobPrice) >= 0) {
				return tobSize;
			}
		} else {
			double tobPrice = ecnPrice.getBid0();
			double tobSize = ecnPrice.getBidSize0();
			if (!Double.isNaN(tobPrice) && Utils.cmp(price, tobPrice) <= 0) {
				return tobSize;
			}
		}
		return 0.0;
	}

	private void handleDeferredRequest(OrderObj deferredRequest, OrderHandler handler) {
		if (deferredRequest.getReqType() == MadrigalReqType.DEL) {
			handleDelRequest(deferredRequest, handler);
		} else {
			handleRwtRequest(deferredRequest, handler);
		}
	}

	private void conflateRequests(OrderObj request, OrderObj deferredRequest, OrderHandler handler) {
		if (deferredRequest.getReqType() == MadrigalReqType.DEL) {
			// NAK the new request w/ message Pending DEL
			if (handler.unPend(request)) {
				request.setDone(false);
				request.setStatus(NAK);
				request.setText(VAL_ERR_STRING_PENDING_DEL);

				handler.enqueueAckNakResponse(request);
				handler.addToDeferredReqsHead(deferredRequest); // put the old request back at the front of the queue
			}
			request.stopUsing();
		} else { // RWT
			// NAK the deferredRequest w/ message RWT superseded
			if (handler.unPend(deferredRequest)) {
				deferredRequest.setDone(false);
				deferredRequest.setStatus(NAK);
				deferredRequest.setText(MadrigalReqType.RWT + VAL_ERR_STRING_SUPERSEDED);

				handler.enqueueAckNakResponse(deferredRequest);
				handler.addToDeferredReqsTail(request); // put new request at the back of the queue
			}
			deferredRequest.stopUsing();
		}
	}
}
