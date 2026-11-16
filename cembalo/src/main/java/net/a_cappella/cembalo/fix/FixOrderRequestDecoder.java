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

package net.a_cappella.cembalo.fix;

import static net.a_cappella.cembalo.generated.FixConstants.Tag_ClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MaxShow;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrigClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_PegOffsetType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_PegOffsetValue;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_PegPriceType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_PegRoundDirection;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_PegScope;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Price;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Side;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Symbol;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TimeInForce;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Username;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdType_Pegged;

import java.nio.channels.SelectionKey;

import net.a_cappella.cembalo.IOrderRequestHandler;
import net.a_cappella.cembalo.PegInstruction;

/** Decodes the order requests (NewOrderSingle, OrderCancelRequest, OrderCancelReplaceRequest) and passes them on to their handler. */
public final class FixOrderRequestDecoder {
    private FixOrderRequestDecoder() {}

    public static void newOrderSingle(final SelectionKey key, final FixMessage nos, IOrderRequestHandler handler) {
        FixFields nosFields = nos.getFields();
        String uid = nosFields.getString(Tag_Username);
        String clOrdID = nosFields.getString(Tag_ClOrdID);
        String symbol = nosFields.getString(Tag_Symbol);
        char ordType = nosFields.getChar(Tag_OrdType);
        char tif = nosFields.getChar(Tag_TimeInForce);
        char side = nosFields.getChar(Tag_Side);
        double px = price(nosFields, ordType);
        double qtyShown = nosFields.getFloat(Tag_MaxShow);
        double qty = nosFields.getFloat(Tag_OrderQty);
        PegInstruction peg = null;
        if (ordType == Val_OrdType_Pegged) {
            // a peg instruction that is not specified takes its default value
            peg = new PegInstruction(
                    (int) nosFields.getInt(Tag_PegPriceType, PegInstruction.DEFAULT_PRICE_TYPE),
                    (int) nosFields.getInt(Tag_PegRoundDirection, PegInstruction.DEFAULT_ROUND_DIRECTION),
                    nosFields.getFloat(Tag_PegOffsetValue, PegInstruction.DEFAULT_OFFSET_VALUE),
                    (int) nosFields.getInt(Tag_PegOffsetType, PegInstruction.DEFAULT_OFFSET_TYPE),
                    (int) nosFields.getInt(Tag_PegScope, PegInstruction.DEFAULT_SCOPE));
        }
        handler.handleNewOrderSingle(key, uid, clOrdID, symbol, ordType, tif, side, px, qtyShown, qty, peg);
    }

    public static void orderCancelRequest(final SelectionKey key, final FixMessage ocr, IOrderRequestHandler handler) {
        FixFields ocrFields = ocr.getFields();
        String uid = ocrFields.getString(Tag_Username);
        String origClOrdID = ocrFields.getString(Tag_OrigClOrdID);
        long orderID = ocrFields.getInt(Tag_OrderID);
        String clOrdID = ocrFields.getString(Tag_ClOrdID);
        String symbol = ocrFields.getString(Tag_Symbol);
        char side = ocrFields.getChar(Tag_Side);
        double qty = ocrFields.getFloat(Tag_OrderQty);
        handler.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, symbol, side, qty);
    }

    public static void orderCancelReplaceRequest(final SelectionKey key, final FixMessage ocrr, IOrderRequestHandler handler) {
        FixFields ocrrFields = ocrr.getFields();
        String uid = ocrrFields.getString(Tag_Username);
        String origClOrdID = ocrrFields.getString(Tag_OrigClOrdID);
        long orderID = ocrrFields.getInt(Tag_OrderID);
        String clOrdID = ocrrFields.getString(Tag_ClOrdID);
        String symbol = ocrrFields.getString(Tag_Symbol);
        char ordType = ocrrFields.getChar(Tag_OrdType);
        char side = ocrrFields.getChar(Tag_Side);
        char tif = ocrrFields.getChar(Tag_TimeInForce);
        double px = price(ocrrFields, ordType);
        double qtyShown = ocrrFields.getFloat(Tag_MaxShow);
        double qty = ocrrFields.getFloat(Tag_OrderQty);
        handler.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, symbol, px, qtyShown, qty, ordType, side, tif);
    }

    // the Price of a pegged order is optional: when present it caps the pegged price, when missing there is no cap (NaN)
    private static double price(FixFields fields, char ordType) {
        return (ordType == Val_OrdType_Pegged) ? fields.getFloat(Tag_Price, Double.NaN) : fields.getFloat(Tag_Price);
    }
}
