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

package net.a_cappella.lh;

import net.a_cappella.cembalo.ExchangeClient;
import net.a_cappella.cembalo.IExchangeClientListener;
import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.MktStatus;
import net.a_cappella.cembalo.constants.UserStatus;
import net.a_cappella.cembalo.generator.Dictionary;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.madrigal.IEcnUserManager;
import net.a_cappella.madrigal.ILoginManagerAdaptor;
import net.a_cappella.madrigal.IMarketDataService;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.madrigal.om.IOrderManagerAdaptor;
import net.a_cappella.madrigal.om.IOrderManagerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.cembalo.generated.FixConstants.*;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.*;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.*;

public class LineHandler extends ExchangeClient implements IExchangeClientListener, ILoginManagerAdaptor, IOrderManagerAdaptor {
    private static final Logger log = LoggerFactory.getLogger(LineHandler.class);

	protected String _ecn;
	protected String _lhEcn;
	protected OrderObj _response = new OrderObj();

	private IMarketDataService _marketDataService;
	public void setMarketDataService(IMarketDataService marketDataService) {
		_marketDataService = marketDataService;
	}
	private IEcnUserManager _ecnUserManager;
	public void setEcnUserManager(IEcnUserManager ecnUserManager) {
		_ecnUserManager = ecnUserManager;
	}
	private IOrderManagerService _orderManagerService;
	public void setOrderManagerService(IOrderManagerService orderManagerService) {
		_orderManagerService = orderManagerService;
	}

	private final EcnInstrumentObj _ecnInstrument = new EcnInstrumentObj();
	private final EcnPriceObj _ecnPrice = new EcnPriceObj();
	private final EcnInstrStatusObj _ecnInstrStatus = new EcnInstrStatusObj();
	private final EcnImbalanceObj _ecnImbalance = new EcnImbalanceObj();
	private final MarketStatusObj _marketStatus = new MarketStatusObj();

	public LineHandler(String ecn, MsgCoder coder, String connInfoStr, Dictionary dictionary) {
		super(coder, connInfoStr, dictionary);

		_ecn = ecn;
		_lhEcn = MadrigalConstants.LH_ECN_PREFIX + _ecn;
	}

	public void init() {
		setListener(this);

		boolean handleMarketData = _marketDataService != null;
		boolean handleOrderFlow = _orderManagerService != null;
		if (handleMarketData && !handleOrderFlow) {
			connectToExchange();
		}
		setHandleMarketData(handleMarketData);
	}



	@Override
	public void connectToExchange() {
		super.start();
	}

	@Override
	public void disconnectFromExchange() {
		super.stop();
	}

	@Override
	public void login(String ecnUid, String ecnPwd) {
		super.login(ecnUid, ecnPwd);
	}

	@Override
	public void logout(String ecnUid, String ecnPwd) {
		super.logout(ecnUid, ecnPwd);
	}

