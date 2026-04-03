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

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.cucumber.java.DataTableType;
import net.a_cappella.cembalo.AccumulatingLevel;
import net.a_cappella.cembalo.AccumulatingOrderBook;
import net.a_cappella.cembalo.AuctionLevel;

import static net.a_cappella.cembalo.CukeUtils.parseDouble;
import static net.a_cappella.cembalo.CukeUtils.parseDoubleNaN;

public class CukeAuctionLevel {

    private final double price;
    private final double bidSize;
    private final double offerSize;
    private final double bidPressure;
    private final double offerPressure;
    private final double matched;
    private final double surplus;
    private final String surplusSide;

    @DataTableType
    public static CukeAuctionLevel dttCukeAuctionLevel(Map<String, String> entry) {
        return new CukeAuctionLevel(
                parseDoubleNaN(entry.get("price")),
                parseDouble(entry.get("bidSize")),
                parseDouble(entry.get("offerSize")),
                parseDouble(entry.get("bidPressure")),
                parseDouble(entry.get("offerPressure")),
                parseDouble(entry.get("matched")),
                parseDouble(entry.get("surplus")),
                entry.get("surplusSide")
        );
    }

    public CukeAuctionLevel(
            double price,
            double bidSize, double offerSize,
            double bidPressure, double offerPressure,
            double matched, double surplus, String surplusSide) {
        this.price = price;
        this.bidSize = bidSize;
        this.offerSize = offerSize;
        this.bidPressure = bidPressure;
        this.offerPressure = offerPressure;
        this.matched = matched;
        this.surplus = surplus;
        this.surplusSide = surplusSide;
    }

    public double getPrice() {
        return price;
    }

    public double getBidSize() {
        return bidSize;
    }

    public double getOfferSize() {
        return offerSize;
    }

    public double getBidPressure() {
        return bidPressure;
    }

    public double getOfferPressure() {
        return offerPressure;
    }

    public double getMatched() {
        return matched;
    }

    public double getSurplus() {
        return surplus;
    }

    public String getSurplusSide() {
        return surplusSide;
    }

    private static CukeAuctionLevel adapt(AccumulatingLevel accumulatingLevel) {
        if (accumulatingLevel instanceof AuctionLevel) {
            AuctionLevel auctionLevel = (AuctionLevel) accumulatingLevel;
            return new CukeAuctionLevel(
                    auctionLevel.getPrice(),
                    auctionLevel.bidsSize(), auctionLevel.offersSize(),
                    auctionLevel.getBidPressure(), auctionLevel.getOfferPressure(),
                    auctionLevel.getMatched(), auctionLevel.getSurplus(), auctionLevel.getSurplusSide().toString());
        }
        return new CukeAuctionLevel(
                accumulatingLevel.getPrice(),
                accumulatingLevel.getBidLeavesQty(), accumulatingLevel.getOfferLeavesQty(),
                0.0, 0.0,
                0.0, 0.0, null);
    }

    public static <T extends AccumulatingLevel> List<CukeAuctionLevel> adapt(AccumulatingOrderBook<T> accumulatingOrderBook) {
        List<T> accumulatingLevels = accumulatingOrderBook.getLevels();
        List<CukeAuctionLevel> cukeAuctionLevels = new ArrayList<>();

        for (int i=0; i<accumulatingLevels.size(); i++) {
            T auctionLevel = accumulatingLevels.get(i);
            cukeAuctionLevels.add(CukeAuctionLevel.adapt(auctionLevel));
        }

        return cukeAuctionLevels;
    }

    @Override
    public String toString() {
        return "{"+price+"|("+bidSize+", "+offerSize+")("+bidPressure+", "+offerPressure+")<"+matched+", "+surplus+", "+surplusSide+">}";
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        long temp;
        temp = Double.doubleToLongBits(bidPressure);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(bidSize);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(matched);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(offerPressure);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(offerSize);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(price);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        temp = Double.doubleToLongBits(surplus);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        result = prime * result + ((surplusSide == null) ? 0 : surplusSide.hashCode());
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
        CukeAuctionLevel other = (CukeAuctionLevel) obj;
        if (Double.doubleToLongBits(bidPressure) != Double.doubleToLongBits(other.bidPressure))
            return false;
        if (Double.doubleToLongBits(bidSize) != Double.doubleToLongBits(other.bidSize))
            return false;
        if (Double.doubleToLongBits(matched) != Double.doubleToLongBits(other.matched))
            return false;
        if (Double.doubleToLongBits(offerPressure) != Double.doubleToLongBits(other.offerPressure))
            return false;
        if (Double.doubleToLongBits(offerSize) != Double.doubleToLongBits(other.offerSize))
            return false;
        if (Double.doubleToLongBits(price) != Double.doubleToLongBits(other.price))
            return false;
        if (Double.doubleToLongBits(surplus) != Double.doubleToLongBits(other.surplus))
            return false;
        if (surplusSide == null) {
            if (other.surplusSide != null)
                return false;
        } else if (!surplusSide.equals(other.surplusSide))
            return false;
        return true;
    }
}
