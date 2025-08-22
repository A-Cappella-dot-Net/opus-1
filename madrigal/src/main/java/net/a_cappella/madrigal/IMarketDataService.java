package net.a_cappella.madrigal;

import net.a_cappella.madrigal.common.obj.*;

public interface IMarketDataService {
	void publishMarketStatus(MarketStatusObj marketStatus) throws Exception;
	void publishInstrument(EcnInstrumentObj ecnInstrument) throws Exception;
	void publishEcnPrice(EcnPriceObj ecnPrice) throws Exception;
	void publishEcnInstrStatus(EcnInstrStatusObj ecnInstrStatus) throws Exception;
	void publishEcnImbalance(EcnImbalanceObj ecnImbalance) throws Exception;
}
