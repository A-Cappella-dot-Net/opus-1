package net.a_cappella.cembalo;

//import static org.junit.Assert.assertEquals;
//import static org.junit.Assert.assertFalse;
//import static org.junit.Assert.assertNotNull;
//import static org.junit.Assert.assertNull;
//import static org.junit.Assert.assertTrue;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import static org.mockito.Mockito.mock;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.ExecType;
import net.a_cappella.cembalo.constants.Operation;
import net.a_cappella.cembalo.constants.OrdStatus;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.cembalo.cukes.adaptors.CukeAuctionLevel;
import net.a_cappella.cembalo.cukes.adaptors.CukeBookOrder;
import net.a_cappella.cembalo.cukes.adaptors.CukeExecutionReport;
import net.a_cappella.cembalo.cukes.adaptors.CukeImbalance;
import net.a_cappella.cembalo.cukes.adaptors.CukeMarketDataSnapshot;
import net.a_cappella.cembalo.cukes.adaptors.CukeOrder;
import net.a_cappella.cembalo.cukes.adaptors.CukeRejection;
import net.a_cappella.cembalo.message.TimerMsg;
import net.a_cappella.cembalo.message.TimerMsgs;

public class ExchangeServerMock implements IExchangeServer {
    private static final double EPSILON = 0.00000001;

    private final SelectionKey _key = mock(SelectionKey.class);
    private InstrumentsCache _instrumentsCache;
    private final ActiveOrders _activeOrders = new ActiveOrders();
    private Map<String, Matcher> _matcherBySecId;

    private List<CukeExecutionReport> _erList = new ArrayList<>();
    private List<CukeRejection> _rejList = new ArrayList<>();
    private final Map<String, MarketDataSnapshot> _mdsMap = new HashMap<>();
    private final Map<String, Imbalance> _imbalanceBySecId = new HashMap<>();

    private boolean _strictRwt = false;
    public void setStrictRwt(boolean strictRwt) {
        _strictRwt = strictRwt;
    }
    @Override
    public boolean isStrictRwt() {
        return _strictRwt;
    }

    @Override
    public void sendExecutionReport(SelectionKey key,
                                    String uid, long orderID, String clOrdID, String origClOrdID,
                                    char execType, char ordStatus, int ordRejReason,
                                    String symbol, char side, char ordType, char timeInForce,
                                    double price, double qty, double shownQty,
                                    double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx,
                                    String text) {
        CukeExecutionReport cukeOrder = new CukeExecutionReport(
                uid, orderID, clOrdID, symbol, OrdType.toString(ordType), TimeInForce.toString(timeInForce),
                Side.toString(side), shownQty, qty, price,
                ExecType.toString(execType), OrdStatus.toString(ordStatus),
                lastQty, lastPx, cumQty, leavesQty, avgPx,
                text
        );
        _erList.add(cukeOrder);
    }

    @Override
    public void sendOrderCancelReject(
            final SelectionKey key, String uid,
            long orderID, String clOrdID, String origClOrdID, char ordStatus,
            char cxlRejResponseTo, int cxlRejReason, String text) {

        CukeRejection cukeOrder = new CukeRejection(uid, orderID, clOrdID, OrdStatus.toString(ordStatus), text);
        _rejList.add(cukeOrder);
    }

    @Override
    public void sendImbalanceToAllSubscribers(Imbalance imbalance) {
        if (imbalance!=null) _imbalanceBySecId.put(imbalance.getSymbol(), imbalance);
    }

    @Override
    public void sendInstrStatusToAllSubscribers(InstrumentStatus status) {

    }

    @Override
    public void sendMdsToAllSubscribers(MarketDataSnapshot mds) {
        if (mds!=null) _mdsMap.put(mds._securityID, mds);
    }

    public void setup() {

    }
    public void tearDown() {
        _imbalanceBySecId.clear(); // TODO assert it's empty to force exhaustive testing
        _mdsMap.clear(); // TODO assert it's empty
    }



