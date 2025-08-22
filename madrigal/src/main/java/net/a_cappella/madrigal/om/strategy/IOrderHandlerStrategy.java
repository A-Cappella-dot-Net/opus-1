package net.a_cappella.madrigal.om.strategy;

import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;

public interface IOrderHandlerStrategy {
	String getLabel();
	boolean isConflateRequests();
	boolean isProcessOnePendingRequestAtATime();
	boolean isStrictRwt();
	String validateAddRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	String validateRwtRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	String validateDelRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleAddRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleRwtRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleDelRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	OrderObj handleResponse(OrderObj er, OrderHandler handler); // mode=RESPONSE
	void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj request);
	void onFtDone(OrderHandler handler);
}
