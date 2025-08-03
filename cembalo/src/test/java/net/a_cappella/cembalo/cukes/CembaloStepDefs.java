package net.a_cappella.cembalo.cukes;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.Map;

import io.cucumber.java.DataTableType;
import io.cucumber.java.ParameterType;
import net.a_cappella.cembalo.ExchangeServerMock;
import net.a_cappella.cembalo.Instrument;
import net.a_cappella.cembalo.cukes.adaptors.CukeAuctionLevel;
import net.a_cappella.cembalo.cukes.adaptors.CukeBookOrder;
import net.a_cappella.cembalo.cukes.adaptors.CukeExecutionReport;
import net.a_cappella.cembalo.cukes.adaptors.CukeImbalance;
import net.a_cappella.cembalo.cukes.adaptors.CukeMarketDataSnapshot;
import net.a_cappella.cembalo.cukes.adaptors.CukeOrder;
import net.a_cappella.cembalo.cukes.adaptors.CukeRejection;
import io.cucumber.java.After;
import io.cucumber.java.Before;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.When;
import io.cucumber.java.en.Then;

public class CembaloStepDefs {

    private final ExchangeServerMock _server = new ExchangeServerMock();

    private static double parseDoubleNaN(String str) {
        if (str == null) return Double.NaN;
        if ("".equals(str.trim())) return Double.NaN;
        if ("NaN".equalsIgnoreCase(str)) return Double.NaN;
        if ("Inf".equalsIgnoreCase(str)) return Double.POSITIVE_INFINITY;
        if ("-Inf".equalsIgnoreCase(str)) return Double.NEGATIVE_INFINITY;
        return Double.parseDouble(str);
    }
    private static double parseDouble(String str) {
        if (str == null) return 0.0;
        if ("".equals(str.trim())) return 0.0;
        if ("NaN".equalsIgnoreCase(str)) return Double.NaN;
        return Double.parseDouble(str);
    }

    @ParameterType(".+")
    public double price(String string) {
        return parseDoubleNaN(string);
    }

