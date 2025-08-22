package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;

public interface IOrderManagerAdaptor {
	void connectToExchange();
	void disconnectFromExchange();
	void sendNewOrderSingle(String uid, String clOrdID, String symbol, MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side, double px, double qtyShown, double qty);
	void sendOrderCancelRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, MadrigalSide side, double qty);
	void sendOrderCancelReplaceRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, double px, double qtyShown, double qty, MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side);
}
