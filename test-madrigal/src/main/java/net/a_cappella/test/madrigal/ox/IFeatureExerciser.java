package net.a_cappella.test.madrigal.ox;

import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.test.madrigal.ox.OrderExerciser.MDSnapshot;

public interface IFeatureExerciser {
	void setOx(OrderExerciser ox);
    MDSnapshot selectInstrMds();
    boolean selectOrderDetails(MDSnapshot mds);
    void set(String instrId, MadrigalSide side, double price);
    void evalState();
    String sendOrder();
    void handleResponse(OrderObj er);
}

