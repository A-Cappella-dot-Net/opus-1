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
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;

public class SimulatedIbgRwtStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(SimulatedIbgRwtStrategy.class);

	private final boolean _conflateRequests;
	@Override
	public boolean isConflateRequests() {
		return _conflateRequests;
	}
	@Override
	public boolean isProcessOnePendingRequestAtATime() {
		return true;
	}

	private final boolean _useDelAddForPriceChange;

	private final boolean _strictRwt;
	@Override
	public boolean isStrictRwt() {
		return _strictRwt;
	}

	public SimulatedIbgRwtStrategy(boolean conflateRequests, boolean useDelAddForPriceChange, boolean strictRwt) {
		_conflateRequests = conflateRequests;
		_useDelAddForPriceChange = useDelAddForPriceChange;
		_strictRwt = strictRwt;
	}

	@Override
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		OrderObj childRequest = handler.newAddRequest(handler.newChildOrdId(), request);
        if (request.isIceberg()) {
			EcnInstrumentObj ecnInstr = handler.getEcnInstr(request.getInstrId());
        	double random = request.getShownQty() + Utils.randomInt(request.getRandomMax()) * ecnInstr.getMinQtyIncrement();
        	double requested = request.getOrderQty();

        	double newQty = Math.min(random, requested);

        	childRequest.setOrderQty(newQty);
        	childRequest.setShownQty(newQty);
        }

		OrderHandler childHandler = handler.newChildOrderHandler(childRequest, request.getClOrdId(), handler.getRootHandler().getNativeStrategy());
        childHandler.handleAddRequest(childRequest);
	}

	@Override
	public void handleRwtRequest(OrderObj request, OrderHandler handler) {
		handleRwtRequest(request, handler, false);
	}

	private void handleRwtRequest(OrderObj request, OrderHandler handler, boolean isDeferredRequest) {
		boolean priceChange = request.getPrice()!=handler._orderState.getPrice();
		if (priceChange && _useDelAddForPriceChange && !isDeferredRequest && handler.activeChildrenCount()>1) {
			handler.delAllChildren(request);
			handler.addToDeferredReqsTail(request);
			// two step operation: after receiving all ACKs will place order at the new price
		} else {
			double requested = request.getOrderQty();
			double filled = handler._orderState.getCumQty();
			double fillable = handler.getFillableQty();
			if (log.isDebugEnabled()) log.info("{} handleRwtRequest {}/{}/{} {}", handler._level, requested, filled, fillable, request);
			// always true : filled <= fillable
			if (requested < filled) {
				if (_strictRwt || !handler.delAllChildren(request)) { // strictRwt OR no children to cancel
	                handler.unPend(request);
					request.setDone(handler.allChildrenCompleted());
					request.setStatus(NAK);
					request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
					handler.enqueueAckNakResponse(request);
				}
			} else if (requested == filled) { // includes the case when filled == requested == fillable
				if (!handler.delAllChildren(request)) { // no children to cancel
	                handler.unPend(request);
					request.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
					request.setStatus((handler.isDone()) ? NAK : ACK);
					request.setDone(true);
					handler.enqueueAckNakResponse(request);
				}
			} else if (requested <= fillable) {
				if (!handler.delRwtChildren(request, priceChange)) {
	                handler.unPend(request);
					request.setStatus(ACK);
					handler.enqueueAckNakResponse(request);
				}
			} else { // requested > fillable; includes the case where filled == fillable < requested

				EcnInstrumentObj ecnInstr = handler.getEcnInstr(request.getInstrId());
				double minQty = ecnInstr.getMinQty();
	        	double random = request.getShownQty() + Utils.randomInt(request.getRandomMax()) * ecnInstr.getMinQtyIncrement();
	        	double active = handler.getActiveQty();

				double newQty = Math.min(random - active, requested - fillable);
	        	double remaining = requested - fillable - newQty;
	        	if (remaining < minQty) {
	        		newQty = newQty + remaining;
	        	}

				if (newQty <= 0.0) {
		        	if (priceChange) {
						handler.rwtAllChildren(request);
					} else {
		                handler.unPend(request);
						request.setStatus(ACK);
						handler.enqueueAckNakResponse(request);
					}
				} else if (newQty < minQty) { // add newQty to latest child, and handle possible price change for all children
					if (!handler.rwtNewestChild(request, newQty, priceChange)) {
		        		handler.unPend(request);
		        		handler.enqueueNakResponse(request, VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY, true);
					}
				} else { // newQty >= minQty => rwt all existing children & send new slice
		        	if (priceChange) {
						handler.rwtAllChildren(request);
					}
	        		sendNextChildAddRequest(newQty, request, handler);
				}
			}
		}
	}

	@Override
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
		// cancel all children
		handler.delAllChildren(request);
	}

	@Override
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleResponse {}", handler._level, response);

		OrderObj orderState = handler._orderState;
		OrderObj nakResponse = handler._nakResponse;
		MadrigalOrdStatus status = response.getStatus();

		if (NAK == status) {
			MadrigalReqType reqType = response.getReqType();
			if (reqType == MadrigalReqType.ADD || !response.isDone()) {
				handler.unPendMapped(nakResponse, response);
				return handler.setInFailFastMode(nakResponse);
			}
		}

		if (ACK == status || (NAK == status && response.isDone())) {
			if (handler.anySiblingPending(response.getClOrdId())) {
				return null; // wait
			}
			// no siblings pending

			if (!handler.allChildrenCompleted()) { // some children are active
				if (handler.unPendMapped(orderState, response)) { // request not yet ACKed
					handler.completeParent(false);
					orderState.setStatus(ACK);
					return orderState;
				}
				return null; // do nothing, request already ACKed
			}
			// no children are active

			OrderObj deferredRequest = handler.removeDeferredReq();
			if (deferredRequest!=null) {
				// after receiving all DEL ACKs placing one order at the new price
				handleRwtRequest(deferredRequest, handler, true);
				deferredRequest.stopUsing();
				return null;
			}
			// no deferred request

			handler.backupResponse(orderState); // just in case should unPend into the nakResponse
			handler.unPendMapped(orderState, response);
			MadrigalReqType reqType = orderState.getReqType();
			double leavesQty = orderState.getLeavesQty();
			if (reqType == MadrigalReqType.DEL) {
				if (leavesQty <= 0.0) {
					orderState.setStatus(NAK);
					orderState.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
				} else {
					orderState.setStatus(ACK);
					orderState.setText(VAL_EMPTY_STRING);
				}
				handler.completeParent(true);
			} else { // RWT
				if (leavesQty<0.0) {
					if (_strictRwt) { // need to add back
						// should have unPend'ed into the nakResponse
						handler.transferAndRestore(orderState, nakResponse);

						EcnInstrumentObj ecnInstr = handler.getEcnInstr(orderState.getInstrId());
			        	double random = orderState.getShownQty() + Utils.randomInt(orderState.getRandomMax()) * ecnInstr.getMinQtyIncrement();
			        	double active = handler.getActiveQty();
			        	double requested = orderState.getOrderQty();
			        	double fillable = handler.getFillableQty();

			        	double newQty = Math.min(random - active, requested - fillable);

						double minQty = ecnInstr.getMinQty();

						if (newQty >= minQty) { // adding back
			        		sendNextChildAddRequest(newQty, orderState, handler);
						} else {
							// ignore
						}

						nakResponse.setStatus(NAK);
						nakResponse.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
						handler.completeParent(false);

						return nakResponse;
					} else { // laxRwt
						orderState.setStatus(ACK);
						orderState.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
						handler.completeParent(true);
					}
				} else if (leavesQty==0.0) {
					orderState.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
					orderState.setStatus(ACK);
					handler.completeParent(true);
				} else { // leavesQty>0.0
					orderState.setStatus(handler.isDone()? NAK : ACK);
					handler.completeParent(false);
				}
			}
			return orderState;
		}

		// FILL or DONE
		orderState.updateFillDetails(response);
		orderState.copyResponseDetails(response);
		orderState.setText(VAL_EMPTY_STRING);
		orderState.setStatus(status);
        if (orderState.isIceberg() && !handler._delSent) {
        	OrderObj request = handler.myOnePendRequest();
        	if (request == null) {
        		request = orderState;
        	}

        	double requested = request.getOrderQty();
        	double fillable = handler.getFillableQty();

        	EcnInstrumentObj ecnInstr = handler.getEcnInstr(request.getInstrId());
			double minQty = ecnInstr.getMinQty();
        	double random = request.getShownQty() + Utils.randomInt(request.getRandomMax()) * ecnInstr.getMinQtyIncrement();
        	double active = handler.getActiveQty();

        	double newQty = Math.min(random - active, requested - fillable);
        	double remaining = requested - fillable - newQty;
        	if (remaining < minQty) {
        		newQty = newQty + remaining;
        	}

        	if (newQty <= 0.0) {
    			handler.completeParent(orderState.getLeavesQty() <= 0);
        	} else if (newQty < minQty) {
        		orderState.setText(VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY);
        		handler.completeParent(true); // final partial fill
        	} else {
        		sendNextChildAddRequest(newQty, request, handler);
        		handler.completeParent(false);
        	}
    	} else { // non iceberg
			handler.completeParent(orderState.getLeavesQty() <= 0);
    	}

        return orderState;
	}


	private void sendNextChildAddRequest(double childQty, OrderObj order, OrderHandler handler) {
		OrderObj childRequest = handler.newAddRequest(handler.newChildOrdId(), order);
    	childRequest.setOrderQty(childQty);
    	childRequest.setShownQty(childQty);

    	OrderHandler childHandler = handler.newChildOrderHandler(childRequest, order.getClOrdId(), handler.getRootHandler().getNativeStrategy());
		childHandler.handleAddRequest(childRequest);
	}
}
