package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.madrigal.common.constants.MadrigalGatewayType;
import net.a_cappella.madrigal.common.constants.MadrigalMarketStatus;
import net.a_cappella.madrigal.common.obj.MarketStatusObj;

public class CukeMarketStatus {
	String ecn;
	String gwt;
	String status;

	public CukeMarketStatus(String ecn, String gwt, String status) {
		this.ecn = ecn;
		this.gwt = gwt;
		this.status = status;
	}

	public String getEcn() {
		return ecn;
	}
	public String getGwt() {
		return gwt;
	}
	public String getStatus() {
		return status;
	}

	public MarketStatusObj of() {
		MarketStatusObj obj = new MarketStatusObj();
		obj.set(ecn, MadrigalGatewayType.valueOf(gwt), MadrigalMarketStatus.valueOf(status), System.currentTimeMillis());
		return obj;
	}
}
