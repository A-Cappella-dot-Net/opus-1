package net.a_cappella.cembalo.cukes.adaptors;

import net.a_cappella.continuo.utils.Utils;

import java.util.Objects;

public class CukeOrder {
    private final long ordId;
    private final String clOrdId;
    private final String uid;
    private final String secId;
    private final double price;
    private double shownQty;
    private final double qty;
    private final String side;
    private final String ordType;
    private final String tif;

    public CukeOrder(
            String uid, long ordId, String clOrdId,
            String secId, String ordType, String tif,
            String side, double shownQty, double qty, double price) {

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
