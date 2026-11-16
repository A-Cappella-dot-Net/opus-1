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

public class Instrument {
    private static final double EPSILON = 0.00000001;

    public static final int ORDERING_PRICE = 1; // TODO enum
    public static final int ORDERING_YIELD = 2;

    private final String symbol;
    private final String secId;
    private final double minQty;
    private final double minQtyIncrement;
    private final double minPriceIncrement;
    private final int ordering;
    private final int maxLevels;

    public Instrument(String symbol, String secId, double minQty, double minQtyIncrement, double minPriceIncrement, int ordering, int maxLevels) {
        this.symbol = symbol;
        this.secId = secId;
        this.minQty = minQty;
        this.minQtyIncrement = minQtyIncrement;
        this.minPriceIncrement = minPriceIncrement;
        this.ordering = ordering;
        this.maxLevels = maxLevels;
    }

    public String getSymbol() {
        return symbol;
    }
    public String getSecId() {
        return secId;
    }
    public double getMinQty() {
        return minQty;
    }
    public double getMinQtyIncrement() {
        return minQtyIncrement;
    }
    public double getMinPriceIncrement() {
        return minPriceIncrement;
    }
    public int getOrdering() {
        return ordering;
    }
    public int getMaxLevels() {
        return maxLevels;
    }

    public String validate(double px, double qtyShown, double qty) {
        if (qtyShown == 0.0) qtyShown = qty;
        if (minQty>qtyShown) {
            return "MinQty restriction not met: "+minQty+">"+qtyShown;
        }
        double numQtyIncrements = (qty - minQty) / minQtyIncrement;
        if (Math.abs(numQtyIncrements - Math.rint(numQtyIncrements)) > EPSILON) {
            return "Qty "+qty+" does not align to minQtyIncrement of "+minQtyIncrement+" where minQty is "+minQty;
        }
        if (qtyShown!=qty) {
            numQtyIncrements = (qtyShown - minQty) / minQtyIncrement;
            if (Math.abs(numQtyIncrements - Math.rint(numQtyIncrements)) > EPSILON) {
                return "Shown Qty "+qtyShown+" does not align to minQtyIncrement of "+minQtyIncrement+" where minQty is "+minQty;
            }
        }
        double numPxIncrements = px / minPriceIncrement;
        if (Math.abs(numPxIncrements-Math.rint(numPxIncrements)) > EPSILON) {
            return "Price "+px+" does not align to minPriceIncrement of "+minPriceIncrement;
        }
        return null;
    }

    /**
     * Aligns a computed price (as opposed to one received from a client) to the price increments of
     * this instrument. A price that is already aligned is only normalized; any other price is rounded
     * up or down to the adjacent increment.
     */
    public double roundToPriceIncrement(double px, boolean up) {
        double numPxIncrements = px / minPriceIncrement;
        double rounded = Math.rint(numPxIncrements);
        if (Math.abs(numPxIncrements - rounded) > EPSILON) {
            rounded = (up) ? Math.ceil(numPxIncrements) : Math.floor(numPxIncrements);
        }
        // The order book compares prices for equality, so a computed price must be the very same double
        // a client would send for that price. Dividing by the (integral) number of increments per unit
        // is correctly rounded, just like parsing the decimal price is; multiplying by the increment is not.
        double incrementsPerUnit = Math.rint(1.0 / minPriceIncrement);
        if (incrementsPerUnit >= 1.0 && Math.abs(incrementsPerUnit * minPriceIncrement - 1.0) <= EPSILON) {
            return rounded / incrementsPerUnit;
        }
        return rounded * minPriceIncrement;
    }

    @Override
    public String toString() {
        return
                "Instrument{" +
                        symbol + " " +
                        minQty + " " + minQtyIncrement + " " + minPriceIncrement + " " +
                        ordering + " " + maxLevels + "}";
    }
}
