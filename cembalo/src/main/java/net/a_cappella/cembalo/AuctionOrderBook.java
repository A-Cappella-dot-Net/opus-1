package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejReason_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejResponseTo_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejResponseTo_OrderCancelRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Trade;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Filled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_PartiallyFilled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Rejected;

import java.nio.channels.SelectionKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.InstrPhase;
import net.a_cappella.cembalo.constants.InstrStatus;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.cembalo.message.TimerMsg;

public class AuctionOrderBook extends AccumulatingOrderBook<AuctionLevel> {
    private static final Logger log = LoggerFactory.getLogger(AuctionOrderBook.class);

    private static final String NO_MATCH_IN_AUCTION = "No match in auction";
    private static final boolean ON_TIE_USE_HIGHER_PRICE = true;

    private final ContinuousOrderBook _continuousOrderBook;
    private final ActiveOrders _activeOrders;

    private final boolean _isOpenAuction;

    private final Imbalance _imbalance;
    private final InstrumentStatus _is;

    public AuctionOrderBook(IExchangeServer server, ActiveOrders activeOrders, Instrument instrument, ContinuousOrderBook continuousOrderBook, boolean isOpenAuction) {
        super(server, instrument, (px) -> new AuctionLevel(px));
        _continuousOrderBook = continuousOrderBook;
        _activeOrders = activeOrders;
        _isOpenAuction = isOpenAuction;
        _imbalance = new Imbalance(_securityID, (isOpenAuction) ? Book.OPEN_BK : Book.CLOSE_BK);
        _is = new InstrumentStatus(_securityID, (isOpenAuction) ? Book.OPEN_BK : Book.CLOSE_BK);
    }

    public boolean isOpen() {
        return _is._status == InstrStatus.OPEN;
    }

    public InstrumentStatus getStatus() {
        return _is;
    }

