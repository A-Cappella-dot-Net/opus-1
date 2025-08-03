package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.List;

public class SummarizedOrders {
    private double _leavesQty;
    private final List<Order> _orders = new ArrayList<>(); // sorted by arrival time

    public void add(Order ord) {
        _leavesQty += ord._leavesQty;
        _orders.add(ord);
    }
    public void add(Order ord, double qty) {
        _leavesQty += qty;
        _orders.add(ord);
    }

    public void remove(Order ord) {
        _orders.remove(ord);
        _leavesQty -= ord._leavesQty;
    }
    public void remove(Order ord, double qty) {
        _orders.remove(ord);
        _leavesQty -= qty;
    }
    public void remove(int i) {
        Order ord = _orders.remove(i);
        _leavesQty -= ord._leavesQty;
    }
    public void fill(double fillQty) {
        _leavesQty -= fillQty;
    }

    public boolean remove(SelectionKey selectionKey) {
        boolean removed = false;
        for (int j=0; j<_orders.size(); j++) {
            Order ord = _orders.get(j);
            if (selectionKey.equals(ord._selectionKey)) {
                _orders.remove(j--);
                removed = true;
            }
        }
        return removed;
    }

    public void replaceSameLevel(Order ord, double delta, boolean moveToEndOfQueue) {
        _leavesQty += delta;
        if (moveToEndOfQueue) {
            _orders.remove(ord);
            _orders.add(ord);
        } // else in place
    }

    public int count() {
        return _orders.size();
    }

    public boolean hasOrders() {
        return !_orders.isEmpty();
    }

    public boolean hasNoOrders() {
        return _orders.isEmpty();
    }

    public Order getOrder(int i) {
        return _orders.get(i);
    }

    public double getLeavesQty() {
        return _leavesQty;
    }

    public void reset() {
        _leavesQty = 0.0;
        _orders.clear();
    }

    public String toString() {
        return "{"+_leavesQty+" "+_orders+"}";
    }
}
