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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.cembalo.constants.*;
import net.a_cappella.madrigal.common.constants.*;

public class EcnConverters {

	public static Side convert(MadrigalSide side) {
		switch (side) {
		case Buy: return Side.Buy;
		case None: return Side.None;
		case Sell: return Side.Sell;
		case SellShort: return Side.SellShort;
		default: return Side.NULL_VAL;
		}
	}
	public static MadrigalSide convert(Side side) {
		switch (side) {
		case Buy: return MadrigalSide.Buy;
		case None: return MadrigalSide.None;
		case Sell: return MadrigalSide.Sell;
		case SellShort: return MadrigalSide.SellShort;
		default: return MadrigalSide.NULL_VAL;
		}
	}

	public static OrdType convert(MadrigalOrdType ordType) {
		switch (ordType) {
		case LIMIT: return OrdType.Limit;
		case MARKET: return OrdType.Market;
		case PEGGED: return OrdType.Pegged;
		default: return OrdType.Unknown;
		}
	}

	public static TimeInForce convert(MadrigalTimeInForce tif) {
		switch (tif) { // STO, DAY, IOC, FOK, AtOpen, AtClose
		case STO: return TimeInForce.STO;
		case DAY: return TimeInForce.DAY;
		case IOC: return TimeInForce.IOC;
		case FOK: return TimeInForce.FOK;
		case AtOpen: return TimeInForce.AtOpen;
		case AtClose: return TimeInForce.AtClose;
		default: return TimeInForce.NULL_VAL;
		}
	}

	public static MadrigalOrderBook convert(Book book) {
        switch (book) {
        case OPEN_BK: return MadrigalOrderBook.OPEN;
        case CLOSE_BK: return MadrigalOrderBook.CLOSE;
        default: return MadrigalOrderBook.CONTINUOUS;
        }
    }

	public static MadrigalInstrStatus convert(InstrStatus status) {
        switch (status) {
        case OPEN: return MadrigalInstrStatus.OPEN;
        default: return MadrigalInstrStatus.CLOSED;
        }
    }

    public static MadrigalInstrPhase convert(InstrPhase phase) {
        switch (phase) {
        case ALL: return MadrigalInstrPhase.ALL;
        case ONLY_NEW: return MadrigalInstrPhase.ONLY_NEW;
        case NON_MATCHING: return MadrigalInstrPhase.NON_MATCHING;
        case MATCHING: return MadrigalInstrPhase.MATCHING;
        default: return MadrigalInstrPhase.CLOSED;
        }
    }

	public static MadrigalUserStatus convert(UserStatus userStatus) {
        switch (userStatus) {
            case LOGGED_IN: return MadrigalUserStatus.On;
            default: return MadrigalUserStatus.Off;
        }
    }

	public static MadrigalMarketStatus convert(MktStatus mktStatus) {
        switch (mktStatus) {
            case OPEN: return MadrigalMarketStatus.OPEN;
            case CLOSED: return MadrigalMarketStatus.CLOSED;
            default: return MadrigalMarketStatus.NULL_VAL;
        }
    }
	public static MktStatus convert(MadrigalMarketStatus mktStatus) {
        switch (mktStatus) {
            case OPEN: return MktStatus.OPEN;
            case CLOSED: return MktStatus.CLOSED;
            default: return MktStatus.NULL_VAL;
        }
    }
}
