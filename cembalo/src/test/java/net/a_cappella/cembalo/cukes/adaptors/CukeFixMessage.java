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

package net.a_cappella.cembalo.cukes.adaptors;

import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;
import static net.a_cappella.cembalo.generated.FixConstants.*;

import java.nio.ByteBuffer;
import java.util.Map;

import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;

/**
 * Builds the FIX messages of the scenarios that exercise the FIX layer. A message is given as a table
 * row whose columns are named after the FIX fields and whose cells hold the raw FIX values; a field
 * with an empty cell is not part of the message.
 */
public class CukeFixMessage {

    public static FixMessage build(String fixMsgType, Map<String, String> entry) {
        FixMessage fixMessage = new FixMessage(new FixFields());
        fixMessage.setFixMsgType(fixMsgType);
        FixFields fields = fixMessage.getFields();
        for (Map.Entry<String, String> field : entry.entrySet()) {
            String value = field.getValue();
            if (value == null || value.trim().isEmpty()) continue;
            put(fields, field.getKey(), value.trim());
        }
        return fixMessage;
    }

    private static void put(FixFields fields, String name, String value) {
        switch (name) {
            case "Username": fields.putString(Tag_Username, value); break;
            case "ClOrdID": fields.putString(Tag_ClOrdID, value); break;
            case "OrigClOrdID": fields.putString(Tag_OrigClOrdID, value); break;
            case "Symbol": fields.putString(Tag_Symbol, value); break;
            case "OrderID": fields.putInt(Tag_OrderID, Long.parseLong(value)); break;
            case "OrdType": fields.putChar(Tag_OrdType, value.charAt(0)); break;
            case "TimeInForce": fields.putChar(Tag_TimeInForce, value.charAt(0)); break;
            case "Side": fields.putChar(Tag_Side, value.charAt(0)); break;
            case "Price": fields.putFloat(Tag_Price, parseDoubleNaN(value)); break;
            case "OrderQty": fields.putFloat(Tag_OrderQty, parseDoubleNaN(value)); break;
            case "MaxShow": fields.putFloat(Tag_MaxShow, parseDoubleNaN(value)); break;
            case "PegPriceType": fields.putInt(Tag_PegPriceType, Long.parseLong(value)); break;
            case "PegRoundDirection": fields.putInt(Tag_PegRoundDirection, Long.parseLong(value)); break;
            case "PegOffsetValue": fields.putFloat(Tag_PegOffsetValue, parseDoubleNaN(value)); break;
            case "PegOffsetType": fields.putInt(Tag_PegOffsetType, Long.parseLong(value)); break;
            case "PegScope": fields.putInt(Tag_PegScope, Long.parseLong(value)); break;
            default: throw new IllegalArgumentException("FIX field '"+name+"' is not known to the test harness");
        }
    }

    /** The message as the exchange gets it: encoded by the sender, sent over the wire and decoded by the receiver. */
    public static FixMessage overTheWire(FixMessage sent) {
        ByteBuffer buffer = ByteBuffer.allocate(4096);
        sent.encode(buffer);
        buffer.flip();
        FixMessage received = new FixMessage(new FixFields());
        received.decode(buffer, buffer.limit());
        return received;
    }
}