	@Override
	public void sendNewOrderSingle(String uid, String clOrdID, String symbol, MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side, double px, double qtyShown, double qty) {
		super.sendNewOrderSingle(uid, clOrdID, symbol, EcnConverters.convert(ordType), EcnConverters.convert(tif), EcnConverters.convert(side), px, qtyShown, qty);
	}
	@Override
	public void sendOrderCancelRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, MadrigalSide side, double qty) {
		super.sendOrderCancelRequest(uid, ecnOrdId, clOrdId, origClOrdId, symbol, EcnConverters.convert(side), qty);
	}
	@Override
	public void sendOrderCancelReplaceRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId,
                                              String symbol, double px, double qtyShown, double qty, MadrigalOrdType ordType, MadrigalTimeInForce tif, MadrigalSide side) {
		super.sendOrderCancelReplaceRequest(uid, ecnOrdId, clOrdId, origClOrdId, symbol, px, qtyShown, qty, EcnConverters.convert(ordType), EcnConverters.convert(tif), EcnConverters.convert(side));
	}



	@Override
	public void marketStatus(MktStatus marketStatus) {
		super.marketStatus(marketStatus);
		onMarketStatus(EcnConverters.convert(marketStatus));
	}

	private void onMarketStatus(MadrigalMarketStatus status) {
		try {
			if (_marketDataService != null) {
				_marketStatus.set(_ecn, MadrigalGatewayType.MARKET_DATA, status, System.currentTimeMillis());
				_marketDataService.publishMarketStatus(_marketStatus);
			}
			if (_orderManagerService != null) {
				_marketStatus.set(_ecn, MadrigalGatewayType.ORDER_MANAGER, status, System.currentTimeMillis());
				_orderManagerService.publishMarketStatus(_marketStatus);
			}
		} catch (Exception e) {
			log.error("", e);
		}
	}

	@Override
	public void onMarketDataRequestReject(String marketDataRequestRejectReason) {
		log.error("MarketDataRequestResult => "+marketDataRequestRejectReason);
	}

	@Override
	public void onInstrument(String securityID, String symbol, int maturityDate, double couponRate,
			double contractMultiplier, double minPriceIncrement, double minQty, double minQtyIncrement) {
		try {
			_ecnInstrument.set(securityID, symbol, maturityDate, couponRate, contractMultiplier,
					minPriceIncrement, minQty, minQtyIncrement,
					_ecn, System.currentTimeMillis());
			_marketDataService.publishInstrument(_ecnInstrument);
		} catch (Exception e) {
			log.error("", e);
		}
	}

	@Override
	public void onMarketDataSnapshot(String securityID, MarketDataSnapshot mds) {
		try {
			_ecnPrice.set(_ecn, securityID, mds);
			_marketDataService.publishEcnPrice(_ecnPrice);
		} catch (Exception e) {
			log.error("", e);
		}
	}

	@Override
	public void onInstrumentStatus(String securityID, InstrumentStatus is) {
		try {
			_ecnInstrStatus.set(_ecn, is._tsx, securityID, EcnConverters.convert(is._book), EcnConverters.convert(is._status), EcnConverters.convert(is._phase));
			_marketDataService.publishEcnInstrStatus(_ecnInstrStatus);
		} catch (Exception e) {
			log.error("", e);
		}
	}

	@Override
	public void onImbalance(String securityID, Imbalance imb) {
		try {
			_ecnImbalance.set(_ecn, imb.getTsx(), securityID, EcnConverters.convert(imb.getBook()), imb.isAuction(), EcnConverters.convert(imb.getSide()), imb.getMatched(), imb.getSurplus(), imb.getPrice());
			_marketDataService.publishEcnImbalance(_ecnImbalance);
		} catch (Exception e) {
			log.error("", e);
		}
	}

	@Override
	public void onUserResponse(String ecnUid, UserStatus status, String text) {
		_ecnUserManager.publishEcnUserLogOpResponse(ecnUid, EcnConverters.convert(status), text);
	}

	@Override
	public void onExecutionReport(String execId, String ecnOrdId, String clOrdId, String origClOrdId,
			char execType, char ordStatus, int ordRejReason,
			String symbol, char side, double price, char ordType, char timeInForce,
			double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text,
			long transactTime) {
		int verPos = clOrdId.indexOf("-");
		String ordId = clOrdId.substring(0, verPos);
		String verStr = clOrdId.substring(verPos+1);
		int ver = Integer.parseInt(verStr);
		MadrigalOrdStatus status;
        MadrigalReqType reqType = ADD;

        switch (execType) {
        case Val_ExecType_New:
        	status = ACK;
        	break;
        case Val_ExecType_Canceled:
        	if (timeInForce==Val_TimeInForce_IOC) { // IOC order was not filled
            	status = DONE;
        	} else {
            	status = ACK;
            	reqType = DEL;
        	}
        	break;
        case Val_ExecType_Replaced:
        	status = ACK;
        	reqType = RWT;
        	break;
        case Val_ExecType_Rejected:
        	status = NAK;
        	break;
        case Val_ExecType_Trade:
        	status = FILL;
        	break;
       	default:
        	status = null;
        	log.error("cannot determine status for order "+ecnOrdId);
        	break;
        }

        boolean done = ordStatus==Val_OrdStatus_Filled || ordStatus==Val_OrdStatus_Canceled;

        _response.setResponse(
        		reqType,
        		_lhEcn, execId, ecnOrdId, ordId, ver, clOrdId, // execId field from exchange goes into Madrigal field fillId
        		status, lastQty, lastPx, leavesQty, cumQty, avgPx,
        		text, done, transactTime);
        _orderManagerService.publishResponse(_response);
	}

	@Override
	public void onOrderCancelReject(
			String execId, String ecnOrdId, String clOrdId, String origClOrdId,
			char ordStatus, char cxlRejResponseTo, int cxlRejReason, String text,
			long transactTime) {
		int verPos = clOrdId.indexOf("-");
		String ordId = clOrdId.substring(0, verPos);
		String verStr = clOrdId.substring(verPos+1);
		int ver = Integer.parseInt(verStr);
        boolean done = cxlRejReason==Val_CxlRejReason_UnknownOrder;

        _response.setResponse(
        		(cxlRejResponseTo == Val_CxlRejResponseTo_OrderCancelRequest) ? DEL : RWT,
        		_lhEcn, execId, ecnOrdId, ordId, ver, clOrdId, // exchange.execId -> madrigal.fillId
        		NAK, 0.0, 0.0, 0.0, 0.0, 0.0, 
        		text, done, transactTime);
        _orderManagerService.publishResponse(_response);
	}
}
