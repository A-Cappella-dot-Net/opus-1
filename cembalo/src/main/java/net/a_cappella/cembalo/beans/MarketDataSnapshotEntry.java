package net.a_cappella.cembalo.beans;

import java.util.Objects;

public class MarketDataSnapshotEntry {
    private final static double EPSILON = 0.000000000001;
    private final static double MINUS_EPSILON = - EPSILON;

    public double _size;
    public double _price;

    public MarketDataSnapshotEntry(double size, double price) {
        _size = size;
        _price = price;
    }

    public void reset() {
        _size = 0;
        _price = Double.NaN;
    }

    public boolean equals(Object other) {
        if (other==null) {
            return false;
        }
        if (!(other instanceof MarketDataSnapshotEntry)) {
            return false;
        }
        MarketDataSnapshotEntry mds = (MarketDataSnapshotEntry) other;
        double diff = _size - mds._size;
        if (MINUS_EPSILON < diff && diff < EPSILON) {
            diff = _price - mds._price;
            return MINUS_EPSILON < diff && diff < EPSILON;
        }
        return false;
    }
    public int hashCode() {
        return Objects.hash(_size, _price);
    }

    public String toString() {
        return _size+"@"+_price;
    }
}
