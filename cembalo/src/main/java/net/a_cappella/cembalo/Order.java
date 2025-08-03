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

    public double _price;
    public double _shownSize;
    public double _size;

    public double _lastQty;
    public double _lastPx;
    public double _leavesQty;
    public double _cumQty;
    public double _avgPx;

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
        return "{"+_orderID+" "+_shownSize+"/"+_size+"@"+_price+" "+_cumQty+":"+_leavesQty+"}";
    }
}
