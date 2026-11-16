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

import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecRestatementReason_RepricingOfOrder;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Replaced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Restated;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Trade;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Filled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_PartiallyFilled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Replaced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegPriceType_Market;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegPriceType_Primary;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.annotations.VisibleForTesting;

import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.InstrPhase;
import net.a_cappella.cembalo.constants.InstrStatus;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.cembalo.message.TimerMsg;

public class ContinuousOrderBook {
    private static final Logger log = LoggerFactory.getLogger(ContinuousOrderBook.class);

    private static final String COULD_NOT_MATCH_IOC_ORDER = "Could not match IOC order";

    private final IExchangeServer _server;
    private final ActiveOrders _activeOrders;
    private final String _securityID;
    private final int _ordering;

    private final ContinuousSide _bidSide = new ContinuousSide();
    private final ContinuousSide _offerSide = new ContinuousSide();

    private final MarketDataSnapshot _mds;
    private final InstrumentStatus _is;

    private final AccumulatingOrderBook<AccumulatingLevel> _accumulatingOrderBook;

    // Pegged orders. A pegged order follows a reference price given by the orders in this book that are
    // not pegged themselves: the best price on its own side (Primary peg), the best price on the opposite
    // side (Market peg) or the midpoint between the two (Mid Price peg).
    // Whenever the reference price changes the order leaves its price level and re-enters the order book
    // at the new pegged price as if it were a new order: it is matched if it became executable, and it
    // rests behind the orders that are already there otherwise.
    // A pegged order whose pegged price would go beyond its cap is held at its cap: it rests there, in the
    // order book, until the price to peg at is back within the cap.
    // A pegged order with no reference price to peg to is 'parked': it stays active, but out of the order
    // book, until its reference price becomes available.
    // The owner of the order is not told when the order is repriced. A Restated execution report tells it
    // when the order stops or resumes following its reference price, see restated().
    private final Instrument _instrument;
    private final List<Order> _peggedOrders = new ArrayList<>(); // all active pegged orders (resting or parked), sorted by arrival time
    private final List<Order> _repricedOrders = new ArrayList<>(); // scratch list, see repegOnce()
    private final MarketDataSnapshot _mdsBefore; // the order book as it was shown before a pegged order changed
    private boolean _pegPriceAtLimit; // second result of pegPrice()

    public ContinuousOrderBook(IExchangeServer server, ActiveOrders activeOrders, Instrument instrument) {
        _server = server;
        _activeOrders = activeOrders;
        _instrument = instrument;
        _securityID = instrument.getSecId();
        _ordering = instrument.getOrdering();
        _mds = new MarketDataSnapshot(_securityID, instrument.getMaxLevels());
        _mdsBefore = new MarketDataSnapshot(_securityID, instrument.getMaxLevels());
        _is = new InstrumentStatus(_securityID, Book.CONTINUOUS_BK);
        _accumulatingOrderBook = new AccumulatingOrderBook<>(server, instrument, (px) -> new AccumulatingLevel(px));
    }

    public boolean isOpen() {
        return _is._status == InstrStatus.OPEN;
    }

    public boolean isMatching() {
        return _is._phase == InstrPhase.MATCHING;
    }

    public void handleTimerMessage(TimerMsg msg) {
        switch (msg.getOperation()) {
            case CLOSE:
                _is._status = InstrStatus.CLOSED;
                _is._phase = InstrPhase.CLOSED;
                _server.sendInstrStatusToAllSubscribers(getStatus());
                break;
            case OPEN:
                _is._status = InstrStatus.OPEN;
                if (_is._phase != InstrPhase.CLOSED) {
                    _server.sendInstrStatusToAllSubscribers(getStatus());
                }
                break;
            case NON_MATCHING:
                _is._phase = InstrPhase.NON_MATCHING;
                _server.sendInstrStatusToAllSubscribers(getStatus());
                break;
            case MATCHING:
                _is._phase = InstrPhase.MATCHING;
                _server.sendInstrStatusToAllSubscribers(getStatus());
                break;
            default:
                break;
        }
    }

