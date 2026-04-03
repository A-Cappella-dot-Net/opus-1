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
