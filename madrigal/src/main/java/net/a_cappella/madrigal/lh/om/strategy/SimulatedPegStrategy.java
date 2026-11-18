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

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalPegPriceType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.lh.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.DONE;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;
import static net.a_cappella.madrigal.common.constants.MadrigalPegPriceType.MARKET;
import static net.a_cappella.madrigal.common.constants.MadrigalPegPriceType.PRIMARY;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.ADD;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.DEL;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.RWT;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.DAY;

/**
 * Pegged orders (ordType=PEGGED) for an exchange that does not support them.
 *
 * <p>The pegged order is worked through one plain limit order, the working order, which is re-priced every
 * time the market data of the exchange shows that the price the order is pegged to has moved. The working
 * order is an ordinary child order (native, or simulated iceberg / rwt when useNative=false), hence it is
 * visible in the market data. This is why only the displayed peg types are supported:
 * <ul>
 * <li>PRIMARY: pegged to the best price on the order's own side (bid for a buy, offer for a sell);</li>
 * <li>MARKET: pegged to the best price on the opposite side (offer for a buy, bid for a sell).</li>
 * </ul>
 * The pegged price is the price pegged to plus pegOffsetValue ticks (signed, added as is for both sides).
 * The peg scope is always local: the only prices available are the ones of the exchange itself.
 *
 * <p>The pegged order is ACKed as soon as it is received; from then on the client only hears about fills,
 * about its own RWT and DEL requests and about the demise of the order. In particular nothing is sent when
 * the working order is re-priced and nothing is sent in the two cases below, which are only logged:
 * <ol>
 * <li>there is no price to peg to: the order is parked, i.e., the working order (if any) is pulled out of
 * the market, until the side of the book the order is pegged to is populated again;</li>
 * <li>the pegged price is more aggressive than the limit of the order (its price, if specified): the order
 * stops tracking and the working order is left where it is, to be hit if the market comes back to it. An
 * order that has no working order at that time (new, or just unparked) is placed at its limit. Tracking
 * resumes when the pegged price is back within the limit.</li>
 * </ol>
 *
 * <p>A PRIMARY peg looks at the side of the book its own working order sits on, so the working order is left
 * out when looking for the price to peg to: the order would otherwise follow itself. Market data and
 * execution reports reach us independently, so a snapshot that does not show the working order where it is
 * known to be is not acted upon; for the same reason the pegged price is only re-evaluated when market data
 * arrives, never when the working order answers a request. Market data that arrives while a request is in
 * flight is not acted upon either: the next snapshot is.
 */
