package net.a_cappella.cembalo.cukes.adaptors;

import net.a_cappella.cembalo.beans.Imbalance;

public class CukeImbalance {

    private double price;
    private double matched;
    private double surplus;
    private String side;

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
