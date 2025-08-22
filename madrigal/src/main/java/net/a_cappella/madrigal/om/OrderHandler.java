package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.constants.MadrigalActionOnFailover;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.logic.DelNakRetryManager;
import net.a_cappella.madrigal.om.strategy.IOrderHandlerStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NULL_VAL;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.*;

public class OrderHandler implements IOrderHandler {
    private static final Logger log = LoggerFactory.getLogger(OrderHandler.class);

	private IOrderHandlerStrategy _strategy;
    private RootOrderHandler _rootHandler;
	public IOrderResponseHandler _parent;
	public List<OrderHandler> _childrenHandlers = new ArrayList<>();

	private final List<OrderObj> _queuedReqs = new ArrayList<>();
	/**
	 * _pending is true if and only if
	 * (1) the first child of the order has not been ACKed/NAKed yet, or
	 * (2) the strategy associated with the handler has flag processOnePendingRequestAtATime set to true
	 *     and a previous request (DEL, RWT) has not been ACKed/NAKed yet.
	 * 
	 * It is used to prevent sending any new request if the initial ADD has not been ACKed
	 * or, in the case of processOnePendingRequestAtATime, if a prior request has not been ACKed/NAKed yet.
	 */
	private boolean _pending;
	/**
	 * _pendingRequests contains all pending requests keyed off of the clOrdId field.
	 */
	private final Map<String, OrderObj> _pendingRequests = new HashMap<>();
	private final Map<String, String> _childId2ParentIdMap = new HashMap<>();

	public final OrderObj _orderState;
	public final OrderObj _nakResponse;

	public int _level;
	private String _ordId;
	private int _nextChildId = 0;
	private int _nextReqVer = 0;
	private int _nextXReqVer = 0;

	private boolean _done; // this order is completed
	private long _doneCnt;

	public boolean _delSent = false;
	public boolean _delNaked = false;
	private DelNakRetryManager _delNakRetryManager;

	private final List<OrderObj> _queuedResponses = new ArrayList<>();

	private OrderObj _backupResponse;
	private final ArrayDeque<OrderObj> _deferredReqs = new ArrayDeque<>();
	/**
	 * _ackedClOrdId is only populated in case of failover; in this case it contains the 
	 * clOrdId of the 'state' record and only if the state contains an 'ACKed' record 
	 * (any state but NULL_VAL); it is used to not ACK/NAK a request it if has already
	 * been ACKed.
	 */
	private String _ackedClOrdId;
	public double _filledBeforeFailover = 0.0;

	private String _latestAckedXClOrdId;


	public OrderHandler(int parentLevel) {
		this(null, parentLevel);
	}

	public OrderHandler(OrderObj state, int parentLevel) {
		_level = parentLevel+1;
		if (state == null) {
			_orderState = new OrderObj();
			_nakResponse = new OrderObj();
		} else {
			_orderState = new OrderObj(state);
			_nakResponse = new OrderObj(state);
		}

		_orderState.setMadrigalMode(RESPONSE);
		_nakResponse.setMadrigalMode(RESPONSE);
		_nakResponse.setStatus(NAK);
		_nakResponse.resetLast();
	}

	public void set(RootOrderHandler rootHandler, IOrderResponseHandler parent, IOrderHandlerStrategy strategy, String ordId) {
		_rootHandler = rootHandler;
		_parent = parent;
		_strategy = strategy;
		if (_strategy == _rootHandler.getNativeStrategy()) { // can set for all types though
			_delNakRetryManager = new DelNakRetryManager(_rootHandler.getDelRetryType(), _rootHandler.getDelRetryConstant());
		}
		_ordId = ordId;
		_orderState.setUseNative(rootHandler.getImmutables().isUseNative());
		_nakResponse.setUseNative(rootHandler.getImmutables().isUseNative());
	}
	public void initCancelRetryLogic() {
		_delNakRetryManager.initCancelRetryLogic();
	}
	public boolean okToRetryCancel() {
		return _delNakRetryManager.okToRetryCancel();
	}

	public String newChildOrdId() {
		return _ordId+"~"+(_nextChildId++);
	}
	public int newReqVer() {
		return _nextReqVer++;
	}
	public void setReqVer(int nextReqVer) {
		_nextReqVer= nextReqVer;
	}
	public String getAndMapNextXClOrdId(String parentClOrdId) {
		String xClOrdId = _ordId + "-" + _nextXReqVer++;
		mapChildId2ParentId(xClOrdId, parentClOrdId);
		return xClOrdId;
	}
	public OrderHandler newChildOrderHandler(OrderObj childRequest, String parentClOrdId, IOrderHandlerStrategy strategy) {
		String childOrdId = childRequest.getOrdId();
		OrderHandler childHandler = new OrderHandler(_level); // TODO use managed object instead
		childHandler.set(_rootHandler, this, strategy, childOrdId);
		_childrenHandlers.add(childHandler);
		childRequest.setIds(childHandler.newReqVer());
		mapChildId2ParentId(childRequest.getClOrdId(), parentClOrdId);
		return childHandler;
	}

