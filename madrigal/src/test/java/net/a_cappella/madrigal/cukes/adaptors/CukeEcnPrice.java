package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.common.obj.EcnPriceObj;

public class CukeEcnPrice {
	private String ecn;
	private String instrId;

	private final double bid0 = Double.NaN;
	private final double bidSize0 = Double.NaN;
	private final double ask0 = Double.NaN;
	private final double askSize0 = Double.NaN;

	private final double bid1 = Double.NaN;
	private final double bidSize1 = Double.NaN;
	private final double ask1 = Double.NaN;
	private final double askSize1 = Double.NaN;

	private final double bid2 = Double.NaN;
	private final double bidSize2 = Double.NaN;
	private final double ask2 = Double.NaN;
	private final double askSize2 = Double.NaN;

	public String getEcn() {
		return ecn;
	}
	public String getInstrId() {
		return instrId;
	}
	public double getBid0() {
		return bid0;
	}
	public double getBidSize0() {
		return bidSize0;
	}
	public double getAsk0() {
		return ask0;
	}
	public double getAskSize0() {
		return askSize0;
	}
	public double getBid1() {
		return bid1;
	}
	public double getBidSize1() {
		return bidSize1;
	}
	public double getAsk1() {
		return ask1;
	}
	public double getAskSize1() {
		return askSize1;
	}
	public double getBid2() {
		return bid2;
	}
	public double getBidSize2() {
		return bidSize2;
	}
	public double getAsk2() {
		return ask2;
	}
	public double getAskSize2() {
		return askSize2;
	}

	public EcnPriceObj adapt() {
		EcnPriceObj price = new EcnPriceObj();
		price.setEcn((ecn==null)?"ecn":ecn);
		price.setInstrId((instrId==null)?"instrId":instrId);
		price.setBid0(bid0);
		price.setBidSize0(bidSize0);
		price.setBid1(bid1);
		price.setBidSize1(bidSize1);
		price.setBid2(bid2);
		price.setBidSize2(bidSize2);
		price.setOffer0(ask0);
		price.setOfferSize0(askSize0);
		price.setOffer1(ask1);
		price.setOfferSize1(askSize1);
		price.setOffer2(ask2);
		price.setOfferSize2(askSize2);
		price.setStale(false);
		return price;
	}

	@Override
	public String toString() {
		return "CukeEcnPrice [ecn=" + ecn + ", instrId=" + instrId + ", bid0="
				+ bid0 + ", bidSize0=" + bidSize0 + ", ask0=" + ask0
				+ ", askSize0=" + askSize0 + ", bid1=" + bid1 + ", bidSize1="
				+ bidSize1 + ", ask1=" + ask1 + ", askSize1=" + askSize1
				+ ", bid2=" + bid2 + ", bidSize2=" + bidSize2 + ", ask2="
				+ ask2 + ", askSize2=" + askSize2 + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		long temp;
		temp = Double.doubleToLongBits(ask0);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(ask1);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(ask2);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(askSize0);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(askSize1);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(askSize2);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bid0);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bid1);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bid2);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bidSize0);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bidSize1);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(bidSize2);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		result = prime * result + ((ecn == null) ? 0 : ecn.hashCode());
		result = prime * result + ((instrId == null) ? 0 : instrId.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		CukeEcnPrice other = (CukeEcnPrice) obj;
		if (Double.doubleToLongBits(ask0) != Double
				.doubleToLongBits(other.ask0))
			return false;
		if (Double.doubleToLongBits(ask1) != Double
				.doubleToLongBits(other.ask1))
			return false;
		if (Double.doubleToLongBits(ask2) != Double
				.doubleToLongBits(other.ask2))
			return false;
		if (Double.doubleToLongBits(askSize0) != Double
				.doubleToLongBits(other.askSize0))
			return false;
		if (Double.doubleToLongBits(askSize1) != Double
				.doubleToLongBits(other.askSize1))
			return false;
		if (Double.doubleToLongBits(askSize2) != Double
				.doubleToLongBits(other.askSize2))
			return false;
		if (Double.doubleToLongBits(bid0) != Double
				.doubleToLongBits(other.bid0))
			return false;
		if (Double.doubleToLongBits(bid1) != Double
				.doubleToLongBits(other.bid1))
			return false;
		if (Double.doubleToLongBits(bid2) != Double
				.doubleToLongBits(other.bid2))
			return false;
		if (Double.doubleToLongBits(bidSize0) != Double
				.doubleToLongBits(other.bidSize0))
			return false;
		if (Double.doubleToLongBits(bidSize1) != Double
				.doubleToLongBits(other.bidSize1))
			return false;
		if (Double.doubleToLongBits(bidSize2) != Double
				.doubleToLongBits(other.bidSize2))
			return false;
		if (ecn == null) {
			if (other.ecn != null)
				return false;
		} else if (!ecn.equals(other.ecn))
			return false;
		if (instrId == null) {
			if (other.instrId != null)
				return false;
		} else if (!instrId.equals(other.instrId))
			return false;
		return true;
	}

}
