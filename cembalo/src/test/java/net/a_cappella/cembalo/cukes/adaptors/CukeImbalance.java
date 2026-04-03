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
import net.a_cappella.cembalo.beans.Imbalance;

import java.util.Map;

import static net.a_cappella.cembalo.CukeUtils.parseDouble;
import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;

public class CukeImbalance {

    private final double price;
    private final double matched;
    private final double surplus;
    private final String side;

    @DataTableType
    public static CukeImbalance dttCukeImbalance(Map<String, String> entry) {
        return new CukeImbalance(
                parseDoubleNaN(entry.get("price")),
                parseDouble(entry.get("matched")),
                parseDouble(entry.get("surplus")),
                entry.get("side")
        );
    }

    public CukeImbalance(double price, double matched, double surplus, String side) {
        this.price = price;
        this.matched = matched;
        this.surplus = surplus;
        this.side = side;
    }

    @Override
    public String toString() {
        return "{"+side+" "+matched+"/"+surplus+"@"+price+"}";
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        long temp;
        temp = Double.doubleToLongBits(matched);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(price);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        result = prime * result + ((side == null) ? 0 : side.hashCode());
        temp = Double.doubleToLongBits(surplus);
        result = prime * result + (int) (temp ^ (temp >>> 32));
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
        CukeImbalance other = (CukeImbalance) obj;
        if (Double.doubleToLongBits(matched) != Double.doubleToLongBits(other.matched))
            return false;
        if (Double.doubleToLongBits(price) != Double.doubleToLongBits(other.price))
            return false;
        if (side == null) {
            if (other.side != null)
                return false;
        } else if (!side.equals(other.side))
            return false;
        if (Double.doubleToLongBits(surplus) != Double.doubleToLongBits(other.surplus))
            return false;
        return true;
    }

    public static CukeImbalance adapt(Imbalance imbalance) {
        return new CukeImbalance(imbalance.getPrice(), imbalance.getMatched(), imbalance.getSurplus(), imbalance.getSide().toString());
    }

}
