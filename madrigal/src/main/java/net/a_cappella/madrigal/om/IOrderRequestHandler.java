package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.obj.OrderObj;

public interface IOrderRequestHandler {
	void handleAddRequest(OrderObj request); // mode=REQUEST
	void handleRwtRequest(OrderObj request); // mode=REQUEST
	void handleDelRequest(OrderObj request); // mode=REQUEST
}