public class SimulatedPegStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(SimulatedPegStrategy.class);

	private static final int MD_LEVELS = 5; // price levels per side in EcnPriceObj
	private static final double STALE = Double.NEGATIVE_INFINITY; // see referencePrice
	private static final double TICK_TOLERANCE = 0.000001;

	/** What needs to be remembered about one pegged order: the strategy itself is shared by all of them. */
	private static final class PegState {
		/** price increment of the instrument */
		double _tick;
		/** the request sent to the working order on our own initiative (place, re-price, park) that is not answered yet */
		String _ownClOrdId;
		/** no price to peg to */
		boolean _parked;
		/** pegged price is beyond the limit of the order */
		boolean _beyondLimit;
	}

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

	public SimulatedPegStrategy(boolean strictRwt) {
		_strictRwt = strictRwt;
	}

	@Override // IOrderRequestHandler
	public String validateAddRequest(OrderObj request, OrderHandler handler) {
		MadrigalPegPriceType pegPriceType = request.getPegPriceType();
		if (MARKET != pegPriceType && PRIMARY != pegPriceType) {
			return VAL_ERR_STRING_PEG_PRICE_TYPE_NOT_SUPPORTED;
		}
		if (DAY != request.getTimeInForce()) {
			return VAL_ERR_STRING_PEG_TIF_NOT_SUPPORTED;
		}
		if (!(request.getShownQty() > 0.0)) { // the working order is always displayed
			return VAL_ERR_STRING_PEG_HIDDEN_NOT_SUPPORTED;
		}
		EcnInstrumentObj ecnInstr = handler.getEcnInstr(request.getInstrId());
		if (!(ecnInstr.getMinPriceIncrement() > 0.0)) { // the offset is a number of price increments
			return VAL_ERR_STRING_PEG_NO_PRICE_INCREMENT;
		}
		return super.validateAddRequest(request, handler);
	}

	@Override // IOrderRequestHandler
	public String validateRwtRequest(OrderObj request, OrderHandler handler) {
		if (!(request.getShownQty() > 0.0)) {
			return VAL_ERR_STRING_PEG_HIDDEN_NOT_SUPPORTED;
		}
		return super.validateRwtRequest(request, handler);
	}

	@Override // IOrderRequestHandler
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleAddRequest {}", handler._level, request);

		PegState state = new PegState();
		EcnInstrumentObj ecnInstr = handler.getEcnInstr(request.getInstrId());
		state._tick = ecnInstr.getMinPriceIncrement();
		handler.setStrategyState(state);

		// ack the order right away: its working orders come and go
		handler.unPend(request);
		request.setStatus(ACK);
		handler.enqueueAckNakResponse(request);

		EcnPriceObj ecnPrice = handler.registerAsPriceListener();
		if (ecnPrice != null) {
			handleEcnPrice(ecnPrice, handler, request);
		} else {
			state._parked = true;
			log.info("{} pegged order {} parked: no market data for {}", handler._level, request.getOrdId(), request.getInstrId());
		}
	}

	@Override // IOrderRequestHandler
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleDelRequest {}", handler._level, request);

		OrderObj deferredRequest = handler.removeDeferredReq();
		if (deferredRequest != null && deferredRequest != request) {
			supersede(deferredRequest, handler); // a RWT that was waiting for the working order: no point in doing it anymore
		}

		if (handler.isDone()) { // only for a request that had to wait
			handler.unPend(request);
			handler.enqueueNakResponse(request, VAL_ERR_STRING_ALREADY_COMPLETED, true);
		} else if (handler.delAllChildren(request)) {
			// the working order is being canceled on behalf of this request, which is answered when the working order is
		} else if (!handler.allChildrenCompleted()) {
			// the working order is already being canceled (parked): wait for it
			handler.addToDeferredReqsTail(request);
		} else { // nothing in the market
			handler.unPend(request);
			request.setDone(true);
			if (handler._orderState.getLeavesQty() <= 0.0) {
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
		handleRwtRequest(request, handler, false);
	}

	/** @param waited the request had to wait for the working order to answer, and the working order just did */
	private void handleRwtRequest(OrderObj request, OrderHandler handler, boolean waited) {
		if (log.isDebugEnabled()) log.info("{} handleRwtRequest {} {}", handler._level, waited, request);

		OrderObj deferredRequest = handler.removeDeferredReq();
		if (deferredRequest != null && deferredRequest != request) {
			supersede(deferredRequest, handler);
		}

		if (handler.isDone() || handler.isInFailFastMode()) {
			handler.unPend(request);
			handler.enqueueNakResponse(request, handler.isDone() ? VAL_ERR_STRING_ALREADY_COMPLETED : VAL_ERR_STRING_FAIL_FAST, handler.isDone());
			return;
		}
		if (handler.anyChildPending()) {
			// one request at a time for the working order: this one waits until the working order answers
			handler.addToDeferredReqsTail(request);
			return;
		}

		double requested = request.getOrderQty();
		double filled = handler._orderState.getCumQty();
		if (requested <= filled) { // only for a request that had to wait and was overtaken by fills
			if (requested < filled && _strictRwt) {
				handler.unPend(request);
				handler.enqueueNakResponse(request, VAL_ERR_STRING_TOO_LATE_TO_REPLACE, false);
			} else if (!handler.delAllChildren(request)) { // nothing in the market, accepting the request now
				handler.unPend(request);
				request.setDone(true);
				request.setStatus(ACK);
				if (requested < filled) request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
				handler.enqueueAckNakResponse(request);
			}
			return;
		}

		OrderHandler child = handler.getActiveChild();
		if (child != null) {
			OrderObj childState = child._orderState;
			double leaves = requested - filled;
			double childQty = childState.getCumQty() + leaves;
			double childShownQty = Math.min(request.getShownQty(), leaves);

			// the working order keeps its price, unless the new limit leaves it on the wrong side
			double childPrice = childState.getPrice();
			double limit = request.getPrice();
			if (!Double.isNaN(limit)) {
				PegState state = state(handler);
				boolean buy = MadrigalSide.Buy == handler._orderState.getSide();
				long childTicks = Math.round(childPrice / state._tick);
				long limitTicks = limitTicks(limit, state._tick, buy);
				if (buy ? (childTicks > limitTicks) : (childTicks < limitTicks)) {
					childPrice = price(limitTicks, state._tick);
				}
			}

			if (Utils.cmp(childQty, childState.getOrderQty()) != 0 || Utils.cmp(childShownQty, childState.getShownQty()) != 0 || Utils.cmp(childPrice, childState.getPrice()) != 0) {
				OrderObj childRequest = child.newRwtRequest(childPrice, childQty, childShownQty, request.getClOrdId());
				child.handleRwtRequest(childRequest);
				return; // the request is answered when the working order is; the pegged price is looked at again with the next market data
			}
		}

		// nothing to change in the market: either only the limit has changed or the order is parked
		handler.unPend(request);
		request.setDone(false);
		request.setStatus(ACK);
		handler.enqueueAckNakResponse(request);

		// the new limit and quantity count right away, unless the working order just answered:
		// the market data we have may not know about that yet, the next one will
		if (!waited) {
			EcnPriceObj ecnPrice = handler.getRootHandler().getService().getMdCache().get(handler._orderState.getInstrId());
			if (ecnPrice != null) {
				handleEcnPrice(ecnPrice, handler, request);
			}
		}
	}

	@Override // IOrderResponseHandler
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleResponse {}", handler._level, response);

		PegState state = state(handler);
		MadrigalOrdStatus status = response.getStatus();

		if (ACK == status || NAK == status) {
			if (response.getClOrdId().equals(state._ownClOrdId)) {
				return handleOwnResponse(response, handler, state);
			}
			return (ACK == status) ? handleAck(response, handler) : handleNak(response, handler);
		}

		// FILL or DONE
		OrderObj orderState = handler._orderState;
		orderState.updateFillDetails(response);
		orderState.copyResponseDetails(response);
		orderState.setStatus(status);
		if (response.getLastQty() > 0.0) {
			orderState.setText(VAL_EMPTY_STRING);
			handler.completeParent(orderState.getLeavesQty() <= 0.0);
		} else { // the working order was canceled by the exchange: so is the pegged order
			orderState.setText(response.getText());
			handler.completeParent(true);
		}
		return orderState;
	}

	/** The working order answered a request that was sent on our own initiative: the client is not told, unless the order is over. */
	private OrderObj handleOwnResponse(OrderObj response, OrderHandler handler, PegState state) {
		state._ownClOrdId = null;
		handler.unmapChild(response.getClOrdId());

		OrderObj parentResponse = null;
		if (NAK == response.getStatus() && !handler.isDone()) {
			String text = response.getText();
			if (ADD == response.getReqType()) {
				// the working order was rejected: so is the pegged order, which was already ACKed though
				log.info("{} pegged order {} is over: its working order was rejected '{}'", handler._level, handler._orderState.getOrdId(), text);
				parentResponse = handler._orderState;
				parentResponse.resetLast();
				parentResponse.setStatus(DONE);
				parentResponse.setText(text);
				handler.completeParent(true);
			} else if (!response.isDone() && !handler._delSent) {
				// the working order is alive but it can be neither re-priced nor parked
				log.warn("{} pegged order {} cannot be {}: '{}'", handler._level, handler._orderState.getOrdId(), (RWT == response.getReqType()) ? "re-priced" : "parked", text);
				OrderObj nakResponse = handler._nakResponse;
				nakResponse.setText((text == null || text.isEmpty()) ? VAL_ERR_STRING_FAIL_FAST : text);
				handler.setInFailFastMode(nakResponse); // not reported as such: no request of the client was rejected
			}
			// else the working order is gone; its last fill, or its cancel, tells what happened to the pegged order
		}

		// a request of the client may be waiting for the working order to answer
		OrderObj deferredRequest = handler.removeDeferredReq();
		if (deferredRequest != null) {
			if (DEL == deferredRequest.getReqType()) {
				handleDelRequest(deferredRequest, handler);
			} else {
				handleRwtRequest(deferredRequest, handler, true);
			}
		}
		return parentResponse;
	}

	/** The working order accepted a request that was sent on behalf of a request of the client. */
	private OrderObj handleAck(OrderObj response, OrderHandler handler) {
		OrderObj orderState = handler._orderState;
		if (!handler.unPendMapped(orderState, response)) return null;
		// orderState is now about the request of the client: type, ids and goal

		orderState.setStatus(ACK);
		orderState.setText(VAL_EMPTY_STRING);
		if (DEL == orderState.getReqType()) {
			handler.completeParent(true);
		} else if (DEL == response.getReqType()) { // RWT to a quantity that is already filled: the working order was canceled
			double leavesQty = orderState.getLeavesQty();
			orderState.setText((leavesQty < 0.0) ? VAL_ERR_STRING_TOO_LATE_TO_REPLACE : VAL_ERR_STRING_ALREADY_COMPLETED);
			handler.completeParent(true);
		} else {
			handler.completeParent(false);
		}
		return orderState;
	}

	/** The working order rejected a request that was sent on behalf of a request of the client. */
	private OrderObj handleNak(OrderObj response, OrderHandler handler) {
		OrderObj nakResponse = handler._nakResponse;
		if (!handler.unPendMapped(nakResponse, response)) return null;
		// nakResponse is now about the request of the client: type, ids and goal

		if (!response.isDone()) { // the working order is alive but it does not do as told
			String text = nakResponse.getText();
			if (text == null || text.isEmpty()) nakResponse.setText(VAL_ERR_STRING_FAIL_FAST);
			return handler.setInFailFastMode(nakResponse);
		}

		// the working order is gone
		OrderObj orderState = handler._orderState;
		nakResponse.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
		if (DEL == nakResponse.getReqType()) {
			nakResponse.copyRequestGoal(orderState);
		}
		nakResponse.updateCumulatives(orderState);
		handler.completeParent(true);
		return nakResponse;
	}

	private void supersede(OrderObj deferredRequest, OrderHandler handler) {
		if (handler.unPend(deferredRequest)) {
			handler.enqueueNakResponse(deferredRequest, deferredRequest.getReqType() + VAL_ERR_STRING_SUPERSEDED, false);
		}
	}

	@Override // IOrderHandlerStrategy
	public void onFtDone(OrderHandler handler) {
		handler.unRegisterAsPriceListener();
	}

	/**
	 * Works out the pegged price and brings the working order in line with it.
	 * @param goal the price (limit) and quantities to go by: the request being handled or, for market data, the state of the order
	 */
	@Override // IOrderHandlerStrategy
	public void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj goal) {
		if (handler.isDone() || handler.isInFailFastMode()) return;
		if (handler.anyChildPending()) return; // the working order is busy: the market data that follows its answer is acted upon

		PegState state = state(handler);
		OrderObj orderState = handler._orderState;
		String ordId = orderState.getOrdId();
		OrderHandler child = handler.getActiveChild();

		boolean buy = MadrigalSide.Buy == orderState.getSide();
		boolean primary = PRIMARY == orderState.getPegPriceType();
		boolean pegToBid = (buy == primary);
		double tick = state._tick;

		// the price pegged to
		double ownPrice = Double.NaN;
		double ownQty = 0.0;
		if (primary && child != null) { // the working order is on the side of the book the order is pegged to
			ownPrice = child._orderState.getPrice();
			ownQty = displayedQty(child);
		}
		double referencePrice = referencePrice(ecnPrice, pegToBid, ownPrice, ownQty);
		if (referencePrice == STALE) {
			if (log.isDebugEnabled()) log.info("{} pegged order {}: market data does not show its working order at {} yet", handler._level, ordId, ownPrice);
			return;
		}

		if (Double.isNaN(referencePrice)) { // edge case 1: nothing to peg to
			if (!state._parked) {
				state._parked = true;
				log.info("{} pegged order {} parked: no {} to peg to", handler._level, ordId, pegToBid ? "bid" : "offer");
			}
			state._beyondLimit = false;
			if (child != null) { // out of the market
				OrderObj childRequest = child.newDelRequest(orderState.getClOrdId());
				state._ownClOrdId = childRequest.getClOrdId();
				child.handleDelRequest(childRequest);
			}
			return;
		}

		// the pegged price
		long peggedTicks = Math.round(referencePrice / tick) + orderState.getPegOffsetValue();
		double limit = goal.getPrice();
		if (!Double.isNaN(limit)) {
			long limitTicks = limitTicks(limit, tick, buy);
			if (buy ? (peggedTicks > limitTicks) : (peggedTicks < limitTicks)) { // edge case 2: more aggressive than the limit
				if (!state._beyondLimit) {
					state._beyondLimit = true;
					log.info("{} pegged order {} stops tracking: the pegged price {} is beyond its limit {}", handler._level, ordId, price(peggedTicks, tick), limit);
				}
				if (child != null) return; // the working order is left in place
				peggedTicks = limitTicks; // nothing in the market yet: the order goes in at its limit
			} else if (state._beyondLimit) {
				state._beyondLimit = false;
				log.info("{} pegged order {} resumes tracking: the pegged price {} is within its limit {}", handler._level, ordId, price(peggedTicks, tick), limit);
			}
		} else {
			state._beyondLimit = false;
		}

		// the working order
		double peggedPrice = price(peggedTicks, tick);
		if (child == null) {
			if (state._parked) {
				state._parked = false;
				log.info("{} pegged order {} unparked at {}", handler._level, ordId, peggedPrice);
			}
			double leavesQty = goal.getOrderQty() - orderState.getCumQty();

			OrderObj childRequest = handler.newAddRequest(handler.newChildOrdId(), orderState);
			childRequest.setOrdType(MadrigalOrdType.LIMIT); // the exchange knows nothing about pegged orders
			childRequest.setPeg(MadrigalPegPriceType.NULL_VAL, (byte) 0);
			childRequest.setPrice(peggedPrice);
			childRequest.setOrderQty(leavesQty);
			childRequest.setShownQty(Math.min(goal.getShownQty(), leavesQty));
			childRequest.setRandomMax(goal.getRandomMax());

			boolean useNative = handler.getRootHandler().getImmutables().isUseNative();
			IOrderHandlerStrategy childStrategy = handler.getRootHandler().getService().getOmsParams().getIbgRwtStrategy(useNative);
			child = handler.newChildOrderHandler(childRequest, orderState.getClOrdId(), childStrategy);
			state._ownClOrdId = childRequest.getClOrdId();
			child.handleAddRequest(childRequest);
		} else if (Math.round(child._orderState.getPrice() / tick) != peggedTicks) {
			if (log.isDebugEnabled()) log.info("{} pegged order {} re-priced {} => {}", handler._level, ordId, child._orderState.getPrice(), peggedPrice);
			OrderObj childState = child._orderState;
			OrderObj childRequest = child.newRwtRequest(peggedPrice, childState.getOrderQty(), childState.getShownQty(), orderState.getClOrdId());
			state._ownClOrdId = childRequest.getClOrdId();
			child.handleRwtRequest(childRequest);
		}
	}

	private static PegState state(OrderHandler handler) {
		return (PegState) handler.getStrategyState();
	}

	/**
	 * @param ownPrice the price of the working order, if it sits on this side of the book; NaN otherwise
	 * @param ownQty the displayed quantity of the working order
	 * @return the best price on the given side of the book once the working order is left out; NaN if nothing is left;
	 *         STALE if the working order is not where it should be, i.e., the market data is older than what we know about it
	 */
	private static double referencePrice(EcnPriceObj ecnPrice, boolean bid, double ownPrice, double ownQty) {
		boolean own = !Double.isNaN(ownPrice);
		boolean ownFound = false;
		double referencePrice = Double.NaN;
		double lastPrice = Double.NaN;
		for (int level=0; level<MD_LEVELS; level++) {
			double price = levelPrice(ecnPrice, bid, level);
			double size = levelSize(ecnPrice, bid, level);
			if (Double.isNaN(price) || !(size > 0.0)) break;
			lastPrice = price;
			if (own && Utils.cmp(price, ownPrice) == 0) {
				ownFound = true;
				if (Utils.cmp(size, ownQty) <= 0) continue; // nobody else at this price
			}
			if (Double.isNaN(referencePrice)) referencePrice = price;
		}
		if (own && !ownFound) {
			// fine only if the working order is further away than the last price level that is published
			boolean beyondPublishedLevels = !Double.isNaN(lastPrice) && (bid ? Utils.cmp(ownPrice, lastPrice) < 0 : Utils.cmp(ownPrice, lastPrice) > 0);
			if (!beyondPublishedLevels) return STALE;
		}
		return referencePrice;
	}

	/** What the market data shows of the working order. */
	private static double displayedQty(OrderHandler child) {
		if (!child._childrenHandlers.isEmpty()) {
			return child.getActiveQty(); // simulated iceberg: the slices that are in the market
		}
		OrderObj childState = child._orderState;
		return Math.min(childState.getLeavesQty(), childState.getShownQty());
	}

	/** @return the most aggressive valid price that is within the limit, in ticks */
	private static long limitTicks(double limit, double tick, boolean buy) {
		double ticks = limit / tick;
		long rounded = Math.round(ticks);
		if (Math.abs(ticks - rounded) < TICK_TOLERANCE) return rounded;
		return (long) (buy ? Math.floor(ticks) : Math.ceil(ticks));
	}

	private static double price(long ticks, double tick) {
		// dividing by a whole number of ticks gives the double that is closest to the decimal price; multiplying by a tick such as 0.01 may not
		double ticksPerUnit = Math.rint(1.0 / tick);
		return (ticksPerUnit >= 1.0 && Utils.cmp(ticksPerUnit * tick, 1.0) == 0) ? ticks / ticksPerUnit : ticks * tick;
	}

	private static double levelPrice(EcnPriceObj ecnPrice, boolean bid, int level) {
		switch (level) {
		case 0: return bid ? ecnPrice.getBid0() : ecnPrice.getOffer0();
		case 1: return bid ? ecnPrice.getBid1() : ecnPrice.getOffer1();
		case 2: return bid ? ecnPrice.getBid2() : ecnPrice.getOffer2();
		case 3: return bid ? ecnPrice.getBid3() : ecnPrice.getOffer3();
		default: return bid ? ecnPrice.getBid4() : ecnPrice.getOffer4();
		}
	}

	private static double levelSize(EcnPriceObj ecnPrice, boolean bid, int level) {
		switch (level) {
		case 0: return bid ? ecnPrice.getBidSize0() : ecnPrice.getOfferSize0();
		case 1: return bid ? ecnPrice.getBidSize1() : ecnPrice.getOfferSize1();
		case 2: return bid ? ecnPrice.getBidSize2() : ecnPrice.getOfferSize2();
		case 3: return bid ? ecnPrice.getBidSize3() : ecnPrice.getOfferSize3();
		default: return bid ? ecnPrice.getBidSize4() : ecnPrice.getOfferSize4();
		}
	}
}