    public Imbalance getImbalance() {
        return _imbalance;
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
            case ALL:
                _is._phase = InstrPhase.ALL;
                _server.sendInstrStatusToAllSubscribers(getStatus());
                break;
            case ONLY_NEW:
                _is._phase = InstrPhase.ONLY_NEW;
                _server.sendInstrStatusToAllSubscribers(getStatus());
                break;
            case IMBALANCE:
                imbalance();
                _server.sendImbalanceToAllSubscribers(_imbalance);
                break;
            case AUCTION:
                auction();
                _server.sendImbalanceToAllSubscribers(_imbalance);
                break;
            default:
                break;
        }
    }

    public void handleNewOrderSingle(final SelectionKey key, String uid, String clOrdID, String securityID, char ordType, char tif, char side, double px, double qtyShown, double qty, Order order) {
        _activeOrders.add(order);
        addOrder(order);
    }

    public void handleOrderCancelReplaceRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, double px, double qtyShown, double qty, char ordType, char side, char tif, Order order) {
        if (_is._phase == InstrPhase.ONLY_NEW) {
            _server.sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_Other,
                    "Amend not allowed in Only New phase");
        } else {
            order._clOrdID = clOrdID;
            order._origClOrdID = origClOrdID;

            replaceOrder(order, px, qty, qtyShown, OrdType.fromFix(ordType));
        }
    }

    public void handleOrderCancelRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, char side, double qty, Order order) {
        if (_is._phase == InstrPhase.ONLY_NEW) {
            _server.sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelRequest, Val_CxlRejReason_Other,
                    "Cancel not allowed in Only New phase");
        } else {
            _activeOrders.remove(order);

            order._clOrdID = clOrdID;
            order._origClOrdID = origClOrdID;

            cancelOrder(order);
        }
    }

    private void clearContinuousSummarizedOrders() {
        for (int i=0; i<_levels.size(); i++) {
            AuctionLevel level = _levels.get(i);
            level.clearContinuousSummarizedOrders();
        }
    }

    private void transferSummarizedOrdersFromContinuousBook() {
        _continuousOrderBook.forAllSummarizedOrders(_isOpenAuction,
                (price, side, summarizedOrders) -> {
                    AuctionLevel level = findOrInsertNewLevel(price);
                    level.setContinuousSummarizedOrders(side, summarizedOrders);
                });
    }

    public Imbalance imbalance() {
        clearContinuousSummarizedOrders();
        transferSummarizedOrdersFromContinuousBook();

        int size = _levels.size();
        if (size>0) {
            AuctionLevel prevLevel = _levels.get(0);
            prevLevel.setBidPressure();
            for (int i=1; i<size; i++) {
                AuctionLevel currLevel = _levels.get(i);
                currLevel.setBidPressure(prevLevel);
                prevLevel = currLevel;
            }

            prevLevel = _levels.get(size-1);
            prevLevel.setOfferPressure();
            for (int i=size-2; i>=0; i--) {
                AuctionLevel currLevel = _levels.get(i);
                currLevel.setOfferPressure(prevLevel);
                prevLevel = currLevel;
            }

            for (int i=0; i<size; i++) {
                _levels.get(i).setMatchedSurplusAndSide();
            }

            AuctionLevel level = getImbalanceLevel();
            if (level == null || level.getMatched() == 0.0) {
                _imbalance.none();
            } else {
                _imbalance.set(level.getSurplusSide(), level.getMatched(), level.getSurplus(), level.getPrice());
            }
        } else {
            _imbalance.none();
        }
        return _imbalance;
    }

    public Imbalance auction() {
        imbalance();
        _imbalance.auction();
        auction(_imbalance.getMatched(), _imbalance.getPrice());
        _imbalance.notPublishable();
        return _imbalance;
    }

    private void auction(double matched, double price) {
        int numLevels = _levels.size();

        double stillToFill = matched;
        for (int i=0; i<numLevels; i++) {
            AuctionLevel level = _levels.get(i);
            SummarizedOrders sumBids = level._sumBids;
            for (int j=0; j<sumBids.count(); j++) {
                stillToFill = match(sumBids.getOrder(j), price, stillToFill, true, false);
            }
            sumBids.reset();
            sumBids = level._contSumBids;
            if (sumBids != null) {
                for (int j=0; j<sumBids.count(); j++) {
                    stillToFill = match(sumBids.getOrder(j), price, stillToFill, false, _isOpenAuction);
                }
                sumBids.reset();
            }
        }

        stillToFill = matched;
        for (int i=numLevels-1; i>=0; i--) {
            AuctionLevel level = _levels.get(i);
            SummarizedOrders sumOffers = level._sumOffers;
            for (int j=0; j<sumOffers.count(); j++) {
                stillToFill = match(sumOffers.getOrder(j), price, stillToFill, true, false);
            }
            sumOffers.reset();
            sumOffers = level._contSumOffers;
            if (sumOffers != null) {
                for (int j=0; j<sumOffers.count(); j++) {
                    stillToFill = match(sumOffers.getOrder(j), price, stillToFill, false, _isOpenAuction);
                }
                sumOffers.reset();
            }
        }

        _server.sendMdsToAllSubscribers(_continuousOrderBook.getSnapshot());
    }

    private double match(Order o, double price, double stillToFill, boolean isAuctionOrder, boolean transferToContinuous) {
        if (stillToFill <= 0.0) {
            if (isAuctionOrder) {
                cancel(o, NO_MATCH_IN_AUCTION);
            } else if (transferToContinuous) {
                _continuousOrderBook.match(o);
            } else {
                _continuousOrderBook.cancelOrder(o, NO_MATCH_IN_AUCTION);
            }
        } else { // matched > 0.0
            double lastQty;
            double leavesQty = o._leavesQty;
            if (leavesQty > stillToFill) { // => partial fill
                lastQty = stillToFill;
                o._avgPx = (nanSafeMultiplication(o._cumQty, o._avgPx) + lastQty*price) / (o._cumQty + lastQty);
                o._leavesQty = o._leavesQty - lastQty;
                o._cumQty = o._cumQty + lastQty;

                _server.sendExecutionReport(o._selectionKey, o._user, o._orderID, o._clOrdID, null,
                        Val_ExecType_Trade, Val_OrdStatus_PartiallyFilled, 0, _securityID, Side.toFix(o._side), OrdType.toFix(o._ordType), TimeInForce.toFix(o._tif),
                        o._price, o._size, o._shownSize,
                        lastQty, price, o._leavesQty, o._cumQty, o._avgPx, null);
                if (isAuctionOrder) {
                    cancel(o, NO_MATCH_IN_AUCTION);
                } else if (transferToContinuous) {
                    _continuousOrderBook.match(o);
                } else {
                    _continuousOrderBook.cancelOrder(o, NO_MATCH_IN_AUCTION);
                }
            } else { // oQty <= matched => full fill
                _activeOrders.remove(o);

                lastQty = o._size - o._cumQty;
                o._avgPx = (nanSafeMultiplication(o._cumQty, o._avgPx) + lastQty*price) / o._size;
                o._leavesQty = 0.0;
                o._cumQty = o._size;

                _server.sendExecutionReport(o._selectionKey, o._user, o._orderID, o._clOrdID, null,
                        Val_ExecType_Trade, Val_OrdStatus_Filled, 0, _securityID, Side.toFix(o._side), OrdType.toFix(o._ordType), TimeInForce.toFix(o._tif),
                        o._price, o._size, o._shownSize,
                        lastQty, price, o._leavesQty, o._cumQty, o._avgPx, null);
            }
            stillToFill -= lastQty;
        }
        return stillToFill;
    }

    private double nanSafeMultiplication(double qty, double px) { return Double.isNaN(px) ? 0.0 : (qty*px); }

    private AuctionLevel getImbalanceLevel() {
        int size = _levels.size();
        if (size == 0) return null;
        int i1 = 0; int i2 = 0;
        double maxMatched = 0;
        for (int i=0; i<size; i++) {
            AuctionLevel level = _levels.get(i);
            double levelMatched = level.getMatched();
            if (maxMatched < levelMatched) {
                i1 = i2 = i;
                maxMatched = levelMatched;
            } else if (maxMatched == levelMatched) {
                i2 = i;
            }
        }
        if (i1 == i2) return _levels.get(i1);
        double p1 = _levels.get(i1).getSurplus();
        double p2 = _levels.get(i2).getSurplus();
        if (p1 == p2) {
            if (p1 == 0.0) {
                // indifferent, no hurt feelings
                return _levels.get((ON_TIE_USE_HIGHER_PRICE) ? i1 : i2);
            } else {
                // indifferent, some hurt feelings (wrong side of the imbalance)
                Side s1 = _levels.get(i1).getSurplusSide();
                Side s2 = _levels.get(i2).getSurplusSide();
                if (s1 != s2) {
                    return _levels.get((ON_TIE_USE_HIGHER_PRICE) ? i1 : i2);
                }
                // same surplus side
                if (s1 == Side.Buy) return _levels.get(i1);
                else return _levels.get(i2);
            }
        } else /* minimum surplus */ if (p1 < p2) {
            return _levels.get(i1);
        } else { // s1 > s2
            return _levels.get(i2);
        }
    }
}
