/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