	private OrderObj newRequest0(MadrigalReqType reqType, String ordId, OrderObj sourceOrder) {
        OrderObj request = new OrderObj();
        request.setMeta(REQUEST, reqType);
        request.copyInvariants(sourceOrder);
        request.copyRequestGoal(sourceOrder);
        request.setIds(ordId);
		request.setTs(System.currentTimeMillis());
		request.setUseNative(sourceOrder.isUseNative());
		return request;
    }

	public OrderObj newAddRequest(String ordId, OrderObj sourceOrder) {
		return newRequest0(ADD, ordId, sourceOrder);
    }

	public OrderObj newRequest(MadrigalReqType reqType, String ordId, OrderObj sourceOrder, String parentClOrdId) {
    	OrderObj request = newRequest0(reqType, ordId, sourceOrder);
    	request.setIds(newReqVer());
		if (_parent instanceof OrderHandler) {
			((OrderHandler) _parent).mapChildId2ParentId(request.getClOrdId(), parentClOrdId);
		}
		return request;
    }

	public OrderObj newRwtRequest(double price, double qty, double shownQty, String parentClOrdId) {
		OrderObj request = new OrderObj(_orderState);
		request.setMeta(REQUEST, RWT);
		request.resetLast();
		request.resetCumulatives();
		request.setPrice(price);
		request.setOrderQty(qty);
		request.setShownQty(shownQty);
		request.setIds(newReqVer());
		request.setTs(System.currentTimeMillis());
		if (_parent instanceof OrderHandler) {
			((OrderHandler) _parent).mapChildId2ParentId(request.getClOrdId(), parentClOrdId);
		}
		return request;
	}

	private OrderObj newRequestFromState() {
		OrderObj request = new OrderObj(_orderState);
		request.setMadrigalMode(REQUEST);
		request.resetLast();
		request.resetCumulatives();
		return request;
	}




