package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.obj.MarketStatusObj;
import net.a_cappella.madrigal.common.obj.OrderObj;

public interface IOrderManagerService {
	void publishMarketStatus(MarketStatusObj marketStatus) throws Exception;
	void publishResponse(OrderObj response);
}