    public void handleNewOrderSingle(final SelectionKey key, String uid, String clOrdID, String securityID, char ordType, char tif, char side, double px, double qtyShown, double qty, Order order) {
        _activeOrders.add(order);

        if (_is._phase == InstrPhase.NON_MATCHING) {
            _accumulatingOrderBook.addOrder(order);
        } else {
            MarketDataSnapshot mds = addOrder(order);
            if (mds!=null) {
                _server.sendMdsToAllSubscribers(mds);
            }
        }
    }

    public void handleOrderCancelReplaceRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, double px, double qtyShown, double qty, char ordType, char side, char tif, Order order) {
        order._clOrdID = clOrdID;
        order._origClOrdID = origClOrdID;

        // pegged orders are only accepted in the matching phase, hence they are never in the accumulating order book
        if (_is._phase == InstrPhase.NON_MATCHING && !order.isPegged()) {
            _accumulatingOrderBook.replaceOrder(order, px, qty, qtyShown, OrdType.fromFix(ordType));
        } else {
            MarketDataSnapshot mds = replaceOrder(order, px, qtyShown, qty);
            if (mds!=null) {
                _server.sendMdsToAllSubscribers(mds);
            }
        }
    }

    public void handleOrderCancelRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, char side, double qty, Order order) {
        _activeOrders.remove(order);

        order._clOrdID = clOrdID;
        order._origClOrdID = origClOrdID;

        if (_is._phase == InstrPhase.NON_MATCHING && !order.isPegged()) {
            _accumulatingOrderBook.cancelOrder(order);
        } else {
            MarketDataSnapshot mds = cancelOrder(order, null);
            if (mds!=null) {
                _server.sendMdsToAllSubscribers(mds);
            }
        }
    }

    /* efficient when there are relatively few active orders per connection */
    public MarketDataSnapshot removeOrder(Order ord) {
        if (ord.isPegged()) {
            fillSnapshot(_mdsBefore);
            removePeggedOrder(ord);
            return afterPeggedOrderChange();
        }

        ContinuousLevel continuousLevel = findLevel(ord);
        if (continuousLevel==null) return null;

        remove(ord, continuousLevel);
        return afterBookChange(getSnapshot());
    }

    /* efficient when there are many active orders per connection; not used ATM */
    public MarketDataSnapshot removeOrders(SelectionKey selectionKey) {
        for (int i=_peggedOrders.size()-1; i>=0; i--) {
            if (selectionKey.equals(_peggedOrders.get(i)._selectionKey)) _peggedOrders.remove(i);
        }
        boolean stackChanged = _bidSide.removeOrders(selectionKey) | _offerSide.removeOrders(selectionKey);
        return (stackChanged) ? afterBookChange(getSnapshot()) : null;
    }

    public MarketDataSnapshot getSnapshot() {
        return fillSnapshot(_mds);
    }

    // Only the price levels with displayed orders are part of the Market Data: a level made only of
    // hidden orders (Mid Price pegged orders) is skipped, and hidden orders do not add to the level size.
    private MarketDataSnapshot fillSnapshot(MarketDataSnapshot mds) {
        mds.reset(_securityID, System.currentTimeMillis());
        int depth = 0;
        for (int i=0; i<_bidSide.levelsCount() && depth<mds._marketDepth; i++) {
            ContinuousLevel continuousLevel = _bidSide.level(i);
            if (continuousLevel.hasDisplayedOrders()) {
                mds.setBid(depth++, continuousLevel.getPrice(), continuousLevel.getShownQty());
            }
        }
        depth = 0;
        for (int i=0; i<_offerSide.levelsCount() && depth<mds._marketDepth; i++) {
            ContinuousLevel continuousLevel = _offerSide.level(i);
            if (continuousLevel.hasDisplayedOrders()) {
                mds.setOffer(depth++, continuousLevel.getPrice(), continuousLevel.getShownQty());
            }
        }
        return mds;
    }

    public InstrumentStatus getStatus() {
        return _is;
    }

    public AccumulatingOrderBook<AccumulatingLevel> getAccumulatingOrderBook() {
        return _accumulatingOrderBook;
    }



    public MarketDataSnapshot match(Order ord) {
        if (_bidSide.isEmpty() && _offerSide.isEmpty()) {
            if (ord._tif==TimeInForce.IOC) {
                cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                return null;
            } else { // DAY or STO
                if (ord._side==Side.Buy) {
                    _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                } else { // SELL
                    _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                }
                return getSnapshot();
            }
        } else if (!_bidSide.isEmpty() && !_offerSide.isEmpty()) {
            if (isExecutable(ord)) {
                if (ord._side==Side.Buy) {
                    fill(ord, _offerSide, _ordering==Instrument.ORDERING_YIELD);
                    if (ord._leavesQty>0) {
                        if (ord._tif==TimeInForce.IOC) {
                            cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        } else {
                            _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                        }
                    }
                } else { // SELL
                    fill(ord, _bidSide, _ordering==Instrument.ORDERING_PRICE);
                    if (ord._leavesQty>0) {
                        if (ord._tif==TimeInForce.IOC) {
                            cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        } else {
                            _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                        }
                    }
                }
                return getSnapshot();
            } else { // not executable
                if (ord._tif==TimeInForce.IOC) {
                    cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                    return null;
                } else {
                    if (ord._side==Side.Buy) {
                        _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                    } else {
                        _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                    }
                    return getSnapshot();
                }
            }
        } else if (!_bidSide.isEmpty()) { // && _offerSide.isEmpty()
            if (ord._side==Side.Buy) {
                if (ord._tif==TimeInForce.IOC) {
                    cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                    return null;
                } else {
                    _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                    return getSnapshot();
                }
            } else { // SELL
                if (isExecutable(ord)) {
                    fill(ord, _bidSide, _ordering==Instrument.ORDERING_PRICE);
                    if (ord._leavesQty>0) {
                        if (ord._tif==TimeInForce.IOC) {
                            cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        } else {
                            _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                        }
                    }
                    return getSnapshot();
                } else { // not executable
                    if (ord._tif==TimeInForce.IOC) {
                        cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        return null;
                    } else {
                        _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                        return getSnapshot();
                    }
                }
            }
        } else { // !_offerSide.isEmpty() && _bidSide.isEmpty()
            if (ord._side==Side.Sell) {
                if (ord._tif==TimeInForce.IOC) {
                    cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                    return null;
                } else {
                    _offerSide.add(ord, _ordering==Instrument.ORDERING_YIELD);
                    return getSnapshot();
                }
            } else { // BUY
                if (isExecutable(ord)) {
                    fill(ord, _offerSide, _ordering==Instrument.ORDERING_YIELD);
                    if (ord._leavesQty>0) {
                        if (ord._tif==TimeInForce.IOC) {
                            cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        } else {
                            _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                        }
                    }
                    return getSnapshot();
                } else { // not executable
                    if (ord._tif==TimeInForce.IOC) {
                        cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
                        return null;
                    } else {
                        _bidSide.add(ord, _ordering==Instrument.ORDERING_PRICE);
                        return getSnapshot();
                    }
                }
            }
        }
    }

    private ContinuousLevel findLevel(Order ord) {
        ContinuousLevel continuousLevel = null;
        if (_bidSide.isEmpty() && _offerSide.isEmpty()) {
            return null;
        } else if (!_bidSide.isEmpty() && !_offerSide.isEmpty()) {
            double price = ord._price;
            double tobBid = _bidSide.priceAtDepth(0);
            double tobOffer = _offerSide.priceAtDepth(0);
            if (_ordering==Instrument.ORDERING_PRICE) {
                if (price<=tobBid) {
                    continuousLevel = _bidSide.findLevel(ord, true);
                } else if (price>=tobOffer) {
                    continuousLevel = _offerSide.findLevel(ord, false);
                }
            } else { // _ordering==Instrument.ORDERING_YIELD
                if (price>=tobBid) {
                    continuousLevel = _bidSide.findLevel(ord, false);
                } else if (price<=tobOffer) {
                    continuousLevel = _offerSide.findLevel(ord, true);
                }
            }
        } else if (!_bidSide.isEmpty()) { // && _offerSide.isEmpty()
            double price = ord._price;
            double tobBid = _bidSide.priceAtDepth(0);
            if (_ordering==Instrument.ORDERING_PRICE) {
                if (price<=tobBid) {
                    continuousLevel = _bidSide.findLevel(ord, true);
                }
            } else { // _ordering==Instrument.ORDERING_YIELD
                if (price>=tobBid) {
                    continuousLevel = _bidSide.findLevel(ord, false);
                }
            }
        } else { // !_offerSide.isEmpty() && _bidSide.isEmpty()
            double price = ord._price;
            double tobOffer = _offerSide.priceAtDepth(0);
            if (_ordering==Instrument.ORDERING_PRICE) {
                if (price>=tobOffer) {
                    continuousLevel = _offerSide.findLevel(ord, false);
                }
            } else { // _ordering==Instrument.ORDERING_YIELD
                if (price<=tobOffer) {
                    continuousLevel = _offerSide.findLevel(ord, true);
                }
            }
        }
        return continuousLevel;
    }

    @VisibleForTesting
    public MarketDataSnapshot addOrder(Order ord) {
        if (ord.isPegged()) {
            // the order is given its pegged price first: the acknowledgement reports it
            fillSnapshot(_mdsBefore);
            double px = pegPrice(ord, _bidSide.bestNonPeggedPrice(), _offerSide.bestNonPeggedPrice());
            setPegPrice(ord, px, _pegPriceAtLimit);
        }
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null, Val_ExecType_New, Val_OrdStatus_New, 0,
                ord._securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord.clientPrice(), ord._size, ord._shownSize, 0.0, Double.NaN, ord._size, 0.0, Double.NaN, null, ord.peggedPrice(), 0);
        if (ord.isPegged()) {
            return addPeggedOrder(ord);
        }
        return afterBookChange(match(ord));
    }

    @VisibleForTesting
    public MarketDataSnapshot replaceOrder(Order ord, double nPx, double nShownQty, double nQty) {
        if (ord.isPegged()) {
            return replacePeggedOrder(ord, nPx, nShownQty, nQty);
        }

        ContinuousLevel continuousLevel = findLevel(ord);
        if (continuousLevel==null) return null;

        double oPx = ord._price;
        double oQty = ord._size;
        double oShownQty = ord._shownSize;
        double oLeavesQty = ord._leavesQty;

        double deltaQty = nQty - oQty;
        double nLeavesQty = oLeavesQty + deltaQty;

        boolean filled = nLeavesQty<=0;

        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Replaced, (filled) ? Val_OrdStatus_Filled : Val_OrdStatus_Replaced,
                0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif),
                nPx, nQty, nShownQty,
                0.0, Double.NaN, nLeavesQty, ord._cumQty, ord._avgPx, null);

        MarketDataSnapshot mds;

        if (filled) {
            remove(ord, continuousLevel);
            mds = getSnapshot();
            _activeOrders.remove(ord);
        } else if (oPx==nPx) {
            ord._size = nQty;
            ord._shownSize = nShownQty;
            ord._leavesQty = nLeavesQty;
            ord._lastPx = Double.NaN;
            ord._lastQty = 0.0;
            continuousLevel.replace(ord, deltaQty, oShownQty, oLeavesQty, nShownQty, nLeavesQty);
            mds = getSnapshot();
        } else {
            // remove
            remove(ord, continuousLevel);
            // add to different level, possibly different qty/shown
            ord._price = nPx;
            ord._size = nQty;
            ord._shownSize = nShownQty;
            ord._leavesQty = nLeavesQty;
            ord._lastPx = Double.NaN;
            ord._lastQty = 0.0;
            mds = match(ord);
        }

        return afterBookChange(mds);
    }

    @VisibleForTesting
    public MarketDataSnapshot cancelOrder(Order ord, String text) {
        if (ord.isPegged()) {
            fillSnapshot(_mdsBefore);
            removePeggedOrder(ord);
            cancel(ord, text);
            return afterPeggedOrderChange();
        }

        ContinuousLevel continuousLevel = findLevel(ord);
        if (continuousLevel==null) return null;

        remove(ord, continuousLevel);
        cancel(ord, text);
        return afterBookChange(getSnapshot());
    }

    /**
     * Cancels an order that was not matched in an auction. As opposed to {@link #cancelOrder(Order, String)},
     * the pegged orders are not repriced: the auction is still going through the orders of this book.
     */
    public void cancelUnmatchedInAuction(Order ord, String text) {
        if (ord.isPegged()) {
            removePeggedOrder(ord);
        } else {
            ContinuousLevel continuousLevel = findLevel(ord);
            if (continuousLevel==null) return;
            remove(ord, continuousLevel);
        }
        cancel(ord, text);
    }

    /** To be called by an auction order book once its auction is over, before the Market Data is published. */
    public void onAuctionCompleted(boolean isOpenAuction, String text) {
        if (isOpenAuction) {
            // orders may have been transferred to this order book
            repegAll();
        } else {
            // all orders of this order book took part in the close auction and were either filled or canceled;
            // what is left are the pegged orders that were parked, which have no price to take part with
            for (int i=0; i<_peggedOrders.size(); i++) {
                Order ord = _peggedOrders.get(i);
                if (ord._leavesQty>0.0) {
                    if (!ord.isParked()) removeFromBook(ord);
                    cancel(ord, text);
                }
            }
            _peggedOrders.clear();
            _bidSide.removeEmptyLevels();
            _offerSide.removeEmptyLevels();
        }
    }

    private void remove(Order ord, ContinuousLevel continuousLevel) {
        continuousLevel.remove(ord);

        if (continuousLevel.hasNoOrders()) {
            if (ord._side==Side.Buy) {
                _bidSide.remove(continuousLevel);
            } else {
                _offerSide.remove(continuousLevel);
            }
        }
    }



    // ---------------------------------------- pegged orders ----------------------------------------

    // the order comes with its pegged price, and _mdsBefore is set, see addOrder()
    private MarketDataSnapshot addPeggedOrder(Order ord) {
        if (ord.isParked()) { // no reference price
            if (ord._tif==TimeInForce.IOC) {
                cancel(ord, COULD_NOT_MATCH_IOC_ORDER);
            } else {
                _peggedOrders.add(ord);
                restated(ord);
            }
            return null;
        }

        match(ord);
        if (ord._tif!=TimeInForce.IOC && ord._leavesQty>0.0) {
            _peggedOrders.add(ord); // the order rests
            if (ord._pegAtLimit) restated(ord);
        }
        return afterPeggedOrderChange();
    }

    private MarketDataSnapshot replacePeggedOrder(Order ord, double nCap, double nShownQty, double nQty) {
        fillSnapshot(_mdsBefore);

        double oPx = ord._price; // NaN if parked
        double oShownQty = ord._shownSize;
        double oLeavesQty = ord._leavesQty;

        double deltaQty = nQty - ord._size;
        double nLeavesQty = oLeavesQty + deltaQty;

        boolean filled = nLeavesQty<=0;

        // the price the order is pegged at given its new cap; the acknowledgement reports it
        ord._pegCap = nCap;
        double nPx = (filled) ? Double.NaN : pegPrice(ord, _bidSide.bestNonPeggedPrice(), _offerSide.bestNonPeggedPrice());
        boolean nAtLimit = !filled && _pegPriceAtLimit;

        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Replaced, (filled) ? Val_OrdStatus_Filled : Val_OrdStatus_Replaced,
                0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif),
                nCap, nQty, nShownQty,
                0.0, Double.NaN, nLeavesQty, ord._cumQty, ord._avgPx, null, nPx, 0);

        if (filled) {
            removePeggedOrder(ord);
            _activeOrders.remove(ord);
        } else {
            ContinuousLevel continuousLevel = (ord.isParked()) ? null : levelOf(ord);

            if (continuousLevel!=null && oPx==nPx) {
                // same pegged price: the order is amended in place
                ord._size = nQty;
                ord._shownSize = nShownQty;
                ord._leavesQty = nLeavesQty;
                ord._lastPx = Double.NaN;
                ord._lastQty = 0.0;
                continuousLevel.replace(ord, deltaQty, oShownQty, oLeavesQty, nShownQty, nLeavesQty);
                if (setPegPrice(ord, nPx, nAtLimit)) restated(ord);
            } else {
                // the new cap changes the pegged price: the order re-enters the order book
                if (continuousLevel!=null) remove(ord, continuousLevel);
                ord._size = nQty;
                ord._shownSize = nShownQty;
                ord._leavesQty = nLeavesQty;
                ord._lastPx = Double.NaN;
                ord._lastQty = 0.0;
                if (setPegPrice(ord, nPx, nAtLimit)) restated(ord);
                if (!ord.isParked()) match(ord);
            }
        }

        return afterPeggedOrderChange();
    }

    /**
     * Also sets _pegPriceAtLimit, i.e., whether the price had to be held at the limit price of the order.
     * @return the price the order is to be pegged at given the reference prices, i.e., the best bid
     * and the best offer of the orders that are not pegged; NaN if the order has no reference price
     */
    private double pegPrice(Order ord, double refBid, double refOffer) {
        PegInstruction peg = ord._peg;
        boolean isBuy = ord._side==Side.Buy;
        _pegPriceAtLimit = false;

        double refPx;
        switch (peg._priceType) {
            case Val_PegPriceType_Primary: refPx = (isBuy) ? refBid : refOffer; break;
            case Val_PegPriceType_Market: refPx = (isBuy) ? refOffer : refBid; break;
            default: refPx = (refBid + refOffer) / 2.0; break; // Mid Price
        }
        if (Double.isNaN(refPx)) return Double.NaN;

        // when ordering by price, a higher price makes a buy more aggressive and a sell more passive;
        // it is the other way around when ordering by yield
        boolean higherIsMoreAggressive = isBuy == (_ordering==Instrument.ORDERING_PRICE);

        double px = refPx + peg.offset(refPx, _instrument.getMinPriceIncrement());
        px = _instrument.roundToPriceIncrement(px, higherIsMoreAggressive == peg.isRoundMoreAggressive());

        // the optional Price of a pegged order is an absolute cap: the order never goes beyond it
        double cap = ord._pegCap;
        if (!Double.isNaN(cap)) {
            double cappedPx = (higherIsMoreAggressive) ? Math.min(px, cap) : Math.max(px, cap);
            _pegPriceAtLimit = cappedPx!=px;
            px = cappedPx;
        }
        return px;
    }

    /**
     * Gives a pegged order the pegged price that was just calculated for it.
     * @return true if the order has to be restated to its owner: it was parked or unparked, or it started
     * or stopped being held at its limit. An order that is merely repriced is not restated.
     */
    private boolean setPegPrice(Order ord, double px, boolean atLimit) {
        boolean restate = ord.isParked()!=Double.isNaN(px) || ord._pegAtLimit!=atLimit;
        ord._price = px;
        ord._pegAtLimit = atLimit;
        return restate;
    }

    /** To be called after the order book changed because of an order that is not pegged. */
    private MarketDataSnapshot afterBookChange(MarketDataSnapshot mds) {
        if (_peggedOrders.isEmpty()) return mds;
        return (repegAll()) ? getSnapshot() : mds;
    }

    /**
     * To be called after a pegged order was added, amended or removed, with _mdsBefore holding the Market
     * Data as it was before. The Market Data is published only if it changed: hidden and parked orders
     * must not be given away by snapshots that show no change.
     */
    private MarketDataSnapshot afterPeggedOrderChange() {
        repegAll();
        MarketDataSnapshot mds = getSnapshot();
        return (mds.hasSameEntries(_mdsBefore)) ? null : mds;
    }

    /** @return true if at least one pegged order was repriced */
    private boolean repegAll() {
        boolean repriced = false;
        // a repriced order may trade, and that may change the reference prices: repeat until it settles
        while (repegOnce()) {
            repriced = true;
        }
        return repriced;
    }

    private boolean repegOnce() {
        if (_peggedOrders.isEmpty()) return false;

        double refBid = _bidSide.bestNonPeggedPrice();
        double refOffer = _offerSide.bestNonPeggedPrice();

        // first all the orders whose pegged price changed leave the order book...
        _repricedOrders.clear();
        for (int i=0; i<_peggedOrders.size(); i++) {
            Order ord = _peggedOrders.get(i);
            double oPx = ord._price;
            double nPx = pegPrice(ord, refBid, refOffer);
            boolean nAtLimit = _pegPriceAtLimit;
            if (oPx==nPx || (Double.isNaN(oPx) && Double.isNaN(nPx))) {
                // the order stays where it is, yet it may have started or stopped being held at its limit
                if (setPegPrice(ord, nPx, nAtLimit)) restated(ord);
                continue;
            }

            if (!ord.isParked()) removeFromBook(ord);
            boolean restate = setPegPrice(ord, nPx, nAtLimit);
            _repricedOrders.add(ord);
            if (restate) restated(ord);
        }

        // ...and only then they re-enter it, in arrival order, at their new price (unless they are now parked)
        for (int i=0; i<_repricedOrders.size(); i++) {
            Order ord = _repricedOrders.get(i);
            if (!ord.isParked()) match(ord);
        }

        return !_repricedOrders.isEmpty();
    }

    /**
     * Sends the Restated execution report that tells the owner of a pegged order that the order stopped
     * or resumed following its reference price:
     * - it reached its limit price and is held there, or the price to peg at is back within the limit;
     * - it was parked for lack of a reference price, or unparked.
     * The Price is the limit price (the cap, if any) of an order that is held at its limit or parked,
     * and the pegged price of an order that follows its reference price again. The PeggedPrice is the
     * price the order rests at; an order that is parked has none.
     */
    private void restated(Order ord) {
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null,
                Val_ExecType_Restated, (ord._cumQty>0.0) ? Val_OrdStatus_PartiallyFilled : Val_OrdStatus_New,
                0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif),
                (ord.isParked()) ? ord.clientPrice() : ord._price, ord._size, ord._shownSize,
                0.0, Double.NaN, ord._leavesQty, ord._cumQty, ord._avgPx, null,
                ord.peggedPrice(), Val_ExecRestatementReason_RepricingOfOrder);
    }

    private void removePeggedOrder(Order ord) {
        _peggedOrders.remove(ord);
        if (!ord.isParked()) removeFromBook(ord);
    }

    private void removeFromBook(Order ord) {
        ContinuousLevel continuousLevel = levelOf(ord);
        if (continuousLevel!=null) remove(ord, continuousLevel);
    }

    private ContinuousLevel levelOf(Order ord) {
        if (ord._side==Side.Buy) {
            return _bidSide.findLevel(ord, _ordering==Instrument.ORDERING_PRICE);
        } else {
            return _offerSide.findLevel(ord, _ordering==Instrument.ORDERING_YIELD);
        }
    }

    /** The order left the order book for good. */
    private void done(Order ord) {
        _activeOrders.remove(ord);
        if (ord.isPegged()) _peggedOrders.remove(ord);
    }

    // -----------------------------------------------------------------------------------------------



    private void cancel(Order ord, String text) {
        _activeOrders.remove(ord);
        // send Cancel back to client
        ord._lastPx = Double.NaN;
        ord._lastQty = 0.0;
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Canceled, Val_OrdStatus_Canceled, 0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord.clientPrice(),
                ord._size, ord._shownSize, ord._lastQty, ord._lastPx, ord._leavesQty, ord._cumQty, ord._avgPx, text, ord.peggedPrice(), 0);
    }

    private boolean isExecutable(Order ord) {
        if (ord._tif==TimeInForce.STO) return false;
        if (_ordering==Instrument.ORDERING_PRICE) {
            if (ord._side==Side.Buy) {
                return !_offerSide.isEmpty() && ord._price >= _offerSide.priceAtDepth(0);
            } else {
                return !_bidSide.isEmpty() && ord._price <= _bidSide.priceAtDepth(0);
            }
        } else { // YIELD
            if (ord._side==Side.Buy) {
                return !_offerSide.isEmpty() && ord._price <= _offerSide.priceAtDepth(0);
            } else {
                return !_bidSide.isEmpty() && ord._price >= _bidSide.priceAtDepth(0);
            }
        }
    }

    private void fill(Order ord, ContinuousSide side, boolean descending) {
        // fill as much as possible of the remaining quantity of the order
        // send as many fills as necessary to both the aggressing and resting orders
        // remove the matched orders from the order book
        // update the order leavesQty amount

        // an order that re-enters the order book (a pegged order that was repriced, an amended order)
        // may already have executions: this sweep is reported on its own, and then added to them
        double pCumQty = ord._cumQty;
        double pAvgPx = ord._avgPx;

        ord._lastQty = ord._cumQty = 0.0;
        ord._lastPx = ord._avgPx = Double.NaN;

        while (isExecutable(ord) && ord._leavesQty>0.0) {
            ContinuousLevel tob = side.level(0);

            for (int i=0; i<tob.ordersCount(); i++) {
                Order o = tob.get(i);
                o._lastQty = 0.0;
                o._lastPx = Double.NaN;
            }

            boolean levelStillHasSize;
            do {
                levelStillHasSize = false;
                for (int i=0; i<tob.ordersCount(); i++) {
                    Order o = tob.get(i);
                    if (o._leavesQty>0.0) {
                        double oShownQty = o.displayQty();

                        double fillQty = Math.min(ord._leavesQty, o.matchableQty());
                        double fillPx = tob.getPrice();

                        ord.fill(fillQty, fillPx, true); // first fill of 'ord' possibly over multiple price levels
                        o.fill(fillQty, fillPx, false); // 'o' fill is at only one price level

                        double nShownQty = o.displayQty();
                        tob.fill(fillQty, nShownQty - oShownQty);

                        if (o._leavesQty>0.0) {
                            levelStillHasSize = true;
                        }
                    }
                    if (ord._leavesQty<=0.0) break; // ord has been fully filled
                }
            } while (ord._leavesQty>0.0 && levelStillHasSize);

            for (int i=0; i<tob.ordersCount(); i++) {
                Order o = tob.get(i);
                if (o._lastQty>0.0) {
                    char ordStatus = (o._leavesQty<=0.0)?Val_OrdStatus_Filled:Val_OrdStatus_PartiallyFilled;
                    _server.sendExecutionReport(o._selectionKey, o._user, o._orderID, o._clOrdID, null,
                            Val_ExecType_Trade, ordStatus, 0, _securityID, Side.toFix(o._side), OrdType.toFix(o._ordType), TimeInForce.toFix(o._tif),
                            o.clientPrice(), o._size, o._shownSize,
                            o._lastQty, o._lastPx, o._leavesQty, o._cumQty, o._avgPx, null, o.peggedPrice(), 0);
                }
            }

            for (int i=tob.ordersCount()-1; i>=0; i--) {
                Order o = tob.get(i);
                if (o._leavesQty<=0.0) {
                    tob.remove(i);
                    done(o);
                }
            }
            if (tob.hasNoOrders()) {
                side.remove(tob);
            }
        }

        if (pCumQty>0.0) {
            ord._avgPx = (ord._cumQty>0.0) ? (pCumQty*pAvgPx + ord._cumQty*ord._avgPx) / (pCumQty + ord._cumQty) : pAvgPx;
            ord._cumQty += pCumQty;
        }

        char ordStatus = (ord._leavesQty<=0.0)?Val_OrdStatus_Filled:Val_OrdStatus_PartiallyFilled;
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null,
                Val_ExecType_Trade, ordStatus, 0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif),
                ord.clientPrice(), ord._size, ord._shownSize,
                ord._lastQty, ord._lastPx, ord._leavesQty, ord._cumQty, ord._avgPx, null, ord.peggedPrice(), 0);
        if (ord._leavesQty<=0.0) {
            done(ord);
        }
    }

    @VisibleForTesting
    public ContinuousLevel bidsAtLevel(int index) {
        return _bidSide.level(index);
    }
    @VisibleForTesting
    public ContinuousLevel offersAtLevel(int index) {
        return _offerSide.level(index);
    }

    @VisibleForTesting
    public int bidLevels() {
        return _bidSide.levelsCount();
    }
    @VisibleForTesting
    public int offerLevels() {
        return _offerSide.levelsCount();
    }

    public void forAllSummarizedOrders(boolean isOpenAuction, SummarizedOrdersConsumer consumer) {
        if (isOpenAuction) {
            List<AccumulatingLevel> levels = _accumulatingOrderBook._levels;
            for (int i=0; i<levels.size(); i++) {
                AccumulatingLevel level = levels.get(i);
                SummarizedOrders summarizedOrders = level._sumBids;
                if (summarizedOrders.hasOrders()) consumer.accept(level.getPrice(), Side.Buy, summarizedOrders);
                summarizedOrders = level._sumOffers;
                if (summarizedOrders.hasOrders()) consumer.accept(level.getPrice(), Side.Sell, summarizedOrders);
            }
        } else {
            List<ContinuousLevel> levels = _bidSide._levels;
            for (int i=0; i<levels.size(); i++) {
                ContinuousLevel level = levels.get(i);
                SummarizedOrders summarizedOrders = level._sumOrders;
                if (summarizedOrders.hasOrders()) consumer.accept(level.getPrice(), Side.Buy, summarizedOrders);
            }
            levels = _offerSide._levels;
            for (int i=0; i<levels.size(); i++) {
                ContinuousLevel level = levels.get(i);
                SummarizedOrders summarizedOrders = level._sumOrders;
                if (summarizedOrders.hasOrders()) consumer.accept(level.getPrice(), Side.Sell, summarizedOrders);
            }
        }
    }
}
