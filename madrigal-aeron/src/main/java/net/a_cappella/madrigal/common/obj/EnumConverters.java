package net.a_cappella.madrigal.common.obj;

import net.a_cappella.madrigal.common.constants.MadrigalGatewayType;
import net.a_cappella.madrigal.common.constants.MadrigalInstrPhase;
import net.a_cappella.madrigal.common.constants.MadrigalInstrStatus;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMarketStatus;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalOrderBook;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import sbe.generated.SbeBookEnum;
import sbe.generated.SbeBoolean;
import sbe.generated.SbeGatewayTypeEnum;
import sbe.generated.SbeInstrPhaseEnum;
import sbe.generated.SbeInstrStatusEnum;
import sbe.generated.SbeLogOpEnum;
import sbe.generated.SbeMarketStatusEnum;
import sbe.generated.SbeModeEnum;
import sbe.generated.SbeOrdStatusEnum;
import sbe.generated.SbeOrdTypeEnum;
import sbe.generated.SbeReqTypeEnum;
import sbe.generated.SbeSideEnum;
import sbe.generated.SbeTimeInForceEnum;
import sbe.generated.SbeUserStatusEnum;

public class EnumConverters {

	public static SbeBoolean convert(boolean bool) {
    	return bool ? SbeBoolean.TRUE : SbeBoolean.FALSE;
    }
	public static boolean convert(SbeBoolean bool) {
    	return bool == SbeBoolean.TRUE;
    }

    public static SbeBookEnum convert(MadrigalOrderBook book) {
        switch (book) {
            case OPEN: return SbeBookEnum.OPEN;
            case CLOSE: return SbeBookEnum.CLOSE;
            case CONTINUOUS: return SbeBookEnum.CONTINUOUS;
            default: return SbeBookEnum.NULL_VAL;
        }
    }
	public static MadrigalOrderBook convert(SbeBookEnum sbeBookEnum) {
        switch (sbeBookEnum) {
            case OPEN: return MadrigalOrderBook.OPEN;
            case CLOSE: return MadrigalOrderBook.CLOSE;
            case CONTINUOUS: return MadrigalOrderBook.CONTINUOUS;
            default: return MadrigalOrderBook.NULL_VAL;
        }
    }

	public static SbeGatewayTypeEnum convert(MadrigalGatewayType gatewayType) {
        switch (gatewayType) {
            case MARKET_DATA: return SbeGatewayTypeEnum.MARKET_DATA;
            case ORDER_MANAGER: return SbeGatewayTypeEnum.ORDER_MANAGER;
            default: return SbeGatewayTypeEnum.NULL_VAL;
        }
    }
	public static MadrigalGatewayType convert(SbeGatewayTypeEnum gatewayType) {
        switch (gatewayType) {
            case MARKET_DATA: return MadrigalGatewayType.MARKET_DATA;
            case ORDER_MANAGER: return MadrigalGatewayType.ORDER_MANAGER;
            default: return MadrigalGatewayType.NULL_VAL;
        }
    }

	public static SbeMarketStatusEnum convert(MadrigalMarketStatus marketStatus) {
        switch (marketStatus) {
            case OPEN: return SbeMarketStatusEnum.OPEN;
            case CLOSED: return SbeMarketStatusEnum.CLOSED;
            default: return SbeMarketStatusEnum.NULL_VAL;
        }
    }
	public static MadrigalMarketStatus convert(SbeMarketStatusEnum marketStatus) {
        switch (marketStatus) {
            case OPEN: return MadrigalMarketStatus.OPEN;
            case CLOSED: return MadrigalMarketStatus.CLOSED;
            default: return MadrigalMarketStatus.NULL_VAL;
        }
    }

	public static SbeInstrStatusEnum convert(MadrigalInstrStatus status) {
        switch (status) {
            case OPEN: return SbeInstrStatusEnum.OPEN;
            case CLOSED: return SbeInstrStatusEnum.CLOSED;
            default: return SbeInstrStatusEnum.NULL_VAL;
        }
    }
	public static MadrigalInstrStatus convert(SbeInstrStatusEnum status) {
        switch (status) {
            case OPEN: return MadrigalInstrStatus.OPEN;
            case CLOSED: return MadrigalInstrStatus.CLOSED;
            default: return MadrigalInstrStatus.NULL_VAL;
        }
    }

	public static SbeInstrPhaseEnum convert(MadrigalInstrPhase phase) {
        switch (phase) {
	        case ALL: return SbeInstrPhaseEnum.ALL;
	        case ONLY_NEW: return SbeInstrPhaseEnum.ONLY_NEW;
	        case NON_MATCHING: return SbeInstrPhaseEnum.NON_MATCHING;
	        case MATCHING: return SbeInstrPhaseEnum.MATCHING;
	        default: return SbeInstrPhaseEnum.NULL_VAL;
        }
    }
	public static MadrigalInstrPhase convert(SbeInstrPhaseEnum phase) {
        switch (phase) {
            case ALL: return MadrigalInstrPhase.ALL;
            case ONLY_NEW: return MadrigalInstrPhase.ONLY_NEW;
            case NON_MATCHING: return MadrigalInstrPhase.NON_MATCHING;
            case MATCHING: return MadrigalInstrPhase.MATCHING;
            default: return MadrigalInstrPhase.NULL_VAL;
        }
    }

    public static SbeModeEnum convert(MadrigalMode mode) {
        switch (mode) {
            case REQUEST: return SbeModeEnum.REQUEST;
            case RESPONSE: return SbeModeEnum.RESPONSE;
            default: return SbeModeEnum.NULL_VAL;
        }
    }
	public static MadrigalMode convert(SbeModeEnum msgType) {
        switch (msgType) {
            case REQUEST: return MadrigalMode.REQUEST;
            case RESPONSE: return MadrigalMode.RESPONSE;
            default: return MadrigalMode.NULL_VAL;
        }
    }

