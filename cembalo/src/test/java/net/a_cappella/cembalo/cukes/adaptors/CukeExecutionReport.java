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
import net.a_cappella.continuo.utils.Utils;

import java.util.Map;
import java.util.Objects;

import static com.google.common.base.Strings.nullToEmpty;
import static net.a_cappella.cembalo.CukeUtils.parseDouble;
import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;


public class CukeExecutionReport {

    private final long ordId;
    private final String clOrdId;
    private final String uid;
    private final String secId;
    private final double price;
    private final double shownQty;
    private final double qty;
    private final String side;
    private final String ordType;
    private final String tif;

    private final double lastQty;
    private final double lastPx;
    private final double cumQty;
    private final double leavesQty;
    private final double avgPx;

    private final String execType;
    private final String ordStatus;
    private final String text;

    @DataTableType
    public static CukeExecutionReport dttCukeExecutionReport(Map<String, String> entry) {
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

    public CukeExecutionReport(
            String uid, long ordId, String clOrdId,
            String secId, String ordType, String tif,
            String side, double shownQty, double qty, double price,
            String execType, String ordStatus,
            double lastQty, double lastPx, double cumQty, double leavesQty, double avgPx,
            String text) {

        this.uid = uid;
        this.ordId = ordId;
        this.clOrdId = clOrdId;

        this.secId = secId;
        this.ordType = ordType;
        this.tif = tif;
        this.side = side;
        this.shownQty = shownQty;
        this.qty = qty;
        this.price = price;

        this.execType = execType;
        this.ordStatus = ordStatus;

        this.lastQty = lastQty;
        this.lastPx = lastPx;
        this.cumQty = cumQty;
        this.leavesQty = leavesQty;
        this.avgPx = avgPx;

        this.text = nullToEmpty(text);
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

        temp = Double.doubleToLongBits(lastQty);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(lastPx);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(leavesQty);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(cumQty);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(avgPx);
        result = prime * result + (int) (temp ^ (temp >>> 32));

        result = prime * result + ((uid == null) ? 0 : uid.hashCode());
        result = prime * result + ((clOrdId == null) ? 0 : clOrdId.hashCode());
        result = prime * result + ((secId == null) ? 0 : secId.hashCode());
        result = prime * result + ((ordType == null) ? 0 : ordType.hashCode());
        result = prime * result + ((tif == null) ? 0 : tif.hashCode());
        result = prime * result + ((side == null) ? 0 : side.hashCode());
        result = prime * result + ((execType == null) ? 0 : execType.hashCode());
        result = prime * result + ((ordStatus == null) ? 0 : ordStatus.hashCode());
        result = prime * result + ((text == null) ? 0 : text.hashCode());
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
        CukeExecutionReport other = (CukeExecutionReport) obj;

        if (!Objects.equals(uid, other.uid)) return false;
        if (!Objects.equals(clOrdId, other.clOrdId)) return false;
        if (!Objects.equals(ordId, other.ordId)) return false;
        if (!Objects.equals(ordType, other.ordType)) return false;
        if (!Objects.equals(tif, other.tif)) return false;
        if (!Objects.equals(secId, other.secId)) return false;
        if (!Objects.equals(side, other.side)) return false;
        if (!Utils.doubleEquals(qty, other.qty)) return false;
        if (!Utils.doubleEquals(shownQty, other.shownQty)) return false;
        if (!Utils.doubleEquals(price, other.price)) return false;

        if (!Objects.equals(execType, other.execType)) return false;
        if (!Objects.equals(ordStatus, other.ordStatus)) return false;

        if (!Utils.doubleEquals(lastQty, other.lastQty)) return false;
        if (!Utils.doubleEquals(lastPx, other.lastPx)) return false;
        if (!Utils.doubleEquals(leavesQty, other.leavesQty)) return false;
        if (!Utils.doubleEquals(cumQty, other.cumQty)) return false;
        if (!Utils.doubleEquals(avgPx, other.avgPx)) return false;

        if (!Objects.equals(text, other.text)) return false;

        return true;
    }

    @Override
    public String toString() {
        return "{RESPONSE "+
                uid+" "+clOrdId+" "+ordId+" "+
                ordType+" "+tif+" "+secId+" "+side+" "+
                shownQty+"/"+qty+"@"+price+" "+
                execType+" "+ordStatus+" "+
                lastQty+"@"+lastPx+"/"+leavesQty+"/"+cumQty+"@"+avgPx+" "+text+"}";
    }
}
