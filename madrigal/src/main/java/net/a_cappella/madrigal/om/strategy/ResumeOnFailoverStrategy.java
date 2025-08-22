package net.a_cappella.madrigal.om.strategy;

import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_STRING_ALREADY_COMPLETED;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_STRING_TOO_LATE_TO_REPLACE;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.IOC;

public class ResumeOnFailoverStrategy extends OrderHandlerStrategy {
    private static final Logger log = LoggerFactory.getLogger(ResumeOnFailoverStrategy.class);

	private final boolean _conflateRequests;
	@Override
	public boolean isConflateRequests() {
		return _conflateRequests;
	}

	@Override
	public boolean isProcessOnePendingRequestAtATime() {
		return true;
	}

	private final boolean _strictRwt;
	@Override
	public boolean isStrictRwt() {
		return _strictRwt;
	}

	public ResumeOnFailoverStrategy(boolean conflateRequests, boolean strictRwt) {
		_conflateRequests = conflateRequests;
		_strictRwt = strictRwt;
	}


	@Override
	public void handleAddRequest(OrderObj request, OrderHandler handler) {
		IOrderHandlerStrategy originalStrategy = handler.getRootHandler().getService().getOmsParams().getStrategy(handler.getRootHandler().getImmutables());

		OrderObj childRequest = handler.newAddRequest(handler.newChildOrdId(), request);
		childRequest.setOrderQty(childRequest.getOrderQty() - handler._filledBeforeFailover);
		childRequest.setShownQty(Math.min(childRequest.getOrderQty(), childRequest.getShownQty()));

		OrderHandler childHandler = handler.newChildOrderHandler(childRequest, request.getClOrdId(), originalStrategy);
        childHandler.handleAddRequest(childRequest);
	}

	@Override
	public void handleRwtRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleRwtRequest {}", handler._level, request);

		double newAdjustedQty = request.getOrderQty() - handler._filledBeforeFailover;

		List<OrderHandler> childrenHandlers = handler._childrenHandlers;
		if (childrenHandlers.isEmpty()) { // the ADD was superseded
			handler._orderState.copyRequestGoal(request);
			handler._nakResponse.copyRequestGoal(request);

			IOrderHandlerStrategy originalStrategy = handler.getRootHandler().getService().getOmsParams().getStrategy(handler.getRootHandler().getImmutables());

			if (newAdjustedQty > 0) {
				OrderObj childRequest = handler.newAddRequest(handler.newChildOrdId(), request);
				childRequest.setOrderQty(newAdjustedQty);
				childRequest.setShownQty(Math.min(childRequest.getOrderQty(), request.getShownQty()));

				OrderHandler childHandler = handler.newChildOrderHandler(childRequest, request.getClOrdId(), originalStrategy);
		        childHandler.handleAddRequest(childRequest);
			} else {
    			request.setMadrigalMode(RESPONSE);
    			request.setDone(true);
    			if (newAdjustedQty == 0) {
    				request.setStatus(ACK);
    			} else {
    				request.setStatus(NAK);
    				request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);
    			}
				handler.enqueueAckNakResponse(request);
			}
		} else {
			if (newAdjustedQty > 0) {
				OrderHandler childHandler = handler._childrenHandlers.get(0);

				OrderObj childRequest = childHandler.newRwtRequest(request.getPrice(), newAdjustedQty, Math.min(newAdjustedQty, request.getShownQty()), request.getClOrdId());

				childHandler.handleRwtRequest(childRequest);
			} else if (newAdjustedQty == 0) {
				handler.delAllChildren(request);
			} else { // newAdjustedQty < 0
				if (_strictRwt) {
	                handler.unPend(request);
					request.setDone(handler.allChildrenCompleted());
					request.setStatus(NAK);
					request.setText(VAL_ERR_STRING_TOO_LATE_TO_REPLACE);

					handler.enqueueAckNakResponse(request);
				} else {
					handler.delAllChildren(request);
				}
			}
		}
	}

	@Override
	public void handleDelRequest(OrderObj request, OrderHandler handler) {
		if (log.isDebugEnabled()) log.info("{} handleDelRequest {}", handler._level, request);

		// cancel all children
		handler.delAllChildren(request);
	}

	@Override
	public OrderObj handleResponse(OrderObj response, OrderHandler handler) {
		OrderObj orderState = handler._orderState;

		if (log.isDebugEnabled()) log.info("{} handleResponse {} {}", handler._level, orderState.getReqType(), response);

		switch (response.getStatus()) {
		case ACK:
			if (!handler.unPendMapped(orderState, response)) return null;

			MadrigalReqType reqType = orderState.getReqType(); // from the parent pending request

			orderState.resetLast();
			orderState.setText(response.getText());
			orderState.setStatus(ACK);

			switch (reqType) {
			case RWT:
			case DEL:
				handler.updateDone(response.isDone());
				break;
			default:
				break;
			}

			return orderState;
		case NAK:
			OrderObj nakResponse = handler._nakResponse;

			if (!handler.unPendMapped(nakResponse, response)) return null;
			nakResponse.setText(response.getText());

			reqType = nakResponse.getReqType(); // from the parent pending request

			switch (reqType) {
			case RWT:
				if (response.isDone()) {
					nakResponse.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
				}
				nakResponse.updateCumulatives(orderState);
				handler.updateDone(response.isDone());
				break;
			case DEL:
				if (IOC == response.getTimeInForce()) {
					// pass the nakResponse to parent as is
				} else if (response.isDone()) {
					nakResponse.setText(VAL_ERR_STRING_ALREADY_COMPLETED);
					nakResponse.copyRequestGoal(orderState);
					nakResponse.updateCumulatives(orderState);
					handler.updateDone(true);
				} else {
					log.error("{} DEL NAK should be handled differently. {} => {}", handler._level, handler, response);
				}
				break;
			default:
				break;
			}

			return nakResponse;
		default: // FILL or DONE
			orderState.updateFillDetails(response);
			orderState.copyResponseDetails(response);
			orderState.setText(response.getText());
			orderState.setStatus(response.getStatus());
			handler.updateDone(response.isDone());
			return orderState;
		}
	}

}