    @DataTableType
    public Instrument instrumentEntry(Map<String, String> entry) {
        return new Instrument(
                entry.get("symbol"),
                entry.get("secId"),
                parseDouble(entry.get("minQty")),
                parseDouble(entry.get("minQtyIncrement")),
                parseDouble(entry.get("minPriceIncrement")),
                Integer.parseInt(entry.get("ordering")),
                Integer.parseInt(entry.get("maxLevels"))
        );
    }
    @DataTableType
    public CukeOrder orderEntry(Map<String, String> entry) {
        return new CukeOrder(
                entry.get("uid"),
                Long.parseLong(entry.get("ordId")),
                entry.get("clOrdId"),
                entry.get("secId"),
                entry.get("ordType"),
                entry.get("tif"),
                entry.get("side"),
                parseDouble(entry.get("shownQty")),
                parseDouble(entry.get("qty")),
                parseDoubleNaN(entry.get("price"))
        );
    }
    @DataTableType
    public CukeMarketDataSnapshot marketDataSnapshotEntry(Map<String, String> entry) {
        return new CukeMarketDataSnapshot(
                parseDouble(entry.get("bidQ4")),
                parseDoubleNaN(entry.get("bid4")),
                parseDouble(entry.get("bidQ3")),
                parseDoubleNaN(entry.get("bid3")),
                parseDouble(entry.get("bidQ2")),
                parseDoubleNaN(entry.get("bid2")),
                parseDouble(entry.get("bidQ1")),
                parseDoubleNaN(entry.get("bid1")),
                parseDouble(entry.get("bidQ0")),
                parseDoubleNaN(entry.get("bid0")),
                parseDouble(entry.get("askQ0")),
                parseDoubleNaN(entry.get("ask0")),
                parseDouble(entry.get("askQ1")),
                parseDoubleNaN(entry.get("ask1")),
                parseDouble(entry.get("askQ2")),
                parseDoubleNaN(entry.get("ask2")),
                parseDouble(entry.get("askQ3")),
                parseDoubleNaN(entry.get("ask3")),
                parseDouble(entry.get("askQ4")),
                parseDoubleNaN(entry.get("ask4"))
        );
    }
    @DataTableType
    public CukeBookOrder bookOrderEntry(Map<String, String> entry) {
        return new CukeBookOrder(
                entry.get("uid"),
                Long.parseLong(entry.get("ordId")),
                entry.get("clOrdId"),
                entry.get("secId"),
                entry.get("ordType"),
                entry.get("tif"),
                entry.get("side"),
                parseDouble(entry.get("shownQty")),
                parseDouble(entry.get("qty")),
                parseDoubleNaN(entry.get("price")),
                parseDoubleNaN(entry.get("lastQty")),
                parseDoubleNaN(entry.get("lastPx")),
                parseDouble(entry.get("cumQty")),
                parseDouble(entry.get("leavesQty")),
                parseDoubleNaN(entry.get("avgPx"))
        );
    }
    @DataTableType
    public CukeExecutionReport executionReportEntry(Map<String, String> entry) {
        return new CukeExecutionReport(
                entry.get("uid"),
                Long.parseLong(entry.get("ordId")),
                entry.get("clOrdId"),
                entry.get("secId"),
                entry.get("ordType"),
                entry.get("tif"),
                entry.get("side"),
                parseDouble(entry.get("shownQty")),
                parseDouble(entry.get("qty")),
                parseDoubleNaN(entry.get("price")),
                entry.get("execType"),
                entry.get("ordStatus"),
                parseDouble(entry.get("lastQty")),
                parseDoubleNaN(entry.get("lastPx")),
                parseDouble(entry.get("cumQty")),
                parseDouble(entry.get("leavesQty")),
                parseDoubleNaN(entry.get("avgPx")),
                entry.get("text")
        );
    }
    @DataTableType
    public CukeRejection rejectionEntry(Map<String, String> entry) {
        return new CukeRejection(
                entry.get("uid"),
                Long.parseLong(entry.get("ordId")),
                entry.get("clOrdId"),
                entry.get("ordStatus"),
                entry.get("text")
        );
    }
    @DataTableType
    public CukeAuctionLevel auctionLevelEntry(Map<String, String> entry) {
        return new CukeAuctionLevel(
                parseDoubleNaN(entry.get("price")),
                parseDouble(entry.get("bidSize")),
                parseDouble(entry.get("offerSize")),
                parseDouble(entry.get("bidPressure")),
                parseDouble(entry.get("offerPressure")),
                parseDouble(entry.get("matched")),
                parseDouble(entry.get("surplus")),
                entry.get("surplusSide")
        );
    }
    @DataTableType
    public CukeImbalance imbalanceEntry(Map<String, String> entry) {
        return new CukeImbalance(
                parseDoubleNaN(entry.get("price")),
                parseDouble(entry.get("matched")),
                parseDouble(entry.get("surplus")),
                entry.get("side")
        );
    }


    @Before
    public void setupScenario() {
        _server.setup();
    }

    @After
    public void tearDownScenario() {
        _server.tearDown();
    }

    @Given("^the server is set up with strictRwt$")
    public void theServerIsSetUpWithStrictRwt() throws Throwable {
        _server.setStrictRwt(true);
    }

    @Given("^the set of available instruments is$")
    public void theSetOfAvailableInstrumentsIs(List<Instrument> instruments) throws Throwable {
        _server.theSetOfAvailableInstrumentsIs(instruments);
    }

    @Given("^all books are initialized in open matching state$")
    public void allBooksAreInitializedInOpenMatchingState() throws Throwable {
        _server.allBooksAreInitializedInOpenMatchingState();
    }

    @Given("^exchange starts with no active orders$")
    public void exchangeStartsWithNoActiveOrders() throws Throwable {
        _server.exchangeStartsWithNoActiveOrders();
    }

