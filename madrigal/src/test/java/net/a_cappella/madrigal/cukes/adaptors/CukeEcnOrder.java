/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.madrigal.cukes.adaptors;

import io.cucumber.java.DataTableType;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;

import java.util.Map;

import static net.a_cappella.madrigal.CukeUtils.*;

public class CukeEcnOrder {
    private final MadrigalReqType reqType; // {ADD,DEL,RWT}
	private String ecnUid;
	private final String clOrdID;
	private String symbol;
	private MadrigalOrdType ordType;
    private MadrigalTimeInForce tif;
    private final MadrigalSide side;
    private Double px;
    private final double qty;
    private Double shownQty;
    private String ecnOrdId;
	private String origClOrdId;

	@DataTableType
	public static CukeEcnOrder cukeEcnOrder(Map<String, String> entry) {
		return new CukeEcnOrder(
				parseMadrigalReqType(entry.get("reqType")), // {ADD,DEL,RWT}
				entry.get("ecnUid"),
				entry.get("clOrdID"),
				entry.get("symbol"),
				parseMadrigalOrdType(entry.get("ordType")),
				parseMadrigalTimeInForce(entry.get("tif")),
				MadrigalSide.valueOf(entry.get("side")),
				parseDoubleNaN(entry.get("px")),
				parseDouble(entry.get("qty")),
				parseDoubleNaN(entry.get("shownQty")),
				entry.get("ecnOrdId"),
				entry.get("origClOrdId")
		);
	}

	public CukeEcnOrder(
            MadrigalReqType reqType, // {ADD,DEL,RWT}
            String ecnUid,
            String clOrdID,
            String symbol,
            MadrigalOrdType ordType,
            MadrigalTimeInForce tif,
            MadrigalSide side,
            Double px,
            double qty,
            Double shownQty,
            String ecnOrdId,
            String origClOrdId
    ) {
        this.reqType = reqType; // {ADD,DEL,RWT}
        this.ecnUid = ecnUid;
        this.clOrdID = clOrdID;
        this.symbol = symbol;
        this.ordType = ordType;
        this.tif = tif;
        this.side = side;
        this.px = px;
        this.qty = qty;
        this.shownQty = shownQty;
        this.ecnOrdId = ecnOrdId;
        this.origClOrdId = origClOrdId;
    }


    public CukeEcnOrder(
            String uid, String clOrdID,
            String symbol,
            MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side,
            double px, double qty, double shownQty) {
    	this.reqType = MadrigalReqType.ADD;

    	this.ecnUid = uid;
    	this.clOrdID = clOrdID;
    	this.symbol = symbol;
    	this.ordType = ordType;
    	this.tif = tif;
    	this.side = side;
    	this.px = px;
    	this.qty = qty;
    	this.shownQty = shownQty;
    }

	public CukeEcnOrder(
			String uid, String ecnOrdId, String clOrdID, String origClOrdId,
			String symbol, MadrigalSide side, double qty) {
    	this.reqType = MadrigalReqType.DEL;
		
    	this.ecnUid = uid;
    	this.ecnOrdId = ecnOrdId;
    	this.clOrdID = clOrdID;
    	this.origClOrdId = origClOrdId;
    	this.symbol = symbol;
    	this.side = side;
    	this.qty = qty;
	}

	public CukeEcnOrder(
			String uid, String ecnOrdId, String clOrdId, String origClOrdId,
			String symbol, double px, double qtyShown, double qty, MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side) {
    	this.reqType = MadrigalReqType.RWT;

    	this.ecnUid = uid;
    	this.ecnOrdId = ecnOrdId;
    	this.clOrdID = clOrdId;
    	this.origClOrdId = origClOrdId;
    	this.symbol = symbol;
    	this.px = px;
    	this.shownQty = qtyShown;
    	this.qty = qty;
    	this.ordType = ordType;
    	this.tif = tif;
    	this.side = side;
	}