	@Override // IOrderRequestHandler
	public void handleAddRequest(OrderObj request) {
		if (log.isDebugEnabled()) log.info("{} handleAddRequest {} {}", _level, _strategy.getLabel(), request);
		_orderState.copyInvariants(request);
		_orderState.copyIds(request);
		_nakResponse.copyInvariants(request);
		_nakResponse.copyIds(request);

		if (_filledBeforeFailover == 0) {
			_orderState.copyRequestGoal(request);
			_nakResponse.copyRequestGoal(request);
			_orderState.resetCumulatives();
			_nakResponse.resetCumulatives();
		}

		String invalidMsg = _strategy.validateAddRequest(request, this);
		if (invalidMsg!=null) {
			enqueueNakResponse(request, invalidMsg, true);
		} else {
			_pending = true;
			pend(request);
			_strategy.handleAddRequest(request, this);
		}
		handleQueuedAcksNaks();
	}
	@Override // IOrderRequestHandler
	public void handleRwtRequest(OrderObj request) {
		if (log.isDebugEnabled()) log.info("{} handleRwtRequest {} {}", _level, _strategy.getLabel(), request);
		String invalidMsg = _strategy.validateRwtRequest(request, this);
		if (invalidMsg!=null || _delSent || _orderState.isDone()) {
			invalidMsg = (invalidMsg!=null) ? invalidMsg : (_delSent) ? VAL_ERR_STRING_DEL_ALREADY_SENT : VAL_ERR_STRING_ALREADY_COMPLETED;
			enqueueNakResponse(request, invalidMsg, _orderState.isDone());
		} else {
			double requested = request.getOrderQty();
			double filled = _orderState.getCumQty();
			if (requested < filled) {
				if (_strategy.isStrictRwt()) { // rejecting the request
					request.setDone(false);
					request.setStatus(NAK);
					request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
					enqueueAckNakResponse(request);
				} else {
					if (!delAllChildren(request)) {
						// there were no child orders, so accepting the request now
		    			request.setDone(true);
	    				request.setStatus(ACK);
						request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE); // expect overfill
						enqueueAckNakResponse(request);
					} else {
						// attempting to DEL child orders
						pend(request);
					}
				}
			} else if (requested == filled) {
				if (!delAllChildren(request)) {
					// there were no child orders, so accepting the request now
	    			request.setDone(true);
    				request.setStatus(ACK);
					enqueueAckNakResponse(request);
				} else {
					// attempting to DEL child orders
					pend(request);
				}
			} else { // requested > filled
				if (_pending) {
					enqueueRequest(request);
				} else {
					if (_strategy.isProcessOnePendingRequestAtATime()) {
						_pending = true;
					}
					pend(request);
					_strategy.handleRwtRequest(request, this);
				}
			}
		}
		handleQueuedAcksNaks();
	}
	@Override // IOrderRequestHandler
	public void handleDelRequest(OrderObj request) {
		handleDelRequest(request, false);
		handleQueuedAcksNaks();
	}
	private void handleDelRequest(OrderObj request, boolean failFast) {
		if (log.isDebugEnabled()) log.info("{} handleDelRequest {} {} {}", _level, _strategy.getLabel(), failFast, request);
		String invalidMsg = _strategy.validateDelRequest(request, this);
		if (invalidMsg!=null || _delSent || _orderState.isDone()) {
			invalidMsg = (invalidMsg!=null) ? invalidMsg : (_delSent) ? VAL_ERR_STRING_DEL_ALREADY_SENT : VAL_ERR_STRING_ALREADY_COMPLETED;
			if (!failFast) {
				enqueueNakResponse(request, invalidMsg, _orderState.isDone());
			} else {
				log.info("{} {}", _level, invalidMsg);
			}
		} else {
			if (_pending) {
				enqueueRequest(request);
			} else {
				_delSent = true;
				if (_strategy.isProcessOnePendingRequestAtATime() && !failFast) {
					_pending = true;
				}
				pend(request);
				_strategy.handleDelRequest(request, this);
			}
		}
	}
	@Override // IOrderResponseHandler
	public void handleResponse(OrderObj response) {
		OrderObj parentResponse = (isInFailFastMode()) ? windDownOrder(response) : _strategy.handleResponse(response, this);
		// parentResponse is null, or _orderState, or _nakResponse
		boolean handleQueuedRequests = false;

		if (log.isDebugEnabled()) log.info("{} handleResponse {} {}", _level, _strategy.getLabel(), parentResponse);

		if (parentResponse!=null) {
			MadrigalOrdStatus parentStatus = parentResponse.getStatus();
			if (ACK == parentStatus || NAK == parentStatus) {
				parentResponse.resetLast(); // lastQty, lastPx
				parentResponse.copyResponseDetails(response); // ecnOrdId, ts, tsx
				if (_strategy != _rootHandler.getNativeStrategy() && _strategy != _rootHandler.getResumeOnFailoverStrategy()) {
					parentResponse.setEcnOrdId(null);
				}
				handleQueuedRequests = true;
			}

			if (ACK == parentStatus && parentResponse.getClOrdId().equals(_ackedClOrdId)) {
				// I am about to ACK the parent but the parent has already been ACKed
			} else {
				updateDone();
				_parent.handleResponse(parentResponse);
			}

			if (handleQueuedRequests) {
				handleQueuedRequests(response); // this potentially overwrites parentResponse / _orderState / _nakResponse
			}
		}
		handleQueuedAcksNaks();
		if (parentResponse!=null) {
			if (parentResponse.isDone() && !anyChildPending()) {
				rejectAllQueuedRequests();
			}
		}
	}
	private void handleQueuedRequests(OrderObj childResponse) {
		if (!isInFailFastMode()) {
			if (ADD == childResponse.getReqType()) {
				if (ACK == childResponse.getStatus()) {
					if (_strategy.isProcessOnePendingRequestAtATime()) {
						activateNextQueuedRequest();
					} else {
						activateAllQueuedRequests();
					}
				} else { // NAK
					rejectAllQueuedRequests();
				}
			} else { // RWT or DEL
				if (!anyChildPending()) {
					if (_strategy.isProcessOnePendingRequestAtATime()) {
						activateNextQueuedRequest();
					} else {
						activateAllQueuedRequests();
					}
				}
			}
		}
	}

	private void mapChildId2ParentId(String childClOrdId, String parentClOrdId) {
		if (log.isTraceEnabled()) log.info("{} ~~~~~ map {} -> {}", _level, childClOrdId, parentClOrdId);
		_childId2ParentIdMap.put(childClOrdId, parentClOrdId);
	}
	private String unmapChildId(String childClOrdId) {
		String parentClOrdId = _childId2ParentIdMap.remove(childClOrdId);
		if (log.isTraceEnabled()) log.info("{} ~~~ unmap {} => {}", _level, childClOrdId, parentClOrdId);
		return parentClOrdId;
	}

	public EcnPriceObj registerAsPriceListener() {
		return _rootHandler.getService().registerPriceListener(this._orderState.getInstrId(), this);
	}
	public void unRegisterAsPriceListener() {
		_rootHandler.getService().unRegisterPriceListener(this._orderState.getInstrId(), this);
	}
	public void handleEcnPrice(EcnPriceObj ecnPrice) {
		if (nothingPending()) _strategy.handleEcnPrice(ecnPrice, this, _orderState);
	}

	public void enqueueAckNakResponse(OrderObj response) {
		response.startUsing();
		_queuedResponses.add(response);
	}
	public void enqueueNakResponse(OrderObj response, String text, boolean done) {
		response.setStatus(NAK);
		response.setText(text);
		response.setDone(done);
		enqueueAckNakResponse(response);
	}

	private void handleQueuedAcksNaks() {
		if (_queuedResponses.size()>0) {
			for (int i=0; i<_queuedResponses.size(); i++) {
				OrderObj order = _queuedResponses.get(i);
				MadrigalOrdStatus status = order.getStatus();
				if (ACK == status) {
					ackParent(order);
				} else {
					nakParent(order);
				}
				order.stopUsing();
			}
			_queuedResponses.clear();
		}
	}

	public boolean nothingPending() {
		return _pendingRequests.isEmpty();
	}

	public OrderObj myOnePendRequest() {
		if (nothingPending()) return null;
		return _pendingRequests.values().iterator().next();
	}

	public void pend(OrderObj request) {
		_pendingRequests.put(request.getClOrdId(), request);
		if (log.isTraceEnabled()) log.info("{} ***** pend {} => {}", _level, request.getClOrdId(), _pendingRequests.keySet());
	}

	public boolean unPendMapped(OrderObj intoParentResponse, OrderObj fromChildResponse) {
		return unPend(intoParentResponse, fromChildResponse, unmapChildId(fromChildResponse.getClOrdId()));
	}

	public boolean unPend(OrderObj intoParentResponse, OrderObj fromChildResponse) {
		return unPend(intoParentResponse, fromChildResponse, fromChildResponse.getClOrdId());
	}

	private boolean unPend(OrderObj intoParentResponse, OrderObj fromChildResponse, String parentClOrdId) {
		if (log.isTraceEnabled()) log.info("{} *** unPend {} from {}", _level, parentClOrdId, _pendingRequests.keySet());
		OrderObj pendingRequest = _pendingRequests.remove(parentClOrdId);
		if (pendingRequest!=null) {
			_pending = false;

			intoParentResponse.setReqType(pendingRequest.getReqType());
			intoParentResponse.copyIds(pendingRequest);
			if (DEL != pendingRequest.getReqType()) { // pending DEL does not contain full goal
				intoParentResponse.copyRequestGoal(pendingRequest);
			}
			intoParentResponse.resetLast();
			intoParentResponse.updateCumulatives();
			intoParentResponse.copyResponseDetails(fromChildResponse);
			intoParentResponse.setText(fromChildResponse.getText());
			pendingRequest.stopUsing();
			return true;
		} else {
			log.info("{} No pending request for {}. Could not unPend.", _level, parentClOrdId);
			return false;
		}
	}

	public boolean unPend(OrderObj order) {
		String clOrdId = order.getClOrdId();
		if (log.isTraceEnabled()) log.info("{} ooo unPend {} from {}", _level, clOrdId, _pendingRequests.keySet());
		OrderObj removed = _pendingRequests.remove(clOrdId);
		if (removed != null) {
			_pending = false;
			return true;
		} else {
			log.info("{} No pending request for {}. Could not unPend.", _level, clOrdId);
			return false;
		}
	}

	public void saveLatestAckedXClOrdId(OrderObj intoResponse) {
		_latestAckedXClOrdId = intoResponse.getClOrdId();
	}
	public String getLatestAckedXClOrdId() {
		return _latestAckedXClOrdId;
	}


	public void finalizeHandler() {
		if (log.isDebugEnabled()) log.info("{} finalizeHandler {} {}", _level, _strategy.getLabel(), _orderState);
		if (!_orderState.isDone()) {
			log.error("{} finalizeHandler: Order is NOT 'done' {}", _level, _orderState);
		}

		if (_strategy == _rootHandler.getNativeStrategy()) { // leaf node
			_rootHandler.getService().getLeafHandlers().remove(_orderState.getOrdId());
		} else {
			for (OrderHandler childHandler : _childrenHandlers) {
				childHandler.finalizeHandler();
			}
			_childrenHandlers.clear();
		}
	}


	private void enqueueRequest(OrderObj request) {
		if (log.isDebugEnabled()) log.info("{} enqueueRequest {}", _level, request);
		if (_strategy.isConflateRequests()) {
			if (_queuedReqs.isEmpty()) {
				request.startUsing();
				_queuedReqs.add(request);
			} else { // only one outstanding request in this case
                OrderObj queuedRequest = _queuedReqs.get(0);
                switch (queuedRequest.getReqType()) {
                case ADD:
                case RWT:
                	_queuedReqs.remove(0);
            		request.startUsing();
                    _queuedReqs.add(request);
                    if (!queuedRequest.getClOrdId().equals(_ackedClOrdId)) {
                        // publish NAK for queued request
	                    queuedRequest.setStatus(NAK);
	                    queuedRequest.setText(queuedRequest.getReqType() + VAL_ERR_STRING_SUPERSEDED);
	                    enqueueAckNakResponse(queuedRequest);
                    }
    				queuedRequest.stopUsing();
    				break;
                case DEL:
                    // publish NAK for new request
                	request.setStatus(NAK);
                    request.setText(VAL_ERR_STRING_PENDING_DEL);
                    enqueueAckNakResponse(request);
    				request.stopUsing();
    				break;
				default:
					break;
                }
			}
		} else {
			request.startUsing();
			_queuedReqs.add(request);
		}
	}
	public void activateNextQueuedRequest() {
    	if (!_queuedReqs.isEmpty()) {
			OrderObj request = _queuedReqs.remove(0);
			if (log.isDebugEnabled()) log.info("{} activateNextQueuedRequest {}", _level, request);

            switch (request.getReqType()) {
            case ADD: // resumeOnFailover only
            	handleAddRequest(request);
            	break;
            case RWT:
            	handleRwtRequest(request);
            	break;
            case DEL:
            	request.setOrderQty(_orderState.getOrderQty());
            	request.setShownQty(_orderState.getShownQty());
            	request.setPrice(_orderState.getPrice());
            	if (!allChildrenCompleted()) { // there is a child that is active
	            	handleDelRequest(request);
            	} else {
	    			request.setMadrigalMode(RESPONSE);
	    			request.setStatus(ACK);
	    			request.setDone(true);
	    			enqueueAckNakResponse(request);
            	}
            	break;
			default:
				break;
            }
            request.stopUsing();
    	}
	}
	public void activateAllQueuedRequests() {
		while (!_queuedReqs.isEmpty()) {
			OrderObj request = _queuedReqs.remove(0);
			if (log.isDebugEnabled()) log.info("{} activateAllQueuedRequests {}", _level, request);
            MadrigalReqType reqType = request.getReqType();
            if (RWT == reqType) {
            	handleRwtRequest(request);
            } else {
            	handleDelRequest(request);
            }
            request.stopUsing();
		}
	}
	public void rejectAllQueuedRequests() {
		rejectAllQueuedRequests(VAL_ERR_STRING_ALREADY_COMPLETED);
	}
	public void rejectAllQueuedRequests(String text) {
		updateDone(true);
		while (!_queuedReqs.isEmpty()) {
			OrderObj request = _queuedReqs.remove(0);
			if (log.isDebugEnabled()) log.info("{} rejectAllQueuedRequests {}", _level, request);
			request.setStatus(NAK);
			request.setDone(true);
			request.setText(text);
			enqueueAckNakResponse(request);
			request.stopUsing();
		}
	}


	public void updateDone(boolean done) {
		_done |= done;
	}
	public void updateDone() {
		if (_done) _doneCnt++;
		boolean ftDone = _doneCnt==1;
		_orderState.setDone(_done);
		_orderState.setFtDone(ftDone);
		_nakResponse.setDone(_done);
		_nakResponse.setFtDone(ftDone);
		if (ftDone) {
			_strategy.onFtDone(this);
		}
	}


	public void completeParent(boolean done) {
		updateDone(done);
		long now = System.currentTimeMillis();
		_orderState.setTs(now);
		_nakResponse.setTs(now);
	}

	private void ackParent(OrderObj order) {
		_orderState.setStatus(ACK);
		_orderState.setReqType(order.getReqType());
		_orderState.copyIds(order);
		if (DEL != order.getReqType()) {
			_orderState.copyRequestGoal(order);
		}
		_orderState.resetLast();
		_orderState.copyResponseDetails(order);
		_orderState.updateCumulatives();
		updateDone(order.isDone());
		updateDone();
		_orderState.setText(order.getText());
		_parent.handleResponse(_orderState);
	}

	private void ackParent() {
		_orderState.setStatus(ACK);
		_orderState.resetLast();
		_orderState.updateCumulatives();
		_parent.handleResponse(_orderState);
	}

	private void nakParent(OrderObj order) {
		_nakResponse.setReqType(order.getReqType());
		_nakResponse.copyIds(order);
		if (order.getReqType() == DEL) {
			_nakResponse.copyRequestGoal(_orderState);
		} else {
			_nakResponse.copyRequestGoal(order);
		}
		_nakResponse.updateCumulatives(_orderState);
		_nakResponse.setText(order.getText());
		_orderState.copyResponseDetails(order);
		_nakResponse.setEcnOrdId(VAL_EMPTY_STRING);
		_nakResponse.setTs(System.currentTimeMillis());
		_nakResponse.setTsx(0);
		updateDone(order.isDone());
		updateDone();
		_parent.handleResponse(_nakResponse);
	}

	private void cxlParent(String text) {
		log.info("{} Sending unsolicited cancel to client with text: {}", _level, text);

		_orderState.setStatus(CXL);
		_orderState.resetLast();
		_orderState.updateCumulatives();
		_orderState.setText(text);
		_orderState.setTs(System.currentTimeMillis());
		updateDone(true);
		updateDone();
		_parent.handleResponse(_orderState);
	}

	public boolean allChildrenCompleted() {
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
    		if (!childHandler._done) return false;
		}
    	return true;
	}

	public boolean anyChildPending() {
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
    		if (!childHandler.nothingPending()) return true;
		}
    	return false;
    }

	public void addToDeferredReqsHead(OrderObj request) {
		if (request!=null) {
			_deferredReqs.offerFirst(request);
			if (log.isDebugEnabled()) log.info("{} addToDeferredReqsHead {}", _level, request);
			request.startUsing();
		}
	}
	public void addToDeferredReqsTail(OrderObj request) {
		if (request!=null) {
			_deferredReqs.offerLast(request);
			if (log.isDebugEnabled()) log.info("{} addToDeferredReqsTail {}", _level, request);
			request.startUsing();
		}
	}
	public OrderObj removeDeferredReq() {
		OrderObj request = _deferredReqs.pollFirst();
		if (request != null) request.stopUsing();
		if (log.isDebugEnabled()) log.info("{} removeDeferredReq {}", _level, request);
		return request;
	}

	public int activeChildrenCount() {
		int cnt = 0;
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done) {
				cnt++;
			}
		}
		return cnt;
	}

	public boolean delAllChildren(OrderObj request) {
		boolean newReq = false;
		log.info("{} delAllChildren {}", _level, request);
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done && !childHandler._delSent) { // TODO what about pending
				newReq = true;

				OrderObj childRequest = childHandler.newRequest(DEL, childHandler._ordId, childHandler._orderState, request.getClOrdId());

				childHandler.handleDelRequest(childRequest);
			}
		}
		return newReq;
	}

	public boolean rwtAllChildren(OrderObj request) {
		boolean newReq = false;
		log.info("{} rwtAllChildren {}", _level, request);
		double price = request.getPrice();
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done && !childHandler._delSent) { // TODO what about pending
				newReq = true;

				OrderObj childRequest = childHandler.newRequest(RWT, childHandler._ordId, childHandler._orderState, request.getClOrdId());
		        childRequest.setPrice(price);

		        childHandler.handleRwtRequest(childRequest);
			}
		}
		return newReq;
	}

	public boolean rwtNewestChild(OrderObj request, double addition, boolean priceChange) {
		boolean newReq = false;
		log.info("{} rwtNewestChild {} {} {}", _level, request, addition, priceChange);
		double price = request.getPrice();
		for (int i=_childrenHandlers.size()-1; i>=0; i--) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done && !childHandler._delSent) {
				if (!newReq) {
					newReq = true;
					OrderObj childRequest = childHandler.newRequest(RWT, childHandler._ordId, childHandler._orderState, request.getClOrdId());
			        childRequest.setOrderQty(childRequest.getOrderQty() + addition);
			        childRequest.setShownQty(childRequest.getShownQty() + addition);
			        childRequest.setPrice(price);
			        childHandler.handleRwtRequest(childRequest);
			        if (!priceChange) break;
				} else {
					OrderObj childRequest = childHandler.newRequest(RWT, childHandler._ordId, childHandler._orderState, request.getClOrdId());
			        childRequest.setPrice(price);

			        childHandler.handleRwtRequest(childRequest);
				}
			}
		}
		return newReq;
	}

	public boolean delRwtChildren(OrderObj request, boolean priceChange) {
		boolean newReq = false;
		double active = getActiveQty();
		double filled = _orderState.getCumQty();
		log.info("{} delRwtChildren {} {} {} {}", _level, active, filled, priceChange, request);
		double reduction = Math.max(active - request.getShownQty(), filled + active - request.getOrderQty());
		//RWT the order by possibly DELeting some children and RWTing one child
		for (int i=_childrenHandlers.size()-1; i>=0; i--) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done) {
				if (reduction <= 0.0) { // the necessary number of children have been canceled and amended to bring the size to the desired one
					if (priceChange) { // will need to traverse the remaining children and amend them only if there is a price change
						newReq = true;
						OrderObj childRequest = childHandler.newRequest(RWT, childHandler._ordId, childHandler._orderState, request.getClOrdId());
				        childRequest.setPrice(request.getPrice());
				        childHandler.handleRwtRequest(childRequest);
				        continue;
					} else {
						break;
					}
				}
				double childLeavesQty = childHandler._orderState.getLeavesQty();
				if (reduction >= childLeavesQty) {
					newReq = true;
					OrderObj childRequest = childHandler.newRequest(DEL, childHandler._ordId, childHandler._orderState, request.getClOrdId());
					reduction -= childLeavesQty;
					childHandler.handleDelRequest(childRequest);
				} else {
					newReq = true;
					double newQty = childHandler._orderState.getOrderQty() - reduction;
					reduction = 0.0;
					OrderObj childRequest = childHandler.newRequest(RWT, childHandler._ordId, childHandler._orderState, request.getClOrdId());
			        childRequest.setOrderQty(newQty);
			        childRequest.setShownQty(newQty);
			        childRequest.setPrice(request.getPrice());
			        childHandler.handleRwtRequest(childRequest);
				}
			}
		}
		return newReq;
	}

	/**
	 * Fail Fast logic.
	 * - order handler goes into fail fast mode whenever it encounters a situation which is not prepared to handle.
	 * - once in fail fast mode a handler stays in fail fast mode until completion.
	 * - if multiple fail fast situations occur, only the first one is handled; all others are logged but ignored.
	 * - when entering fail fast mode the handler tries to cancel all active children.
	 * - these cancel requests may be un-handle-able in which case the child order may get filled. This is acceptable.
	 * - while in fail fast mode all responses are handled as usual but no new child order is placed (this ensures termination).
	 * - while in fail fast mode all new requests are rejected up front.
	 */
	private String _failFastErrorText = null; // initially null, set the first time order goes into FailFast mode and never changes again

	private boolean isInFailFastMode() {
		return _failFastErrorText != null;
	}

	public OrderObj setInFailFastMode(OrderObj parentEr) {
		String errorText = parentEr.getText();
    	if (isInFailFastMode()) {
    		// already in FailFast mode
    		log.warn("{} Multiple failures... Received '{}' while handling '{}'", _level, errorText, _failFastErrorText);
        	return null;
    	} else {
    		log.info("{} failFast mode '{}'", _level, errorText);
    		_failFastErrorText = errorText;
    		for (int i=0; i<_childrenHandlers.size(); i++) {
    			OrderHandler childHandler = _childrenHandlers.get(i);
    			if (!childHandler._done) {
    				if (!childHandler._delSent && !childHandler._delNaked) {
            			OrderObj childRequest = childHandler.newRequest(DEL, childHandler._ordId, childHandler._orderState, _nakResponse.getClOrdId());

    			        childHandler.handleDelRequest(childRequest, true);
    				}
    			}
    		}
			completeParent(allChildrenCompleted());
			return parentEr;
    	}
    }

	private OrderObj windDownOrder(OrderObj response) {
		log.info("{} windDownOrder {}", _level, response);

		MadrigalOrdStatus status = response.getStatus();
		if (status == ACK || status == NAK || (status == DONE && response.getLastQty() == 0.0)) {
			if (allChildrenCompleted()) {
				_orderState.setStatus(DONE);
				_orderState.resetLast();
				_orderState.setText(VAL_ERR_STRING_FAIL_FAST);
				completeParent(true);
				return _orderState;
			}
			return null;
		}

		// FILL or DONE
		_orderState.setStatus(FILL);
		_orderState.updateFillDetails(response);
		_orderState.copyResponseDetails(response);
		_orderState.setText(VAL_ERR_STRING_FAIL_FAST);
		_orderState.setEcnOrdId(null);
		completeParent(allChildrenCompleted());
		return _orderState;
	}

	public double getFillableQty() { // the maximum size that could be filled by the current children
		double fillable = 0.0;
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (childHandler._done) {
				fillable += childHandler._orderState.getCumQty(); // can be < orderQty, e.g., for IOC orders
			} else {
				fillable += childHandler._orderState.getOrderQty();
			}
		}
		return fillable;
	}

	public double getActiveQty() { // the active quantity in the market from all children
		double active = 0.0;
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
			if (!childHandler._done) {
				active += childHandler._orderState.getLeavesQty();
			}
		}
		return active;
	}

	public boolean anySiblingPending(String clOrdId) {
		boolean result = anyChildPendingExcept(clOrdId);
		log.info("{} anySiblingPending {}=>{}", _level, clOrdId, result);
		return result;
	}
	private boolean anyChildPendingExcept(String clOrdId) {
		for (int i=0; i<_childrenHandlers.size(); i++) {
			OrderHandler childHandler = _childrenHandlers.get(i);
    		if (!childHandler._ordId.equals(clOrdId)) {
    			if (!childHandler.nothingPending()) return true;
    		}
		}
    	return false;
    }

	public void backupResponse(OrderObj response) {
		if (_backupResponse==null) {
			_backupResponse = new OrderObj(response);
		} else {
			_backupResponse.set(response);
		}
	}
	public void transferAndRestore(OrderObj from, OrderObj to) {
		to.set(from);
		from.set(_backupResponse);
	}


	public void activateOrder(List<OrderObj> queuedList, Collection<OrderObj> fills) {
		// the current state now resides in _orderState
		// first handle the un-processed fills
		if (!fills.isEmpty()) {
			if (orderIsNotAcked()) {
				OrderObj req = queuedList.get(0);
				if (req.getReqType() == ADD) { // this should always be true
					queuedList.remove(0);
				}
				ackParent();
			}
			fills.forEach(fill -> applyUnprocessedFill(fill));
		}

		if (_orderState.isDone()) { // order is fully filled (eventually after applying the unprocessed fills)
			queuedList.forEach(request -> { // enqueue any requests that were received while disconnected
				request.setTimeInForce(_rootHandler.getImmutables().getTif());
				request.setSide(_rootHandler.getImmutables().getSide());
				enqueueRequest(request);
			});

			rejectAllQueuedRequests();
			_rootHandler.getService().finalizeHandler(_orderState.getOrdId());
		} else { // order is in the range: not ACKed to partially filled
			if (cancelOnActivate()) {
				queuedList.forEach(request -> { // enqueue any requests that were received while disconnected
					request.setTimeInForce(_rootHandler.getImmutables().getTif());
					request.setSide(_rootHandler.getImmutables().getSide());
					enqueueRequest(request);
				});

				if (orderIsNotAcked()) {
					rejectAllQueuedRequests("due to failover");
				} else { // order has been ACKed but not fully filled
					rejectAllQueuedRequests();
					cxlParent("cancel on failover");
				}
			} else { // resume on activate
				if (!orderIsNotAcked()) _ackedClOrdId = _orderState.getClOrdId();
				_filledBeforeFailover = _orderState.getCumQty();
				_strategy = _rootHandler.getResumeOnFailoverStrategy(); // override the handler strategy

				OrderObj request = newRequestFromState();
				if (log.isDebugEnabled()) log.info("{} activateOrder {}", _level, request);
				enqueueRequest(request); // enqueue the current state/request
				queuedList.forEach(req -> { // enqueue any requests that were received while disconnected
					if (req.getReqType() != ADD) {
						req.setTimeInForce(_rootHandler.getImmutables().getTif());
						req.setSide(_rootHandler.getImmutables().getSide());
						enqueueRequest(req); // => activateNextQueuedRequest
					}
				});

				activateNextQueuedRequest(); // b/c ResumeOnFailoverStrategy.processOnePendingRequestAtATime == true
			}
		}
		handleQueuedAcksNaks();
	}

	private void applyUnprocessedFill(OrderObj fill) {
		if (log.isDebugEnabled()) log.info("{} applyUnprocessedFill {}", _level, fill);

		// apply the fill's details to parentResponse
		_orderState.updateFillDetails(fill);
		_orderState.copyResponseDetails(fill);
		_orderState.setText(VAL_EMPTY_STRING);
		_orderState.setStatus(MadrigalOrdStatus.FILL);

		boolean done = _orderState.getLeavesQty()<=0.0;
		_orderState.setDone(done);
		updateDone(done);

		updateDone();
		_parent.handleResponse(_orderState);
	}
	private boolean orderIsNotAcked() {
		return _orderState.getStatus() == NULL_VAL;
	}
	private boolean cancelOnActivate() {
		// TODO use config and state to decide: (ALWAYS_CANCEL, ALWAYS_RESUME, RESUME_IF_RECENT)
		return _rootHandler.getService().getOmsParams().getActionOnFailover() == MadrigalActionOnFailover.ALWAYS_CANCEL;
	}


    public RootOrderHandler getRootHandler() {
    	return _rootHandler;
    }
	public boolean isDone() {
		return _done;
	}

	public EcnInstrumentObj getEcnInstr(String instrId) {
		return getRootHandler().getService().getInstrumentCache().getEcnInstr(instrId);
	}

	public String toString() {
		return "{"+_orderState+"}";
	}
}
