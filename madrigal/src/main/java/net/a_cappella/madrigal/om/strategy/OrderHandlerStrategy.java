package net.a_cappella.madrigal.om.strategy;

import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY;

public abstract class OrderHandlerStrategy implements IOrderHandlerStrategy {

	@Override
	public String getLabel() {
		return this.getClass().getSimpleName();
	}

	@Override
	public String validateAddRequest(OrderObj request, OrderHandler handler) {
		double qty = request.getOrderQty();
		if (request.getShownQty() > 0.0) qty = request.getShownQty();
		EcnInstrumentObj ecnInstr = handler.getRootHandler().getService().getInstrumentCache().getEcnInstr(request.getInstrId());
		return (qty < ecnInstr.getMinQty()) ? VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY : null;
	}

	@Override
	public String validateRwtRequest(OrderObj request, OrderHandler handler) {
		double qty = request.getOrderQty();
		if (request.getShownQty() > 0.0) qty = request.getShownQty();
		EcnInstrumentObj ecnInstr = handler.getRootHandler().getService().getInstrumentCache().getEcnInstr(request.getInstrId());
		return (qty < ecnInstr.getMinQty()) ? VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY : null;
	}

	@Override
	public String validateDelRequest(OrderObj request, OrderHandler handler) {
		return null;
	}

	@Override
	public void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj request) {
	}

	@Override
	public void onFtDone(OrderHandler handler) {
	}

}
