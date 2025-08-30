package net.a_cappella.test.madrigal.ox;

import net.a_cappella.test.madrigal.ox.OrderExerciser.MDSnapshot;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdType.LIMIT;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Sell;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.DAY;

public class RwtExerciser extends AbstractFeatureExerciser {

    public RwtExerciser(boolean useNative, String versionsSequence) {
    	super(useNative, versionsSequence);
    }

    @Override // IFeatureExerciser
    public boolean selectOrderDetails(MDSnapshot mds) {
        String instrId = mds._instrId;
        double bid = mds._bid;
        double ask = mds._ask;
        double bidSize = mds._bidSize;
        double askSize = mds._askSize;

        double minPriceTick = _ox.getMinPriceTick(instrId);

        if (!Double.isNaN(bid) && !Double.isNaN(ask)) {
            if (bidSize>=askSize) {
            	set(instrId, Sell, ask);
            	return true;
            } else { // bidSize<askSize
            	set(instrId, Buy, bid);
            	return true;
            }
        } else if (!Double.isNaN(ask)) {
        	set(instrId, Buy, ask-minPriceTick);
        	return true;
        } else if (!Double.isNaN(bid)) {
        	set(instrId, Sell, bid+minPriceTick);
        	return true;
        }
        return false;
    }

    @Override // IFeatureExerciser
    public String sendOrder() {
    	return sendOrder(LIMIT, DAY);
    }
}
