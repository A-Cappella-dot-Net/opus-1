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

import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;

public class AccumulatingLevel {
    protected double _price;
    protected SummarizedOrders _sumBids = new SummarizedOrders();
    protected SummarizedOrders _sumOffers = new SummarizedOrders();

    public AccumulatingLevel(double price) {
        _price = price;
    }

    public void add(Order ord) {
        if (ord._side == Side.Buy) {
            _sumBids.add(ord);
        } else { // ord._side == Side.Sell
            _sumOffers.add(ord);
        }
    }

    public void remove(Order ord) {
        if (ord._side == Side.Buy) {
            _sumBids.remove(ord);
        } else { // ord._side == Side.Sell
            _sumOffers.remove(ord);
        }
    }

    public void remove(SelectionKey selectionKey) {
        _sumBids.remove(selectionKey);
        _sumOffers.remove(selectionKey);
    }

    public void replaceSameLevel(Order ord, double qty) {
        double oQty = ord._size;
        double delta = qty - oQty;
        // update qty
        ord._size = qty;
        boolean moveToEndOfQueue = oQty<qty;

        if (ord._side == Side.Buy) {
            _sumBids.replaceSameLevel(ord, delta, moveToEndOfQueue);
        } else {
            _sumOffers.replaceSameLevel(ord, delta, moveToEndOfQueue);
        }
    }

    public void replaceNewLevel(Order ord, double px, double qty, OrdType ordType, AccumulatingLevel newLevel) {
        double oQty = ord._size;
        // update px and qty
        ord._price = (ordType==OrdType.Market) ? Double.NaN : px;
        ord._size = qty;
        ord._ordType = ordType;

        if (ord._side == Side.Buy) {
            // remove
            _sumBids.remove(ord, oQty);
            // add to new level
            newLevel._sumBids.add(ord, qty);
        } else {
            // remove
            _sumOffers.remove(ord, oQty);
            // add to new level
            newLevel._sumOffers.add(ord, qty);
        }
    }

    public double getPrice() {
        return _price;
    }

    public boolean hasBids() {
        return _sumBids.hasOrders();
    }

    public int bidsCount() {
        return _sumBids.count();
    }

    public Order getBid(int i) {
        return _sumBids.getOrder(i);
    }

    public double getBidLeavesQty() {
        return _sumBids.getLeavesQty();
    }

    public boolean hasOffers() {
        return _sumOffers.hasOrders();
    }

    public int offersCount() {
        return _sumOffers.count();
    }

    public Order getOffer(int i) {
        return _sumOffers.getOrder(i);
    }

    public double getOfferLeavesQty() {
        return _sumOffers.getLeavesQty();
    }

    public String toString() {
        return "{"+_price+"|("+getBidLeavesQty()+","+getOfferLeavesQty()+")"+"}";
    }

}