	public MadrigalReqType getReqType() {
		return reqType;
	}
    public String getUid() {
		return ecnUid;
	}
	public String getClOrdID() {
		return clOrdID;
	}
	public String getSymbol() {
		return symbol;
	}
	public MadrigalTimeInForce getTif() {
		return tif;
	}
	public MadrigalSide getSide() {
		return side;
	}
	public double getPx() {
		return px == null ? Double.NaN : px;
	}
	public double getQty() {
		return qty;
	}
	public double getShownQty() {
		return shownQty == null ? Double.NaN : shownQty;
	}
    public String getEcnOrdId() {
		return ecnOrdId == null ? "" : ecnOrdId;
	}
	public String getOrigClOrdId() {
		return origClOrdId == null ? "" : origClOrdId;
	}

	public CukeEcnOrder defaults() {
		ecnUid = (ecnUid==null) ? "ecnUid" : ecnUid;
		symbol = (symbol==null) ? "ecnInstrId" : symbol;
		return this;
	}

	@Override
	public String toString() {
		return "CukeEcnOrder [reqType=" + reqType + ", ecnUid=" + ecnUid
				+ ", clOrdID=" + clOrdID + ", symbol=" + symbol + ", tif="
				+ tif + ", side=" + side + ", px=" + getPx() + ", qty=" + qty
				+ ", shownQty=" + getShownQty() + ", ecnOrdId=" + ecnOrdId
				+ ", origClOrdId=" + origClOrdId + "]";
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((clOrdID == null) ? 0 : clOrdID.hashCode());
		result = prime * result + getEcnOrdId().hashCode();
//				+ ((ecnOrdId == null) ? 0 : ecnOrdId.hashCode());
		result = prime * result + getOrigClOrdId().hashCode();
//				+ ((origClOrdId == null) ? 0 : origClOrdId.hashCode());
		long tempLong;
		tempLong = Double.doubleToLongBits(getPx());
		result = prime * result + (int) (tempLong ^ (tempLong >>> 32));
		tempLong = Double.doubleToLongBits(qty);
		result = prime * result + (int) (tempLong ^ (tempLong >>> 32));
		result = prime * result + ((reqType == null) ? 0 : reqType.hashCode());
		tempLong = Double.doubleToLongBits(getShownQty());
		result = prime * result + (int) (tempLong ^ (tempLong >>> 32));
		result = prime * result + ((side == null) ? 0 : side.hashCode());
		result = prime * result + ((symbol == null) ? 0 : symbol.hashCode());
		result = prime * result + ((ordType == null) ? 0 : ordType.hashCode());
		result = prime * result + ((tif == null) ? 0 : tif.hashCode());
		result = prime * result + ((ecnUid == null) ? 0 : ecnUid.hashCode());
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
		CukeEcnOrder other = (CukeEcnOrder) obj;
		if (clOrdID == null) {
			if (other.clOrdID != null)
				return false;
		} else if (!clOrdID.equals(other.clOrdID))
			return false;
//		if (ecnOrdId == null) {
//			if (other.ecnOrdId != null)
//				return false;
//		} else if (!ecnOrdId.equals(other.ecnOrdId))
//			return false;
		if (!getEcnOrdId().equals(other.getEcnOrdId()))
			return false;
//		if (origClOrdId == null) {
//			if (other.origClOrdId != null)
//				return false;
//		} else if (!origClOrdId.equals(other.origClOrdId))
//			return false;
		if (!getOrigClOrdId().equals(other.getOrigClOrdId()))
			return false;
		if (Double.doubleToLongBits(getPx()) != Double.doubleToLongBits(other.getPx()))
			return false;
		if (Double.doubleToLongBits(qty) != Double.doubleToLongBits(other.qty))
			return false;
		if (reqType != other.reqType)
			return false;
		if (Double.doubleToLongBits(getShownQty()) != Double
				.doubleToLongBits(other.getShownQty()))
			return false;
		if (side != other.side)
			return false;
		if (symbol == null) {
			if (other.symbol != null)
				return false;
		} else if (!symbol.equals(other.symbol))
			return false;
		if (ordType != other.ordType)
			return false;
		if (tif != other.tif)
			return false;
		if (ecnUid == null) {
			if (other.ecnUid != null)
				return false;
		} else if (!ecnUid.equals(other.ecnUid))
			return false;
		return true;
	}

}
