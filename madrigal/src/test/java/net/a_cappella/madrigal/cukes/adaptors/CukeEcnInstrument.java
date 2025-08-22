package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;

public class CukeEcnInstrument {
    private final String securityID; // cusip
    private final String symbol; // exchange id
    private final double minPriceIncrement;
    private final double contractMultiplier;
    private final double minQty;
    private final double minQtyIncrement;

	private final String ecn;

	public CukeEcnInstrument(
			String securityID, String symbol,
			double minPriceIncrement, double contractMultiplier,
			double minQty, double minQtyIncrement,
			String ecn) {
		this.securityID = securityID;
		this.symbol = symbol;
		this.minPriceIncrement = minPriceIncrement;
		this.contractMultiplier = contractMultiplier;
		this.minQty = minQty;
		this.minQtyIncrement = minQtyIncrement;
		this.ecn = ecn;
	}

	public String getSecurityID() {
		return securityID;
	}
	public String getSymbol() {
		return symbol;
	}
	public double getMinPriceIncrement() {
		return minPriceIncrement;
	}
	public double getContractMultiplier() {
		return contractMultiplier;
	}
	public double getMinQty() {
		return minQty;
	}
	public double getMinQtyIncrement() {
		return minQtyIncrement;
	}
	public String getEcn() {
		return ecn;
	}

	public EcnInstrumentObj of() {
		EcnInstrumentObj instr = new EcnInstrumentObj();
		instr.set(securityID, symbol, 0, 0.0, contractMultiplier, minPriceIncrement, minQty, minQtyIncrement, ecn, 0);
		return instr;
	}
}
