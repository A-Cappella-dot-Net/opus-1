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

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;

public class Order {
    public SelectionKey _selectionKey;
    public String _user;

    public long _orderID;
    public String _clOrdID;
    public String _origClOrdID;

    public String _securityID;
    public OrdType _ordType;
    public TimeInForce _tif;
    public Side _side;

    public double _price; // for pegged orders: the current pegged price (NaN while parked)
    public double _shownSize;
    public double _size;

    public double _lastQty;
    public double _lastPx;
    public double _leavesQty;
    public double _cumQty;
    public double _avgPx;

    public PegInstruction _peg; // null unless this is a pegged order
    public double _pegCap = Double.NaN; // the optional Price (tag 44) of a pegged order; NaN = no cap
    public boolean _pegAtLimit; // the price to peg at is beyond the cap: the order is held at its cap until the price is back within it

    public Order(SelectionKey key, String uid, long orderID, String clOrdID, String securityID, char ordType, char tif, char side, double qtyShown, double qty, double px) {
        _selectionKey = key;
        _user = uid;
        _orderID = orderID;
        _clOrdID = clOrdID;
        _ordType = OrdType.fromFix(ordType);
        _tif = TimeInForce.fromFix(tif);
        _securityID = securityID;
        _side = Side.fromFix(side);
        _shownSize = qtyShown;
        _size = qty;
        _price = px;
        _lastQty = 0.0;
        _lastPx = Double.NaN;
        _leavesQty = qty;
        _cumQty = 0.0;
        _avgPx = Double.NaN;
    }

    /**
     * Turns this order into a pegged order. The price the order was created with becomes the cap,
     * i.e., the absolute limit the pegged price never goes beyond, and the order remains parked
     * (no price, not in the order book) until the order book assigns it a pegged price.
     */
    public void peg(PegInstruction peg) {
        _peg = peg;
        _pegCap = _price;
        _price = Double.NaN;
    }

    public boolean isPegged() {
        return _peg != null;
    }

    /** A parked order is a pegged order with no reference price to peg to: it is active, but it is not in the order book. */
    public boolean isParked() {
        return _peg != null && Double.isNaN(_price);
    }

    /** Hidden orders are matched like any other order, but they are not shown in the Market Data. */
    public boolean isHidden() {
        return _peg != null && _peg.isHidden();
    }

    /** The Price (tag 44) as the client knows it: the limit price or, for pegged orders, the optional cap. */
    public double clientPrice() {
        return (_peg == null) ? _price : _pegCap;
    }

    /** The PeggedPrice (tag 839): the price a pegged order is currently pegged at; NaN if it is parked or not a pegged order. */
    public double peggedPrice() {
        return (_peg == null) ? Double.NaN : _price;
    }

    /** The quantity this order contributes to the Market Data. */
    public double displayQty() {
        return isHidden() ? 0.0 : Math.min(_leavesQty, _shownSize);
    }

    /** The quantity that can be matched in one round at the order's price level. */
    public double matchableQty() {
        return isHidden() ? _leavesQty : Math.min(_leavesQty, _shownSize);
    }

    public String validate(String securityID, char sideChar) {
        if (securityID != _securityID) {
            return "Inconsistent securityID: expected "+_securityID+" but received "+securityID;
        }
        Side side = Side.fromFix(sideChar);
        if (side != _side) {
            return "Inconsistent side: expected "+_side+" but received "+side;
        }
        return null;
    }

    public Book forOrderBook() {
        return forOrderBook(_tif);
    }

    public static Book forOrderBook(TimeInForce tif) {
        switch (tif) {
            case AtClose:
                return Book.CLOSE_BK;
            case AtOpen:
                return Book.OPEN_BK;
            case DAY:
            case FOK:
            case IOC:
            case STO:
            default:
                return Book.CONTINUOUS_BK;
        }
    }

    public void fill(double fillQty, double fillPx, boolean cumulateOverMultipleLevels) {
        _lastQty += fillQty;
        _avgPx = (Double.isNaN(_avgPx)) ? fillPx : ((fillQty*fillPx + _cumQty*_avgPx)/(fillQty + _cumQty));
        _lastPx = (cumulateOverMultipleLevels) ? _avgPx : fillPx;
        _cumQty += fillQty;
        _leavesQty -= fillQty;
    }

    public String toString() {
        return "{"+_orderID+" "+_shownSize+"/"+_size+"@"+_price+" "+_cumQty+":"+_leavesQty+((_peg == null) ? "" : " "+_peg+" cap "+_pegCap)+"}";
    }
}
