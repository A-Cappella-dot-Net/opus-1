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

package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejReason_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejResponseTo_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Rejected;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdRejReason_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Rejected;

import java.nio.channels.SelectionKey;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.cembalo.message.TimerMsg;
import net.a_cappella.cembalo.message.TimerMsgs;

public class Matcher {
    private static final Logger log = LoggerFactory.getLogger(Matcher.class);

    private final IExchangeServer _server;
    public final ContinuousOrderBook _continuousOrderBook;
    public final AuctionOrderBook _openAuctionOrderBook;
    public final AuctionOrderBook _closeAuctionOrderBook;

    private final boolean _strictRwt;
    private final Instrument _instrument;
    private long _nextOrderID = 1L;

    public Matcher(IExchangeServer server, ActiveOrders activeOrders, Instrument instrument) {
        _server = server;
        _strictRwt = server.isStrictRwt();
        _continuousOrderBook = new ContinuousOrderBook(server, activeOrders, instrument);
        _openAuctionOrderBook = new AuctionOrderBook(server, activeOrders, instrument, _continuousOrderBook, true);
        _closeAuctionOrderBook = new AuctionOrderBook(server, activeOrders, instrument, _continuousOrderBook, false);
        _instrument = instrument;
    }

    public void cancelOrder(Order order) {
        switch (order.forOrderBook()) {
            case CLOSE_BK:
                _closeAuctionOrderBook.cancelOrder(order);
                break;
            case CONTINUOUS_BK:
                MarketDataSnapshot mds = _continuousOrderBook.cancelOrder(order, "User logout");
                if (mds==null) {
                    log.error("'Active' order "+order+" does not exist in the order book !!! Please investigate.");
                } else {
                    _server.sendMdsToAllSubscribers(mds);
                }
                break;
            case OPEN_BK:
                _openAuctionOrderBook.cancelOrder(order);
                break;
            default:
                break;
        }
    }

    public Order handleNewOrderSingle(final SelectionKey key, String uid, String clOrdID, String securityID, char ordType, char tif, char side, double px, double qtyShown, double qty) {
        String invalidErr = _instrument.validate(px, qtyShown, qty);
        if (invalidErr != null) {
            _server.sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_Other,
                    securityID, side, ordType, tif, px, qty, qtyShown, 0.0, Double.NaN, qty, 0.0, Double.NaN, invalidErr);
            return null;
        }

        Order order = null;
        switch (Order.forOrderBook(TimeInForce.fromFix(tif))) {
            case CLOSE_BK:
                if (!_closeAuctionOrderBook.isOpen()) {
                    _server.sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_Other,
                            securityID, side, ordType, tif, px, qty, qtyShown, 0.0, Double.NaN, qty, 0.0, Double.NaN, "Instrument is CLOSED");
                    return null;
                }
                order = new Order(key, uid, _nextOrderID++, clOrdID, securityID, ordType, tif, side, qtyShown, qty, px);
                _closeAuctionOrderBook.handleNewOrderSingle(key, uid, clOrdID, securityID, ordType, tif, side, px, qtyShown, qty, order);
                break;
            case CONTINUOUS_BK:
                if (!_continuousOrderBook.isOpen()) {
                    _server.sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_Other,
                            securityID, side, ordType, tif, px, qty, qtyShown, 0.0, Double.NaN, qty, 0.0, Double.NaN, "Instrument is CLOSED");
                    return null;
                }
                order = new Order(key, uid, _nextOrderID++, clOrdID, securityID, ordType, tif, side, qtyShown, qty, px);
                _continuousOrderBook.handleNewOrderSingle(key, uid, clOrdID, securityID, ordType, tif, side, px, qtyShown, qty, order);
                break;
            case OPEN_BK:
                if (!_openAuctionOrderBook.isOpen()) {
                    _server.sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_Other,
                            securityID, side, ordType, tif, px, qty, qtyShown, 0.0, Double.NaN, qty, 0.0, Double.NaN, "Instrument is CLOSED");
                    return null;
                }
                order = new Order(key, uid, _nextOrderID++, clOrdID, securityID, ordType, tif, side, qtyShown, qty, px);
                _openAuctionOrderBook.handleNewOrderSingle(key, uid, clOrdID, securityID, ordType, tif, side, px, qtyShown, qty, order);
                break;
            default:
                break;
        }

        return order;
    }

    public void handleOrderCancelReplaceRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, double px, double qtyShown, double qty, char ordType, char side, char tif, Order order) {
        String invalidErr = _instrument.validate(px, qtyShown, qty);
        if (invalidErr != null) {
            _server.sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_Other,
                    invalidErr);
            return;
        }

        if (_strictRwt && qty<order._cumQty) {
            _server.sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_Other,
                    "Too late to replace");
            return;
        }

        switch (order.forOrderBook()) {
            case CLOSE_BK:
                _closeAuctionOrderBook.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, px, qtyShown, qty, ordType, side, tif, order);
                break;
            case CONTINUOUS_BK:
                _continuousOrderBook.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, px, qtyShown, qty, ordType, side, tif, order);
                break;
            case OPEN_BK:
                _openAuctionOrderBook.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, px, qtyShown, qty, ordType, side, tif, order);
                break;
            default:
                break;
        }
    }

    public void handleOrderCancelRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, char side, double qty, Order order) {
        switch (order.forOrderBook()) {
            case CLOSE_BK:
                _closeAuctionOrderBook.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, side, qty, order);
                break;
            case CONTINUOUS_BK:
                _continuousOrderBook.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, side, qty, order);
                break;
            case OPEN_BK:
                _openAuctionOrderBook.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, side, qty, order);
                break;
            default:
                break;
        }
    }

    public void handleTimerMessage(TimerMsgs msgs) {
        log.debug("================== TimerMsg "+_instrument.getSecId()+" "+msgs);
        List<TimerMsg> list = msgs.getMsgs();
        for (int i=0; i<list.size(); i++) {
            TimerMsg msg = list.get(i);

            switch (msg.getBook()) {
                case OPEN_BK:
                    _openAuctionOrderBook.handleTimerMessage(msg);
                    break;
                case CLOSE_BK:
                    _closeAuctionOrderBook.handleTimerMessage(msg);
                    break;
                case CONTINUOUS_BK:
                    _continuousOrderBook.handleTimerMessage(msg);
                    break;
                default:
                    break;
            }
        }
    }
}