    private List<CukeExecutionReport> getLatestExecutionReports() {
        List<CukeExecutionReport> list = _erList;
        _erList = new ArrayList<>();
        return list;
    }

    private List<CukeRejection> getLatestRejections() {
        List<CukeRejection> list = _rejList;
        _rejList = new ArrayList<>();
        return list;
    }

    private Imbalance getImbalance(String symbol) {
        return _imbalanceBySecId.remove(symbol);
    }

    private MarketDataSnapshot getMds(String secId) {
        return _mdsMap.remove(secId);
    }




    private Book getBook(String bookStr) {
        Book book = Book.fromString(bookStr);
        assertTrue(book != Book.NULL_VAL, "Invalid book '"+bookStr+"'");
        return book;
    }

    private TimerMsg newTimerMessage(String bookStr, String opStr) {
        Book book = Book.fromString(bookStr);
        Operation op = Operation.fromString(book, opStr);
        assertTrue(book != Book.NULL_VAL, "Invalid book '"+bookStr+"'");
        assertTrue(op != Operation.NULL_VAL, "Invalid operation '"+opStr+"'");
        return new TimerMsg(book, op);
    }



    public void theSetOfAvailableInstrumentsIs(List<Instrument> instruments) {
        _instrumentsCache = new InstrumentsCache(instruments);
        _matcherBySecId = new HashMap<>();

        for (Instrument instrument : instruments) {
            String secId = instrument.getSecId();

            Matcher matcher = new Matcher(this, _activeOrders, instrument);
            _matcherBySecId.put(secId, matcher);
        }
    }

    public void allBooksAreInitializedInOpenMatchingState() {
        for (Matcher matcher : _matcherBySecId.values()) {
            TimerMsgs timerMsgs = new TimerMsgs();
            timerMsgs.add(Book.CONTINUOUS_BK, Operation.OPEN);
            timerMsgs.add(Book.CONTINUOUS_BK, Operation.MATCHING);
            timerMsgs.add(Book.OPEN_BK, Operation.OPEN);
            timerMsgs.add(Book.OPEN_BK, Operation.ALL);
            timerMsgs.add(Book.CLOSE_BK, Operation.OPEN);
            timerMsgs.add(Book.CLOSE_BK, Operation.ALL);

            matcher.handleTimerMessage(timerMsgs);
        }
    }

    public void exchangeStartsWithNoActiveOrders() {
        _activeOrders.reset();
    }

    public void aNewOrderIsReceived(CukeOrder cukeOrder) {
        cukeOrder.adjustShownQty();

        TimeInForce tif = TimeInForce.fromFix(TimeInForce.toFix(cukeOrder.getTif()));
        assertFalse(TimeInForce.NULL_VAL.equals(tif), "Unknown Tif");

        String secId = cukeOrder.getSecId();
        Matcher matcher = _matcherBySecId.get(secId);
        assertNotNull(matcher, "Unknown instrument "+secId);

        Order ord = matcher.handleNewOrderSingle(_key, cukeOrder.getUid(), cukeOrder.getClOrdId(), cukeOrder.getSecId(),
                OrdType.toFix(cukeOrder.getOrdType()), TimeInForce.toFix(cukeOrder.getTif()), Side.toFix(cukeOrder.getSide()),
                cukeOrder.getPrice(), cukeOrder.getShownQty(), cukeOrder.getQty());

        assertEquals(cukeOrder.getOrdId(), (ord==null) ? 0 : ord._orderID, "OrdId");
    }

    public void aReplacementRequestIsReceived(CukeOrder cukeOrder) {
        cukeOrder.adjustShownQty();
        long ordId = cukeOrder.getOrdId();

        Order ord = _activeOrders.get(ordId);
        assertNotNull(ord, "Unknown order "+ordId);

        String symbol = ord._securityID;
        Matcher matcher = _matcherBySecId.get(symbol);
        assertNotNull(matcher, "Unknown instrument "+symbol);

        OrdType ordType = (cukeOrder.getOrdType()==null) ? ord._ordType : OrdType.valueOf(cukeOrder.getOrdType());
        matcher.handleOrderCancelReplaceRequest(
                _key, ord._user, ord._origClOrdID, ordId, cukeOrder.getClOrdId(), symbol,
                cukeOrder.getPrice(), cukeOrder.getShownQty(), cukeOrder.getQty(), OrdType.toFix(ordType),
                Side.toFix(ord._side), TimeInForce.toFix(ord._tif), ord);
    }

