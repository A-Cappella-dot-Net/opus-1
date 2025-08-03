package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;

public interface IExchangeServer {
    boolean isStrictRwt();
    void sendExecutionReport(
            final SelectionKey key, String uid,
            long orderID, String clOrdID, String origClOrdID, char execType, char ordStatus, int ordRejReason,
            String symbol, char side, char ordType, char timeInForce, double price, double qty, double shownQty,
            double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text);
    void sendOrderCancelReject(
            final SelectionKey key, String uid,
            long orderID, String clOrdID, String origClOrdID, char ordStatus,
            char cxlRejResponseTo, int cxlRejReason, String text);

    void sendMdsToAllSubscribers(MarketDataSnapshot mds);
    void sendInstrStatusToAllSubscribers(InstrumentStatus status);
    void sendImbalanceToAllSubscribers(Imbalance imbalance);
}
