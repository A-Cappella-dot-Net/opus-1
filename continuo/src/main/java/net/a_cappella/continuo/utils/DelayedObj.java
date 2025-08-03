package net.a_cappella.continuo.utils;

import java.util.concurrent.Delayed;
import java.util.concurrent.TimeUnit;

public class DelayedObj implements Delayed {
    private long _expiryTime;

    public DelayedObj() {}

    public DelayedObj newInstance() { // only invoked to replenish the pool if exhausted
        return new DelayedObj();
    }

    public void setDelay(long delayInMillis) {
        _expiryTime = System.currentTimeMillis()+delayInMillis;
    }

    public void setExpiryTime(DelayedObj src) {
        _expiryTime = src._expiryTime;
    }

    public boolean isPoisonPill() {
        return _expiryTime == 0;
    }

    @Override // Delayed
    public int compareTo(Delayed o) {
        if (o instanceof DelayedObj) {
            DelayedObj d = (DelayedObj) o;
            return Long.signum(_expiryTime-d._expiryTime);
        }
        return 0;
    }
    @Override // Delayed
    public long getDelay(TimeUnit unit) {
        long delay = _expiryTime - System.currentTimeMillis();
        return unit.convert(delay, TimeUnit.MILLISECONDS);
    }
}
