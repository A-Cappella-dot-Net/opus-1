package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import gnu.trove.map.TLongObjectMap;
import gnu.trove.map.hash.TLongObjectHashMap;

public class ActiveOrders {
    private final Map<SelectionKey, List<Order>> _bySelectionKey = new HashMap<>();
    private final TLongObjectMap<Order> _byOrderId = new TLongObjectHashMap<>();

    public void add(Order ord) {
        SelectionKey key = ord._selectionKey;
        _bySelectionKey.computeIfAbsent(key, k -> new ArrayList<>()).add(ord);
        _byOrderId.put(ord._orderID, ord);
    }
    public void remove(Order ord) {
        List<Order> list = _bySelectionKey.get(ord._selectionKey);
        if (list!=null) list.remove(ord);
        _byOrderId.remove(ord._orderID);
    }
    public Order get(long orderID) {
        return _byOrderId.get(orderID);
    }

    public List<Order> get(SelectionKey key) {
        return _bySelectionKey.get(key);
    }
    public List<Order> remove(SelectionKey key) {
        List<Order> list = _bySelectionKey.remove(key);
        if (list!=null) for (int i=0; i<list.size(); i++) {
            Order ord = list.get(i);
            _byOrderId.remove(ord._orderID);
        }
        return list;
    }

    public void handleClientDisconnect(SelectionKey key, final Consumer<Order> consumer) {
        List<Order> orderList = remove(key);
        if (orderList!=null) for (int i=0; i<orderList.size(); i++) {
            Order order = orderList.get(i);
            consumer.accept(order);
        }
    }

    public void handleUserLogoff(final SelectionKey key, final String uid, final Consumer<Order> consumer) {
        List<Order> orderList = get(key);
        if (orderList!=null) for (int i=0; i<orderList.size(); i++) {
            Order order = orderList.get(i);
            if (order._user.equals(uid)) {
                consumer.accept(order);
                i--;
                remove(order);
            }
        }
    }

    public void reset() {
        _bySelectionKey.clear();
        _byOrderId.clear();
    }
}