    public void aCancelRequestIsReceived(CukeOrder cukeOrder) {
        long ordId = cukeOrder.getOrdId();

        Order ord = _activeOrders.get(ordId);
        assertNotNull(ord, "Unknown order "+ordId);

        String symbol = ord._securityID;
        Matcher matcher = _matcherBySecId.get(symbol);
        assertNotNull(matcher, "Unknown instrument "+symbol);

        matcher.handleOrderCancelRequest(
                _key, ord._user, ord._origClOrdID, ordId, cukeOrder.getClOrdId(), symbol,
                Side.toFix(ord._side), cukeOrder.getQty(), ord);
    }

    public void noMarketDataSnapshotIsSent(String symbol) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        assertNull(getMds(symbol), "No MarketDataSnapshot expected");
    }

    public void aMarketDataSnapshotIsSentToSubscribers(String secId, CukeMarketDataSnapshot cukeMds) {
        Instrument instrument = _instrumentsCache.get(secId);
        assertNotNull(instrument, "Unknown instrument "+secId);
        MarketDataSnapshot mds = getMds(secId);
        assertNotNull(mds, "Market Data Snapshot");
        assertEquals(cukeMds.normalize(), CukeMarketDataSnapshot.adapt(mds), "MarketDataSnapshot");
    }

    public void thereAreNoContinuousOrdersFor(String symbol) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(symbol)._continuousOrderBook;
        assertEquals(0, continuousOrderBook.bidLevels(), "No Orders on the Bid Side");
        assertEquals(0, continuousOrderBook.offerLevels(), "No Orders on the Offer Side");
    }

    public void noConstituentOrdersForInstrumentAndSideAtLevel(String symbol, String side, int level) {
        assertTrue("Buy".equals(side) || "Sell".equals(side), "Illegal side");
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(symbol)._continuousOrderBook;
        if ("Buy".equals(side)) {
            assertTrue(level >= continuousOrderBook.bidLevels(), "Bids");
        } else {
            assertTrue(level >= continuousOrderBook.offerLevels(), "Offers");
        }
    }

    public void theContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(
            String symbol, String side, int cukeLevel, double price, double leavesQty, double shownQty, List<CukeBookOrder> cukeOrders) {
        assertTrue("Buy".equals(side) || "Sell".equals(side), "Illegal side" + side);
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(symbol)._continuousOrderBook;
        ContinuousLevel continuousLevel;
        if ("Buy".equals(side)) {
            assertTrue(continuousOrderBook.bidLevels()>cukeLevel, "Non existing level "+cukeLevel);
            continuousLevel = continuousOrderBook.bidsAtLevel(cukeLevel);
        } else {
            assertTrue(continuousOrderBook.offerLevels()>cukeLevel, "Non existing level "+cukeLevel);
            continuousLevel = continuousOrderBook.offersAtLevel(cukeLevel);
        }
        assertEquals(price, continuousLevel.getPrice(), EPSILON, "level price");
        assertEquals(shownQty, continuousLevel.getShownQty(), EPSILON, "shown qty");
        assertEquals(leavesQty, continuousLevel.getLeavesQty(), EPSILON, "leaves qty");
        for (CukeBookOrder cukeOrder : cukeOrders) {
            cukeOrder.setPrice(price);
        }
        assertEquals(cukeOrders.size(), continuousLevel.ordersCount(), "Number of Orders at level "+cukeLevel);
        int size = cukeOrders.size();
        List<CukeBookOrder> actuals = CukeBookOrder.book(continuousLevel);
        for (int i = 0; i < size; i++) {
            assertEquals(cukeOrders.get(i), actuals.get(i), "Orders at "+side+" level "+cukeLevel + " and index " + i);
        }
    }

    public void allContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(String symbol, List<CukeBookOrder> cukeOrders) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(symbol)._continuousOrderBook;

        List<ContinuousLevel> continuousLevels = new ArrayList<>();
        for (int i=continuousOrderBook.offerLevels()-1; i>=0; i--) {
            continuousLevels.add(continuousOrderBook.offersAtLevel(i));
        }
        for (int i=0; i<continuousOrderBook.bidLevels(); i++) {
            continuousLevels.add(continuousOrderBook.bidsAtLevel(i));
        }
        List<CukeBookOrder> actualOrders = CukeBookOrder.book(continuousLevels);
        assertEquals(cukeOrders.size(), actualOrders.size(), "Number of Orders");
        int size = cukeOrders.size();
        for (int i = 0; i < size; i++) {
            assertEquals(cukeOrders.get(i), actualOrders.get(i), "Orders at index " + i);
        }
    }

    public void noExecutionReportsAreSent() {
        List<CukeExecutionReport> ers = getLatestExecutionReports();
        assertTrue(ers.isEmpty(), "Execution reports"+ers);
    }

    public void allExecutionReportsSentBackToClientsAre(List<CukeExecutionReport> expectedErs) {
        List<CukeExecutionReport> actualErs = getLatestExecutionReports();
        assertEquals(expectedErs.size(), actualErs.size(), "Number of Execution Reports");
        int size = expectedErs.size();
        for (int i = 0; i < size; i++) {
            assertEquals(expectedErs.get(i), actualErs.get(i), "at index " + i);
        }
    }

    public void allRejectionsSentBackToClientsAre(List<CukeRejection> expectedRejections) {
        List<CukeRejection> actualRejections = getLatestRejections();
        assertEquals(expectedRejections.size(), actualRejections.size(), "Number of Rejections");
        int size = expectedRejections.size();
        for (int i = 0; i < size; i++) {
            assertEquals(expectedRejections.get(i), actualRejections.get(i), "at index " + i);
        }
    }

    public void theOrderBookReceivesAnImbalanceTimerEvent(String bookType, String opType) {
        TimerMsg timerMsg = newTimerMessage(bookType, opType);
        for (Entry<String, Matcher> entry : _matcherBySecId.entrySet()) {
            Matcher matcher = entry.getValue();
            if (timerMsg._book == Book.CONTINUOUS_BK) {
                ContinuousOrderBook continuousOrderBook = matcher._continuousOrderBook;
                continuousOrderBook.handleTimerMessage(timerMsg);
            } else {
                AuctionOrderBook auctionOrderBook = (timerMsg._book == Book.OPEN_BK) ? matcher._openAuctionOrderBook : matcher._closeAuctionOrderBook;
                auctionOrderBook.handleTimerMessage(timerMsg);
            }
        }
    }

    @SuppressWarnings("incomplete-switch")
    public void theAuctionOrderBookForIsEmpty(String auctionType, String symbol) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        Matcher matcher = _matcherBySecId.get(symbol);

        AccumulatingOrderBook<?> accumulatingOrderBook = null;
        Book book = getBook(auctionType);
        switch (book) {
            case OPEN_BK: accumulatingOrderBook = matcher._openAuctionOrderBook; break;
            case CLOSE_BK: accumulatingOrderBook = matcher._closeAuctionOrderBook; break;
            case CONTINUOUS_BK: accumulatingOrderBook = matcher._continuousOrderBook.getAccumulatingOrderBook(); break;
        }
        assertTrue(accumulatingOrderBook.isEmpty(), auctionType+" Order Book for "+symbol);
    }

    @SuppressWarnings("incomplete-switch")
    public void theAuctionOrderBookForContains(String auctionType, String symbol, List<CukeAuctionLevel> expectedLevels) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        Matcher matcher = _matcherBySecId.get(symbol);

        List<CukeAuctionLevel> actualLevels = null;
        Book book = getBook(auctionType);
        switch (book) {
            case OPEN_BK: actualLevels = CukeAuctionLevel.adapt(matcher._openAuctionOrderBook); break;
            case CLOSE_BK: actualLevels = CukeAuctionLevel.adapt(matcher._closeAuctionOrderBook); break;
            case CONTINUOUS_BK: actualLevels = CukeAuctionLevel.adapt(matcher._continuousOrderBook.getAccumulatingOrderBook()); break;
        }
        assertEquals(expectedLevels, actualLevels, auctionType+" Order Book for "+symbol);
    }

    @SuppressWarnings("incomplete-switch")
    public void theAccumulatedOrdersForInstrumentAndTheOrderBookFilteredBySideAtPriceAre(String symbol, String auctionType, String side, double price, List<CukeBookOrder> cukeOrders) {
        assertTrue("Buy".equals(side) || "Sell".equals(side), "Illegal side " + side);
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        Matcher matcher = _matcherBySecId.get(symbol);

        AccumulatingOrderBook<?> accumulatingOrderBook = null;
        Book book = getBook(auctionType);
        switch (book) {
            case OPEN_BK: accumulatingOrderBook = matcher._openAuctionOrderBook; break;
            case CLOSE_BK: accumulatingOrderBook = matcher._closeAuctionOrderBook; break;
            case CONTINUOUS_BK: accumulatingOrderBook = matcher._continuousOrderBook.getAccumulatingOrderBook(); break;
        }
        AccumulatingLevel accumulatingLevel = accumulatingOrderBook.findLevel(price);
        assertNotNull(accumulatingLevel, "Level for "+symbol+" and "+price);

        for (CukeBookOrder cukeOrder : cukeOrders) {
            if (price == Double.POSITIVE_INFINITY || price == Double.NEGATIVE_INFINITY) cukeOrder.setPrice(Double.NaN);
            else cukeOrder.setPrice(price);
        }
        List<CukeBookOrder> actualOrders = CukeBookOrder.book(accumulatingLevel, side);

        assertEquals(cukeOrders.size(), actualOrders.size(), "Number of Orders at price "+price);
        assertEquals(new ArrayList<>(cukeOrders), actualOrders, "Orders at "+side+" and price "+price);
    }

    @SuppressWarnings("incomplete-switch")
    public void allAccumulatedOrdersForAndTheOrderBookAre(String symbol, String auctionType, List<CukeBookOrder> cukeOrders) {
        Instrument instrument = _instrumentsCache.get(symbol);
        assertNotNull(instrument, "Unknown instrument "+symbol);
        Matcher matcher = _matcherBySecId.get(symbol);

        AccumulatingOrderBook<?> accumulatingOrderBook = null;
        Book book = getBook(auctionType);
        switch (book) {
            case OPEN_BK: accumulatingOrderBook = matcher._openAuctionOrderBook; break;
            case CLOSE_BK: accumulatingOrderBook = matcher._closeAuctionOrderBook; break;
            case CONTINUOUS_BK: accumulatingOrderBook = matcher._continuousOrderBook.getAccumulatingOrderBook(); break;
        }

        List<CukeBookOrder> actualOrders = CukeBookOrder.book(accumulatingOrderBook);

        assertEquals(cukeOrders.size(), actualOrders.size(), "Number of Orders");
        assertEquals(new ArrayList<>(cukeOrders), actualOrders, "All Orders");
    }

    public void theImbalanceMarketDataSnapshotForIs(String symbol, List<CukeImbalance> cukeImbalance) {
        assertEquals(1, cukeImbalance.size(), "imbalance list size");
        Imbalance imbalance = getImbalance(symbol);
        assertNotNull(imbalance, "No imbalance for instrument "+symbol);
        assertEquals(cukeImbalance.get(0), CukeImbalance.adapt(imbalance), "Imbalance");
    }

    public void userLogsOut(String uid) {
        _activeOrders.handleUserLogoff(_key, uid, order -> _matcherBySecId.get(order._securityID).cancelOrder(order));
    }
}
