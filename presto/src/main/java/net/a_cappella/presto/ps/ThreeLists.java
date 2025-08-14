package net.a_cappella.presto.ps;

import java.util.ArrayList;
import java.util.List;

public class ThreeLists<V> {
    private final List<V> _list = new ArrayList<>();
    private final List<V> _listTBA = new ArrayList<>();
    private final List<V> _listTBR = new ArrayList<>();

    public List<V> get() {
        commit();
        return _list;
    }

    public void add(V value) {
        synchronized (this) {
            _listTBA.add(value);
        }
    }
    public void addAll(List<V> values) {
        synchronized (this) {
            _listTBA.addAll(values);
        }
    }
    public void remove(V value) {
        synchronized (this) {
            _listTBR.add(value);
        }
    }
    public void removeAll(List<V> values) {
        synchronized (this) {
            _listTBR.addAll(values);
        }
    }
    public void commit() {
        synchronized (this) {
            if (!_listTBA.isEmpty()) {
                _list.addAll(_listTBA);
                _listTBA.clear();
            }
            if (!_listTBR.isEmpty()) {
                _list.removeAll(_listTBR);
                _listTBR.clear();
            }
        }
    }
    public boolean isEmpty() {
        commit();
        return _list.isEmpty();
    }
}
