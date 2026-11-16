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

/** Handles the order requests of the clients once they are decoded from the FIX messages they arrive in. */
public interface IOrderRequestHandler {
    /**
     * @param px for a pegged order the price is optional (NaN if not specified) and acts as a cap on the pegged price
     * @param peg the peg instructions of a pegged order, null for any other order
     */
    void handleNewOrderSingle(
            final SelectionKey key, String uid, String clOrdID, String securityID,
            char ordType, char tif, char side, double px, double qtyShown, double qty, PegInstruction peg);

    void handleOrderCancelRequest(
            final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID,
            char side, double qty);

    void handleOrderCancelReplaceRequest(
            final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID,
            double px, double qtyShown, double qty, char ordType, char side, char tif);
}
