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

import io.cucumber.java.DataTableType;
import net.a_cappella.cembalo.PegInstruction;
import net.a_cappella.continuo.utils.Utils;

import java.util.Map;
import java.util.Objects;

import static net.a_cappella.cembalo.CukeUtils.parseDouble;
import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;
import static net.a_cappella.cembalo.generated.FixConstants.*;

public class CukeOrder {
    private long ordId;
    private String clOrdId;
    private String uid;
    private String secId;
    private double price;
    private double shownQty;
    private double qty;
    private String side;
    private String ordType;
    private String tif;

    private String pegPriceType;
    private String pegRoundDirection;
    private String pegOffsetValue;
    private String pegOffsetType;
    private String pegScope;

    @DataTableType
    public static CukeOrder dttCukeOrder(Map<String, String> entry) {
        CukeOrder co = new CukeOrder();
        co.uid = entry.get("uid");
        co.ordId = Long.parseLong(entry.get("ordId"));
        co.clOrdId = entry.get("clOrdId");

        co.secId = entry.get("secId");
        co.ordType = entry.get("ordType");
        co.tif = entry.get("tif");
        co.side = entry.get("side");
        co.shownQty = parseDouble(entry.get("shownQty"));
        co.qty = parseDouble(entry.get("qty"));
        co.price = parseDoubleNaN(entry.get("price"));

        // optional peg instructions; a missing or empty one takes its default value, as it does when missing in the FIX message
        co.pegPriceType = entry.get("pegPriceType");
        co.pegRoundDirection = entry.get("pegRoundDirection");
        co.pegOffsetValue = entry.get("pegOffsetValue");
        co.pegOffsetType = entry.get("pegOffsetType");
        co.pegScope = entry.get("pegScope");
        return co;
    }

    /** @return the peg instructions if this is a pegged order, null otherwise */
    public PegInstruction getPeg() {
        if (!"Pegged".equals(ordType)) return null;
        return new PegInstruction(
                pegValue(pegPriceType, PegInstruction.DEFAULT_PRICE_TYPE, "MidPrice", Val_PegPriceType_MidPrice, "Market", Val_PegPriceType_Market, "Primary", Val_PegPriceType_Primary),
                pegValue(pegRoundDirection, PegInstruction.DEFAULT_ROUND_DIRECTION, "MoreAggressive", Val_PegRoundDirection_MoreAggressive, "MorePassive", Val_PegRoundDirection_MorePassive),
                isEmpty(pegOffsetValue) ? PegInstruction.DEFAULT_OFFSET_VALUE : parseDoubleNaN(pegOffsetValue),
                pegValue(pegOffsetType, PegInstruction.DEFAULT_OFFSET_TYPE, "Price", Val_PegOffsetType_Price, "BasisPoints", Val_PegOffsetType_BasisPoints, "Ticks", Val_PegOffsetType_Ticks, "PriceTier", Val_PegOffsetType_PriceTier),
                pegValue(pegScope, PegInstruction.DEFAULT_SCOPE, "Local", Val_PegScope_Local)
        );
    }

    private static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }

    // namesAndValues: name1, fixValue1, name2, fixValue2... Anything else is taken as the raw FIX value.
    private static int pegValue(String str, int defaultValue, Object... namesAndValues) {
        if (isEmpty(str)) return defaultValue;
        for (int i = 0; i < namesAndValues.length; i += 2) {
            if (namesAndValues[i].equals(str.trim())) return (Integer) namesAndValues[i+1];
        }
        return Integer.parseInt(str.trim());
    }

    public String getUid() {
        return uid;
    }
    public long getOrdId() {
        return ordId;
    }
    public String getClOrdId() {
        return clOrdId;
    }
    public String getSecId() {
        return secId;
    }
    public String getOrdType() {
        return ordType;
    }
    public String getTif() {
        return tif;
    }
    public String getSide() {
        return side;
    }
    public double getShownQty() {
        return shownQty;
    }
    public double getQty() {
        return qty;
    }
    public double getPrice() {
        return price;
    }

    public void adjustShownQty() {
        if ("DAY".equals(tif) && shownQty == 0.0) shownQty = qty;
    }


    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        long temp;
        temp = Double.doubleToLongBits(shownQty);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(qty);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(price);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = ordId;
        result = prime * result + (int) (temp ^ (temp >>> 32));

        result = prime * result + ((uid == null) ? 0 : uid.hashCode());
        result = prime * result + ((clOrdId == null) ? 0 : clOrdId.hashCode());
        result = prime * result + ((secId == null) ? 0 : secId.hashCode());
        result = prime * result + ((ordType == null) ? 0 : ordType.hashCode());
        result = prime * result + ((tif == null) ? 0 : tif.hashCode());
        result = prime * result + ((side == null) ? 0 : side.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        CukeOrder other = (CukeOrder) obj;

        if (!Objects.equals(uid, other.uid)) return false;
        if (!Objects.equals(clOrdId, other.clOrdId)) return false;
        if (!Objects.equals(ordId, other.ordId)) return false;
        if (!Objects.equals(ordType, other.ordType)) return false;
        if (!Objects.equals(tif, other.tif)) return false;
        if (!Objects.equals(secId, other.secId)) return false;
        if (!Objects.equals(side, other.side)) return false;
        if (!Utils.doubleEquals(qty, other.qty)) return false;
        // shownQty is only relevant for DAY orders
        if ("DAY".equals(tif)) if (!Utils.doubleEquals(shownQty, other.shownQty)) return false;
        if (!Utils.doubleEquals(price, other.price)) return false;

        return true;
    }

    @Override
    public String toString() {
        return "{REQUEST "+
                uid+" "+
                clOrdId+" "+ordId+" "+
                ordType+" "+tif+" "+secId+" "+side+" "+
                shownQty+"/"+qty+"@"+price+"}";
    }
}