    @When("^a new order is received$")
    public void aNewOrderIsReceived(List<CukeOrder> cukeOrders) throws Throwable {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aNewOrderIsReceived(cukeOrder);
        }
    }

    @When("^a replacement request is received$")
    public void aReplacementRequestIsReceived(List<CukeOrder> cukeOrders) throws Throwable {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aReplacementRequestIsReceived(cukeOrder);
        }
    }

    @When("^a cancel request is received$")
    public void aCancelRequestIsReceived(List<CukeOrder> cukeOrders) throws Throwable {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aCancelRequestIsReceived(cukeOrder);
        }
    }

    @Then("^no market data snapshot for (.+) is sent$")
    public void noMarketDataSnapshotIsSent(String secId) throws Throwable {
        _server.noMarketDataSnapshotIsSent(secId);
    }

    @Then("^a market data snapshot for (.+) is sent to subscribers$")
    public void aMarketDataSnapshotIsSentToSubscribers(String secId, List<CukeMarketDataSnapshot> cukeMdsList) throws Throwable {
        assertEquals(1, cukeMdsList.size(), "mds list size");
        CukeMarketDataSnapshot cukeMds = cukeMdsList.get(0);
        _server.aMarketDataSnapshotIsSentToSubscribers(secId, cukeMds);
    }

    @Then("^the continuous order book for (.+) is empty$")
    public void thereAreNoContinuousOrdersFor(String secId) throws Throwable {
        _server.thereAreNoContinuousOrdersFor(secId);
    }

    @Then("^there are no continuous orders for instrument (.+) and side (.+) at level (\\d+)$")
    public void noConstituentOrdersForInstrumentAndSideAtLevel(String secId, String side, int level) throws Throwable {
        _server.noConstituentOrdersForInstrumentAndSideAtLevel(secId, side, level);
    }

    @Then("^the continuous orders for (.+) and side (.+) at level (\\d+) with price (.+) and leaves (.+) and shown (.+) are$")
    public void theContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(
            String secId, String side, int cukeLevel, double price, double leavesQty, double shownQty, List<CukeBookOrder> cukeOrders) throws Throwable {
        _server.theContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(secId, side, cukeLevel, price, leavesQty, shownQty, cukeOrders);
    }

    @Then("^all continuous orders for (.+) are$")
    public void allContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(String secId, List<CukeBookOrder> cukeOrders) throws Throwable {
        _server.allContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(secId, cukeOrders);
    }

    @Then("^no execution reports are sent$")
    public void noExecutionReportsAreSent() throws Throwable {
        _server.noExecutionReportsAreSent();
    }

    @Then("^all execution reports sent back to clients are$")
    public void allExecutionReportsSentBackToClientsAre(List<CukeExecutionReport> expectedErs) throws Throwable {
        _server.allExecutionReportsSentBackToClientsAre(expectedErs);
    }

    @Then("^all rejections sent back to clients are$")
    public void allRejectionsSentBackToClientsAre(List<CukeRejection> expectedRejections) throws Throwable {
        _server.allRejectionsSentBackToClientsAre(expectedRejections);
    }

    @When("^the (.+) order book receives (?:an|a) (.+) timer event$")
    public void theOrderBookReceivesAnImbalanceTimerEvent(String bookType, String opType) throws Throwable {
        _server.theOrderBookReceivesAnImbalanceTimerEvent(bookType, opType);
    }

    @Then("^the (.+) accumulating order book for (.+) is empty$")
    public void theAuctionOrderBookForIsEmpty(String auctionType, String secId) throws Throwable {
        _server.theAuctionOrderBookForIsEmpty(auctionType, secId);
    }

    @Then("^the (.+) accumulating order book for (.+) contains$")
    public void theAuctionOrderBookForContains(String auctionType, String secId, List<CukeAuctionLevel> expectedLevels) throws Throwable {
        _server.theAuctionOrderBookForContains(auctionType, secId, expectedLevels);
    }

    @Then("^the accumulated orders for (.+) and the (.+) order book filtered by side (.+) and price (.+) are$")
    public void theAccumulatedOrdersForInstrumentAndTheOrderBookFilteredBySideAtPriceAre(String secId, String auctionType, String side, double price, List<CukeBookOrder> cukeOrders) throws Throwable {
        _server.theAccumulatedOrdersForInstrumentAndTheOrderBookFilteredBySideAtPriceAre(secId, auctionType, side, price, cukeOrders);
    }

    @Then("^all accumulated orders for (.+) and the (.+) order book are$")
    public void allAccumulatedOrdersForAndTheOrderBookAre(String secId, String auctionType, List<CukeBookOrder> cukeOrders) throws Throwable {
        _server.allAccumulatedOrdersForAndTheOrderBookAre(secId, auctionType, cukeOrders);
    }

    @Then("^the imbalance market data snapshot for (.+) is$")
    public void theImbalanceMarketDataSnapshotForIs(String secId, List<CukeImbalance> cukeImbalance) throws Throwable {
        _server.theImbalanceMarketDataSnapshotForIs(secId, cukeImbalance);
    }

    @When("^user (.+) logs out$")
    public void userLogsOut(String uid) throws Throwable {
        _server.userLogsOut(uid);
    }
}
