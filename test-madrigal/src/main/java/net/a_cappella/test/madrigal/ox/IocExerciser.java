package net.a_cappella.test.madrigal.ox;

import net.a_cappella.test.madrigal.ox.OrderExerciser.MDSnapshot;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdType.LIMIT;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Sell;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.IOC;

public class IocExerciser extends AbstractFeatureExerciser {

    public IocExerciser(boolean useNative, String versionsSequence) {
    	super(useNative, versionsSequence);
    }

    @Override // IFeatureExerciser
    public MDSnapshot selectInstrMds() {
    	return _ox.roundRobinMds();
    }

    @Override // IFeatureExerciser
    public boolean selectOrderDetails(MDSnapshot mds) {
        String instrId = mds._instrId;
        double bid = mds._bid;
        double ask = mds._ask;
        double bidSize = mds._bidSize;
        double askSize = mds._askSize;

        if (_passive) { // buy at the bid, sell at the offer
            if (!Double.isNaN(bid) && !Double.isNaN(ask)) {
                if (bidSize>=askSize) {
                	set(instrId, Buy, bid);
                	return true;
                } else { // bidSize<askSize
                	set(instrId, Sell, ask);
                	return true;
                }
            } else if (!Double.isNaN(ask)) {
            	set(instrId, Sell, ask);
            	return true;
            } else if (!Double.isNaN(bid)) {
            	set(instrId, Buy, bid);
            	return true;
            }
        } else { // aggressive order: buy at the offer, sell at the bid
            if (!Double.isNaN(bid) && !Double.isNaN(ask)) {
                if (bidSize>=askSize) {
                	set(instrId, Sell, bid);
                	return true;
                } else { // bidSize<askSize
                	set(instrId, Buy, ask);
                	return true;
                }
            } else if (!Double.isNaN(ask)) {
            	set(instrId, Buy, ask);
            	return true;
            } else if (!Double.isNaN(bid)) {
            	set(instrId, Sell, bid);
            	return true;
            }
        }
        return false;
    }


    @Override // IFeatureExerciser
    public String sendOrder() {
    	return sendOrder(LIMIT, IOC);
    }

    public String toString() {
        return super.toString()+" passive="+_passive;
    }
}
