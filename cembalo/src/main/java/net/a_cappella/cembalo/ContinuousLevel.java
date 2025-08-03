package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;

public class ContinuousLevel {
    private final double _price;
    private double _shownQty; // cumulated shown quantity for all component _orders; used to populate MDS
    public SummarizedOrders _sumOrders = new SummarizedOrders();

    public ContinuousLevel(double price) {
        _price = price;
    }

    public double getPrice() {
        return _price;
    }
    public double getLeavesQty() {
        return _sumOrders.getLeavesQty();
    }
    public double getShownQty() {
        return _shownQty;
    }


    public Order get(int i) {
        return _sumOrders.getOrder(i);
    }

    public void add(Order ord) {
        _sumOrders.add(ord);
        _shownQty += Math.min(ord._leavesQty, ord._shownSize);
    }

    public void remove(int i) {
        _sumOrders.remove(i);
    }

    public void remove(Order ord) {
        _sumOrders.remove(ord);
        _shownQty -= Math.min(ord._leavesQty, ord._shownSize);
    }

    public boolean remove(SelectionKey selectionKey) {
        return _sumOrders.remove(selectionKey);
    }

    public void replace(Order ord, double deltaLeaves, double oShownQty, double oLeavesQty, double nShownQty, double nLeavesQty) {
        double deltaShown = Math.min(nLeavesQty, nShownQty) - Math.min(oLeavesQty, oShownQty);
        _shownQty += deltaShown;
        _sumOrders.replaceSameLevel(ord, deltaLeaves, oShownQty<nShownQty);
    }

    public void fill(double fillQty, double deltaShown) {
        _shownQty += deltaShown;
        _sumOrders.fill(fillQty);
    }

    public int ordersCount() {
        return _sumOrders.count();
    }

    public boolean hasNoOrders() {
        return _sumOrders.hasNoOrders();
    }

    public String toString() {
        return "{"+_price+" "+_sumOrders+"}";
    }
}