	public static SbeLogOpEnum convert(MadrigalLogOp logOp) {
    	if (logOp == null) return SbeLogOpEnum.logout;
        switch (logOp) {
            case login: return SbeLogOpEnum.login;
            case logout: return SbeLogOpEnum.logout;
            default: return SbeLogOpEnum.NULL_VAL;
        }
    }
	public static MadrigalLogOp convert(SbeLogOpEnum logOp) {
        switch (logOp) {
            case login: return MadrigalLogOp.login;
            case logout: return MadrigalLogOp.logout;
            default: return MadrigalLogOp.NULL_VAL;
        }
    }

	public static SbeUserStatusEnum convert(MadrigalUserStatus userStatus) {
    	if (userStatus == null) return SbeUserStatusEnum.Off;
        switch (userStatus) {
            case On: return SbeUserStatusEnum.On;
            case Off: return SbeUserStatusEnum.Off;
            default: return SbeUserStatusEnum.NULL_VAL;
        }
    }
	public static MadrigalUserStatus convert(SbeUserStatusEnum sbeUserStatus) {
        switch (sbeUserStatus) {
            case On: return MadrigalUserStatus.On;
            case Off: return MadrigalUserStatus.Off;
            default: return MadrigalUserStatus.NULL_VAL;
        }
    }

	public static SbeOrdTypeEnum convert(MadrigalOrdType ordType) {
        switch (ordType) {
            case LIMIT: return SbeOrdTypeEnum.LIMIT;
            case MARKET: return SbeOrdTypeEnum.MARKET;
            case PEGGED: return SbeOrdTypeEnum.PEGGED;
            default: return SbeOrdTypeEnum.NULL_VAL;
        }
    }
	public static MadrigalOrdType convert(SbeOrdTypeEnum ordType) {
        switch (ordType) {
            case LIMIT: return MadrigalOrdType.LIMIT;
            case MARKET: return MadrigalOrdType.MARKET;
            case PEGGED: return MadrigalOrdType.PEGGED;
            default: return MadrigalOrdType.NULL_VAL;
        }
    }

	public static SbeTimeInForceEnum convert(MadrigalTimeInForce tif) {
        switch (tif) {
            case STO: return SbeTimeInForceEnum.STO;
            case DAY: return SbeTimeInForceEnum.DAY;
            case IOC: return SbeTimeInForceEnum.IOC;
            case FOK: return SbeTimeInForceEnum.FOK;
            case AtOpen: return SbeTimeInForceEnum.AtOpen;
            case AtClose: return SbeTimeInForceEnum.AtClose;
            default: return SbeTimeInForceEnum.NULL_VAL;
        }
    }
	public static MadrigalTimeInForce convert(SbeTimeInForceEnum tif) {
        switch (tif) {
            case STO: return MadrigalTimeInForce.STO;
            case DAY: return MadrigalTimeInForce.DAY;
            case IOC: return MadrigalTimeInForce.IOC;
            case FOK: return MadrigalTimeInForce.FOK;
            case AtOpen: return MadrigalTimeInForce.AtOpen;
            case AtClose: return MadrigalTimeInForce.AtClose;
            default: return MadrigalTimeInForce.NULL_VAL;
        }
    }

	public static SbeSideEnum convert(MadrigalSide side) {
        switch (side) {
	        case Buy: return SbeSideEnum.Buy;
	        case Sell: return SbeSideEnum.Sell;
	        case SellShort: return SbeSideEnum.Short;
	        default: return SbeSideEnum.None;
        }
    }
	public static MadrigalSide convert(SbeSideEnum side) {
        switch (side) {
	        case Buy: return MadrigalSide.Buy;
	        case Sell: return MadrigalSide.Sell;
	        case Short: return MadrigalSide.SellShort;
            default: return MadrigalSide.None;
        }
    }

	public static SbeReqTypeEnum convert(MadrigalReqType reqType) {
        switch (reqType) {
            case ADD: return SbeReqTypeEnum.ADD;
            case RWT: return SbeReqTypeEnum.RWT;
            case DEL: return SbeReqTypeEnum.DEL;
            default: return SbeReqTypeEnum.NULL_VAL;
        }
    }
	public static MadrigalReqType convert(SbeReqTypeEnum sbeReqType) {
        switch (sbeReqType) {
            case ADD: return MadrigalReqType.ADD;
            case RWT: return MadrigalReqType.RWT;
            case DEL: return MadrigalReqType.DEL;
            default: return MadrigalReqType.NULL_VAL;
        }
    }

	public static SbeOrdStatusEnum convert(MadrigalOrdStatus ordStatus) {
        switch (ordStatus) {
            case ACK: return SbeOrdStatusEnum.ACK;
            case NAK: return SbeOrdStatusEnum.NAK;
            case FILL: return SbeOrdStatusEnum.FILL;
            case DONE: return SbeOrdStatusEnum.DONE;
            case CXL: return SbeOrdStatusEnum.CXL;
            default: return SbeOrdStatusEnum.NULL_VAL;
        }
    }
	public static MadrigalOrdStatus convert(SbeOrdStatusEnum sbeOrdStatus) {
        switch (sbeOrdStatus) {
            case ACK: return MadrigalOrdStatus.ACK;
            case NAK: return MadrigalOrdStatus.NAK;
            case FILL: return MadrigalOrdStatus.FILL;
            case DONE: return MadrigalOrdStatus.DONE;
            case CXL: return MadrigalOrdStatus.CXL;
            default: return MadrigalOrdStatus.NULL_VAL;
        }
    }
}
