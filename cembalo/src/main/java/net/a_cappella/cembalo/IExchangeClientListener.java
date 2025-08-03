package net.a_cappella.cembalo;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.MktStatus;
import net.a_cappella.cembalo.constants.UserStatus;

public interface IExchangeClientListener {
    void marketStatus(MktStatus marketStatus);

    void onMarketDataRequestReject(String marketDataRequestRejectReason);
    void onInstrument(String securityID, String symbol, int maturityDate, double couponRate, double contractMultiplier, double minPriceIncrement, double minQty, double minQtyIncrement);
    void onMarketDataSnapshot(String securityID, MarketDataSnapshot mds);
    void onInstrumentStatus(String securityID, InstrumentStatus is);
    void onImbalance(String securityID, Imbalance imb);

    void onUserResponse(String ecnUid, UserStatus status, String text);

    void onExecutionReport(String execId, String ecnOrdId, String clOrdId, String origClOrdId,
                           char execType, char ordStatus, int ordRejReason,
                           String symbol, char side, double price, char ordType, char timeInForce,
                           double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text,
                           long transactTime);
    void onOrderCancelReject(
            String execId, String ecnOrdId, String clOrdId, String origClOrdId,
            char ordStatus, char cxlRejResponseTo, int cxlRejReason, String text,
            long transactTime);
}
