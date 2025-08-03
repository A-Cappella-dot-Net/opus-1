package net.a_cappella.cembalo.cukes.adaptors;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import net.a_cappella.cembalo.AccumulatingLevel;
import net.a_cappella.cembalo.AccumulatingOrderBook;
import net.a_cappella.cembalo.ContinuousLevel;
import net.a_cappella.cembalo.Order;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.continuo.utils.Utils;

public class CukeBookOrder {

    private final long ordId;
    private final String clOrdId;
    private final String uid;
    private final String secId;
    private double price;
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

    public CukeBookOrder(
            String uid, long ordId, String clOrdId,
            String secId, String ordType, String tif,
            String side, double shownQty, double qty, double price,
            double lastQty, double lastPx, double cumQty, double leavesQty, double avgPx) {

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

        this.lastQty = lastQty;
        this.lastPx = lastPx;
        this.cumQty = cumQty;
        this.leavesQty = leavesQty;
        this.avgPx = avgPx;
    }

    public void setPrice(double price) {
        this.price = price;
    }


    private static CukeBookOrder book(Order order) {
        CukeBookOrder bookOrder = new CukeBookOrder(
                order._user, order._orderID, order._clOrdID,
                order._securityID, OrdType.toString(order._ordType), TimeInForce.toString(order._tif),
                Side.toString(order._side), order._shownSize, order._size, order._price,
                order._lastQty, order._lastPx, order._cumQty, order._leavesQty, order._avgPx
        );
        return bookOrder;
    }
    public static List<CukeBookOrder> book(ContinuousLevel continuousLevel) {
        List<CukeBookOrder> cukeOrders = new ArrayList<>();
        for (int i=0; i<continuousLevel.ordersCount(); i++) {
            cukeOrders.add(book(continuousLevel.get(i)));
        }
        return cukeOrders;
    }
    public static List<CukeBookOrder> book(List<ContinuousLevel> continuousLevels) {
        List<CukeBookOrder> cukeOrders = new ArrayList<>();
        for (int i=0; i<continuousLevels.size(); i++) {
            ContinuousLevel continuousLevel = continuousLevels.get(i);
            for (int j=0; j<continuousLevel.ordersCount(); j++) {
                cukeOrders.add(book(continuousLevel.get(j)));
            }
        }
        return cukeOrders;
    }
    public static List<CukeBookOrder> book(AccumulatingLevel accumulatingLevel, String side) {
        List<CukeBookOrder> cukeOrders = new ArrayList<>();
        if ("Buy".equals(side)) {
            for (int i=0; i<accumulatingLevel.bidsCount(); i++) {
                cukeOrders.add(book(accumulatingLevel.getBid(i)));
            }
        } else {
            for (int i=0; i<accumulatingLevel.offersCount(); i++) {
                cukeOrders.add(book(accumulatingLevel.getOffer(i)));
            }
        }
        return cukeOrders;
    }

    public static <T extends AccumulatingLevel> List<CukeBookOrder> book(AccumulatingOrderBook<T> accumulatingOrderBook) {
        List<CukeBookOrder> cukeOrders = new ArrayList<>();
        for (int j=0; j<accumulatingOrderBook._levels.size(); j++) {
            AccumulatingLevel accumulatingLevel = accumulatingOrderBook._levels.get(j);
            for (int i=0; i<accumulatingLevel.offersCount(); i++) {
                cukeOrders.add(book(accumulatingLevel.getOffer(i)));
            }
            for (int i=0; i<accumulatingLevel.bidsCount(); i++) {
                cukeOrders.add(book(accumulatingLevel.getBid(i)));
            }
        }
        return cukeOrders;
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
        CukeBookOrder other = (CukeBookOrder) obj;

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

        if (!Utils.doubleEquals(lastQty, other.lastQty)) return false;
        if (!Utils.doubleEquals(lastPx, other.lastPx)) return false;
        if (!Utils.doubleEquals(leavesQty, other.leavesQty)) return false;
        if (!Utils.doubleEquals(cumQty, other.cumQty)) return false;
        if (!Utils.doubleEquals(avgPx, other.avgPx)) return false;

        return true;
    }

    @Override
    public String toString() {
        return "{BOOK "+
                uid+" "+clOrdId+" "+ordId+" "+
                ordType+" "+tif+" "+secId+" "+side+" "+
                shownQty+"/"+qty+"@"+price+" "+
                lastQty+"@"+lastPx+"/"+leavesQty+"/"+cumQty+"@"+avgPx+"}";
    }
}
