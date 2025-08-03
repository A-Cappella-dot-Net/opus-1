package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Replaced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Trade;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Filled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_PartiallyFilled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Replaced;

import java.nio.channels.SelectionKey;
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

    public ContinuousOrderBook(IExchangeServer server, ActiveOrders activeOrders, Instrument instrument) {
        _server = server;
        _activeOrders = activeOrders;
        _securityID = instrument.getSecId();
        _ordering = instrument.getOrdering();
        _mds = new MarketDataSnapshot(_securityID, instrument.getMaxLevels());
        _is = new InstrumentStatus(_securityID, Book.CONTINUOUS_BK);
        _accumulatingOrderBook = new AccumulatingOrderBook<>(server, instrument, (px) -> new AccumulatingLevel(px));
    }

    public boolean isOpen() {
        return _is._status == InstrStatus.OPEN;
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

        if (_is._phase == InstrPhase.NON_MATCHING) {
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

        if (_is._phase == InstrPhase.NON_MATCHING) {
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
        ContinuousLevel continuousLevel = findLevel(ord);
        if (continuousLevel==null) return null;

        remove(ord, continuousLevel);
        return getSnapshot();
    }

    /* efficient when there are many active orders per connection; not used ATM */
    public MarketDataSnapshot removeOrders(SelectionKey selectionKey) {
        boolean stackChanged = _bidSide.removeOrders(selectionKey) | _offerSide.removeOrders(selectionKey);
        return (stackChanged) ? getSnapshot() : null;
    }

    public MarketDataSnapshot getSnapshot() {
        _mds.reset(_securityID, System.currentTimeMillis());
        for (int i=0; i<_bidSide.levelsCount(); i++) {
            _mds.setBid(i, _bidSide.priceAtDepth(i), _bidSide.sizeAtDepth(i));
        }
        for (int i=0; i<_offerSide.levelsCount(); i++) {
            _mds.setOffer(i, _offerSide.priceAtDepth(i), _offerSide.sizeAtDepth(i));
        }
        return _mds;
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
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null, Val_ExecType_New, Val_OrdStatus_New, 0,
                ord._securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord._price, ord._size, ord._shownSize, 0.0, Double.NaN, ord._size, 0.0, Double.NaN, null);
        return match(ord);
    }

    @VisibleForTesting
    public MarketDataSnapshot replaceOrder(Order ord, double nPx, double nShownQty, double nQty) {
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

        return mds;
    }

    @VisibleForTesting
    public MarketDataSnapshot cancelOrder(Order ord, String text) {
        ContinuousLevel continuousLevel = findLevel(ord);
        if (continuousLevel==null) return null;

        remove(ord, continuousLevel);
        cancel(ord, text);
        return getSnapshot();
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












    private void cancel(Order ord, String text) {
        _activeOrders.remove(ord);
        // send Cancel back to client
        ord._lastPx = Double.NaN;
        ord._lastQty = 0.0;
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Canceled, Val_OrdStatus_Canceled, 0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord._price,
                ord._size, ord._shownSize, ord._lastQty, ord._lastPx, ord._leavesQty, ord._cumQty, ord._avgPx, text);
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
                        double oShownQty = Math.min(o._leavesQty, o._shownSize);

                        double fillQty = Math.min(ord._leavesQty, oShownQty);
                        double fillPx = tob.getPrice();

                        ord.fill(fillQty, fillPx, true); // first fill of 'ord' possibly over multiple price levels
                        o.fill(fillQty, fillPx, false); // 'o' fill is at only one price level

                        double nShownQty = Math.min(o._leavesQty, o._shownSize);
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
                            o._price, o._size, o._shownSize,
                            o._lastQty, o._lastPx, o._leavesQty, o._cumQty, o._avgPx, null);
                }
            }

            for (int i=tob.ordersCount()-1; i>=0; i--) {
                Order o = tob.get(i);
                if (o._leavesQty<=0.0) {
                    tob.remove(i);
                    _activeOrders.remove(o);
                }
            }
            if (tob.hasNoOrders()) {
                side.remove(tob);
            }
        }

        char ordStatus = (ord._leavesQty<=0.0)?Val_OrdStatus_Filled:Val_OrdStatus_PartiallyFilled;
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null,
                Val_ExecType_Trade, ordStatus, 0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif),
                ord._price, ord._size, ord._shownSize,
                ord._lastQty, ord._lastPx, ord._leavesQty, ord._cumQty, ord._avgPx, null);
        if (ord._leavesQty<=0.0) {
            _activeOrders.remove(ord);
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
