package net.a_cappella.continuo.utils;

import java.util.ArrayList;
import java.util.List;

public class DelayQueue<T extends DelayedObj> {
    private final java.util.concurrent.DelayQueue<T> _queue = new java.util.concurrent.DelayQueue<>();
    private final List<T> _objPool;
    private final T _clone;
    private final T _poisonPill;

    public DelayQueue(int size, T clone) {
        _objPool = new ArrayList<>(size);
        _clone = clone;
        _poisonPill = (T) _clone.newInstance(); // _expiryTime == 0
    }

    public T add(long delayInMillis) {
        int poolSize = _objPool.size();
        T obj;
        if (poolSize<=0) {
            obj = (T) _clone.newInstance();
        } else {
            obj = _objPool.remove(poolSize-1);
        }
        obj.setDelay(delayInMillis);
        _queue.add(obj);
        return obj;
    }

    public void addPoisonPill() {
        _queue.add(_poisonPill);
    }

    public void take(T container) throws InterruptedException {
        T obj = _queue.take();
        updateFrom(container, obj);
        _objPool.add(obj);
    }

    public void updateFrom(T dest, T src) {
        dest.setExpiryTime(src);
    }

    public void drain() {
        // retain only the records received during the previous delayInMillis
        T obj;
        do {
            obj = _queue.poll();
            if (obj!=null) {
                _objPool.add(obj);
            } else {
                break;
            }
        } while (true);
    }
    public int size() {
        return _queue.size();
    }
}
