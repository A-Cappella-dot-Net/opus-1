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

package net.a_cappella.cembalo.cukes;

import static net.a_cappella.cembalo.CukeUtils.parseDouble;
import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;
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

    @ParameterType(".+")
    public static double price(String string) {
        return parseDoubleNaN(string);
    }

    @DataTableType
    public Instrument dttInstrument(Map<String, String> entry) {
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


    @Before
    public void setupScenario() {
        _server.setup();
    }

    @After
    public void tearDownScenario() {
        _server.tearDown();
    }

    @Given("^the server is set up with strictRwt$")
    public void theServerIsSetUpWithStrictRwt() {
        _server.setStrictRwt(true);
    }

    @Given("^the set of available instruments is$")
    public void theSetOfAvailableInstrumentsIs(List<Instrument> instruments) {
        _server.theSetOfAvailableInstrumentsIs(instruments);
    }

    @Given("^all books are initialized in open matching state$")
    public void allBooksAreInitializedInOpenMatchingState() {
        _server.allBooksAreInitializedInOpenMatchingState();
    }

    @Given("^exchange starts with no active orders$")
    public void exchangeStartsWithNoActiveOrders() {
        _server.exchangeStartsWithNoActiveOrders();
    }

    @When("^a new order is received$")
    public void aNewOrderIsReceived(List<CukeOrder> cukeOrders) {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aNewOrderIsReceived(cukeOrder);
        }
    }

    @When("^a replacement request is received$")
    public void aReplacementRequestIsReceived(List<CukeOrder> cukeOrders) {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aReplacementRequestIsReceived(cukeOrder);
        }
    }

    @When("^a cancel request is received$")
    public void aCancelRequestIsReceived(List<CukeOrder> cukeOrders) {
        for (CukeOrder cukeOrder : cukeOrders) {
            _server.aCancelRequestIsReceived(cukeOrder);
        }
    }

    @Then("^no market data snapshot for (.+) is sent$")
    public void noMarketDataSnapshotIsSent(String secId) {
        _server.noMarketDataSnapshotIsSent(secId);
    }

    @Then("^a market data snapshot for (.+) is sent to subscribers$")
    public void aMarketDataSnapshotIsSentToSubscribers(String secId, List<CukeMarketDataSnapshot> cukeMdsList) {
        assertEquals(1, cukeMdsList.size(), "mds list size");
        CukeMarketDataSnapshot cukeMds = cukeMdsList.get(0);
        _server.aMarketDataSnapshotIsSentToSubscribers(secId, cukeMds);
    }

    @Then("^the continuous order book for (.+) is empty$")
    public void thereAreNoContinuousOrdersFor(String secId) {
        _server.thereAreNoContinuousOrdersFor(secId);
    }

    @Then("^there are no continuous orders for instrument (.+) and side (.+) at level (\\d+)$")
    public void noConstituentOrdersForInstrumentAndSideAtLevel(String secId, String side, int level) {
        _server.noConstituentOrdersForInstrumentAndSideAtLevel(secId, side, level);
    }

    @Then("^the continuous orders for (.+) and side (.+) at level (\\d+) with price (.+) and leaves (.+) and shown (.+) are$")
    public void theContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(
            String secId, String side, int cukeLevel, double price, double leavesQty, double shownQty, List<CukeBookOrder> cukeOrders) {
        _server.theContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(secId, side, cukeLevel, price, leavesQty, shownQty, cukeOrders);
    }

    @Then("^all continuous orders for (.+) are$")
    public void allContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(String secId, List<CukeBookOrder> cukeOrders) {
        _server.allContinuousOrdersForAndSideAtLevelWithPriceAndLeavesAndShownAre(secId, cukeOrders);
    }

    @Then("^no execution reports are sent$")
    public void noExecutionReportsAreSent() {
        _server.noExecutionReportsAreSent();
    }

    @Then("^all execution reports sent back to clients are$")
    public void allExecutionReportsSentBackToClientsAre(List<CukeExecutionReport> expectedErs) {
        _server.allExecutionReportsSentBackToClientsAre(expectedErs);
    }

    @Then("^all rejections sent back to clients are$")
    public void allRejectionsSentBackToClientsAre(List<CukeRejection> expectedRejections) {
        _server.allRejectionsSentBackToClientsAre(expectedRejections);
    }

    @When("^the (.+) order book receives (?:an|a) (.+) timer event$")
    public void theOrderBookReceivesAnImbalanceTimerEvent(String bookType, String opType) {
        _server.theOrderBookReceivesAnImbalanceTimerEvent(bookType, opType);
    }

    @Then("^the (.+) accumulating order book for (.+) is empty$")
    public void theAuctionOrderBookForIsEmpty(String auctionType, String secId) {
        _server.theAuctionOrderBookForIsEmpty(auctionType, secId);
    }

    @Then("^the (.+) accumulating order book for (.+) contains$")
    public void theAuctionOrderBookForContains(String auctionType, String secId, List<CukeAuctionLevel> expectedLevels) {
        _server.theAuctionOrderBookForContains(auctionType, secId, expectedLevels);
    }

    @Then("^the accumulated orders for (.+) and the (.+) order book filtered by side (.+) and price (.+) are$")
    public void theAccumulatedOrdersForInstrumentAndTheOrderBookFilteredBySideAtPriceAre(String secId, String auctionType, String side, double price, List<CukeBookOrder> cukeOrders) {
        _server.theAccumulatedOrdersForInstrumentAndTheOrderBookFilteredBySideAtPriceAre(secId, auctionType, side, price, cukeOrders);
    }

    @Then("^all accumulated orders for (.+) and the (.+) order book are$")
    public void allAccumulatedOrdersForAndTheOrderBookAre(String secId, String auctionType, List<CukeBookOrder> cukeOrders) {
        _server.allAccumulatedOrdersForAndTheOrderBookAre(secId, auctionType, cukeOrders);
    }

    @Then("^the imbalance market data snapshot for (.+) is$")
    public void theImbalanceMarketDataSnapshotForIs(String secId, List<CukeImbalance> cukeImbalance) {
        _server.theImbalanceMarketDataSnapshotForIs(secId, cukeImbalance);
    }

    @When("^user (.+) logs out$")
    public void userLogsOut(String uid) {
        _server.userLogsOut(uid);
    }
}
