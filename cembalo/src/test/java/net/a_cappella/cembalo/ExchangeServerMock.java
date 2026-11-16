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

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.*;
import net.a_cappella.cembalo.constants.Operation;
import net.a_cappella.cembalo.cukes.adaptors.*;
import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;
import net.a_cappella.cembalo.fix.FixOrderRequestDecoder;
import net.a_cappella.cembalo.message.TimerMsg;
import net.a_cappella.cembalo.message.TimerMsgs;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import static net.a_cappella.cembalo.generated.FixConstants.MsgType_NewOrderSingle;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelRequest;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

public class ExchangeServerMock implements IExchangeServer, IOrderRequestHandler {
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
        sendExecutionReport(key, uid, orderID, clOrdID, origClOrdID, execType, ordStatus, ordRejReason,
                symbol, side, ordType, timeInForce, price, qty, shownQty,
                lastQty, lastPx, leavesQty, cumQty, avgPx, text, Double.NaN, 0);
    }

    @Override
    public void sendExecutionReport(SelectionKey key,
                                    String uid, long orderID, String clOrdID, String origClOrdID,
                                    char execType, char ordStatus, int ordRejReason,
                                    String symbol, char side, char ordType, char timeInForce,
                                    double price, double qty, double shownQty,
                                    double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx,
                                    String text, double peggedPrice, int execRestatementReason) {
        CukeExecutionReport cukeOrder = new CukeExecutionReport(
                uid, orderID, clOrdID, symbol, OrdType.toString(ordType), TimeInForce.toString(timeInForce),
                Side.toString(side), shownQty, qty, price,
                ExecType.toString(execType), OrdStatus.toString(ordStatus),
                lastQty, lastPx, cumQty, leavesQty, avgPx,
                text, peggedPrice, execRestatementReason
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
                cukeOrder.getPrice(), cukeOrder.getShownQty(), cukeOrder.getQty(), cukeOrder.getPeg());

        assertEquals(cukeOrder.getOrdId(), (ord==null) ? 0 : ord._orderID, "OrdId");
    }

    public void discardAllMessagesSentSoFar() {
        _erList.clear();
        _rejList.clear();
        _mdsMap.clear();
        _imbalanceBySecId.clear();
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

    public void orderIsPeggedAt(long ordId, double price) {
        Order ord = _activeOrders.get(ordId);
        assertNotNull(ord, "Unknown order "+ordId);
        assertTrue(ord.isPegged(), "Order "+ordId+" is not a pegged order");
        assertFalse(ord.isParked(), "Order "+ordId+" is parked");
        assertEquals(price, ord._price, EPSILON, "pegged price of order "+ordId);

        // the order must also rest at the price level of its pegged price
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(ord._securityID)._continuousOrderBook;
        boolean isBuy = ord._side == Side.Buy;
        int levels = (isBuy) ? continuousOrderBook.bidLevels() : continuousOrderBook.offerLevels();
        for (int i=0; i<levels; i++) {
            ContinuousLevel continuousLevel = (isBuy) ? continuousOrderBook.bidsAtLevel(i) : continuousOrderBook.offersAtLevel(i);
            for (int j=0; j<continuousLevel.ordersCount(); j++) {
                if (continuousLevel.get(j) == ord) {
                    assertEquals(price, continuousLevel.getPrice(), 0.0, "price level of order "+ordId);
                    return;
                }
            }
        }
        fail("Order "+ordId+" is not in the order book");
    }

    public void orderIsParked(long ordId) {
        Order ord = _activeOrders.get(ordId);
        assertNotNull(ord, "Unknown order "+ordId);
        assertTrue(ord.isParked(), "Order "+ordId+" is not parked, it is pegged at "+ord._price);

        // a parked order is not in the order book
        ContinuousOrderBook continuousOrderBook = _matcherBySecId.get(ord._securityID)._continuousOrderBook;
        for (int i=0; i<continuousOrderBook.bidLevels(); i++) {
            ContinuousLevel continuousLevel = continuousOrderBook.bidsAtLevel(i);
            for (int j=0; j<continuousLevel.ordersCount(); j++) {
                assertNotSame(ord, continuousLevel.get(j), "Parked order "+ordId+" is in the order book");
            }
        }
        for (int i=0; i<continuousOrderBook.offerLevels(); i++) {
            ContinuousLevel continuousLevel = continuousOrderBook.offersAtLevel(i);
            for (int j=0; j<continuousLevel.ordersCount(); j++) {
                assertNotSame(ord, continuousLevel.get(j), "Parked order "+ordId+" is in the order book");
            }
        }
    }

    public void orderIsNotActive(long ordId) {
        assertNull(_activeOrders.get(ordId), "Order "+ordId+" is still active");
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



    // ---------------------------------------- FIX layer ----------------------------------------
    // The order requests below arrive as FIX messages: they go over the wire (encode/decode), they are
    // decoded by FixOrderRequestDecoder, the decoder the ExchangeServer uses, and they end up in the
    // IOrderRequestHandler methods of this mock, which pass them to the matcher as the ExchangeServer does.

    public void aFixMessageIsReceived(String fixMsgName, Map<String, String> entry) {
        switch (fixMsgName) {
            case "NewOrderSingle":
                FixOrderRequestDecoder.newOrderSingle(_key, CukeFixMessage.overTheWire(CukeFixMessage.build(MsgType_NewOrderSingle, entry)), this);
                break;
            case "OrderCancelRequest":
                FixOrderRequestDecoder.orderCancelRequest(_key, CukeFixMessage.overTheWire(CukeFixMessage.build(MsgType_OrderCancelRequest, entry)), this);
                break;
            case "OrderCancelReplaceRequest":
                FixOrderRequestDecoder.orderCancelReplaceRequest(_key, CukeFixMessage.overTheWire(CukeFixMessage.build(MsgType_OrderCancelReplaceRequest, entry)), this);
                break;
            default:
                fail("Unknown FIX message "+fixMsgName);
        }
    }

    // the NewOrderSingle is built the way the ExchangeClient builds it
    public void aNewOrderIsSentByAnExchangeClient(CukeOrder cukeOrder) {
        cukeOrder.adjustShownQty();

        FixMessage fixMessage = new FixMessage(new FixFields());
        fixMessage.newOrderSingle(cukeOrder.getUid(), cukeOrder.getClOrdId(), cukeOrder.getSecId(),
                OrdType.fromFix(OrdType.toFix(cukeOrder.getOrdType())), TimeInForce.fromFix(TimeInForce.toFix(cukeOrder.getTif())), Side.fromFix(Side.toFix(cukeOrder.getSide())),
                cukeOrder.getPrice(), cukeOrder.getShownQty(), cukeOrder.getQty(), cukeOrder.getPeg());

        FixOrderRequestDecoder.newOrderSingle(_key, CukeFixMessage.overTheWire(fixMessage), this);
    }

    @Override
    public void handleNewOrderSingle(SelectionKey key, String uid, String clOrdID, String securityID,
                                     char ordType, char tif, char side, double px, double qtyShown, double qty, PegInstruction peg) {
        Matcher matcher = _matcherBySecId.get(securityID);
        assertNotNull(matcher, "Unknown instrument "+securityID);
        matcher.handleNewOrderSingle(key, uid, clOrdID, securityID, ordType, tif, side, px, qtyShown, qty, peg);
    }

    @Override
    public void handleOrderCancelRequest(SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID,
                                         char side, double qty) {
        Order ord = _activeOrders.get(orderID);
        assertNotNull(ord, "Unknown order "+orderID);
        _matcherBySecId.get(ord._securityID).handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, ord._securityID, side, qty, ord);
    }

    @Override
    public void handleOrderCancelReplaceRequest(SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID,
                                                double px, double qtyShown, double qty, char ordType, char side, char tif) {
        Order ord = _activeOrders.get(orderID);
        assertNotNull(ord, "Unknown order "+orderID);
        _matcherBySecId.get(ord._securityID).handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, ord._securityID, px, qtyShown, qty, ordType, side, tif, ord);
    }
}
