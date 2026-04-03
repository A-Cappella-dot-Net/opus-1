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
import net.a_cappella.cembalo.constants.MktStatus;
import net.a_cappella.cembalo.constants.UserStatus;

public interface IExchangeClientListener {
    void marketStatus(MktStatus marketStatus);

    void onMarketDataRequestReject(String marketDataRequestRejectReason);
    void onInstrument(String securityID, String symbol, int maturityDate, double couponRate, double contractMultiplier, double minPriceIncrement, double minQty, double minQtyIncrement);
    void onMarketDataSnapshot(String securityID, MarketDataSnapshot mds);
    void onInstrumentStatus(String securityID, InstrumentStatus is);
    void onImbalance(String securityID, Imbalance imb);

    void onUserResponse(String ecnUid, UserStatus status, String text);

    void onExecutionReport(String execId, String ecnOrdId, String clOrdId, String origClOrdId,
                           char execType, char ordStatus, int ordRejReason,
                           String symbol, char side, double price, char ordType, char timeInForce,
                           double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text,
                           long transactTime);
    void onOrderCancelReject(
            String execId, String ecnOrdId, String clOrdId, String origClOrdId,
            char ordStatus, char cxlRejResponseTo, int cxlRejReason, String text,
            long transactTime);
}
