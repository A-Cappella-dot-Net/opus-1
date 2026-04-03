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

package net.a_cappella.presto.utils.conflator;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.presto.ft.collective.IFtMsgListenerNotifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.*;

public abstract class BaseConflator<K, V> {
    private static final Logger log = LoggerFactory.getLogger(BaseConflator.class);

    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
            .setNameFormat(BaseConflator.class.getSimpleName() + "-%d").setDaemon(true).build();

    private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);

    private final ConcurrentMap<K, V> _previousValues = new ConcurrentHashMap<>();
    private final ConcurrentMap<K, Object> _locksByKey = new ConcurrentHashMap<>();
    private final ConcurrentMap<K, ValueAndFuture> _valueAndFutureByKey = new ConcurrentHashMap<>();

    protected long _conflationInterval;
    protected IFtMsgListenerNotifier _notifier;

    public abstract void notifyFtMsgListeners(K key, V value);

    public BaseConflator(long conflationInterval, IFtMsgListenerNotifier notifier) {
        _scheduler.setRemoveOnCancelPolicy(true);
        _conflationInterval = conflationInterval;
        _notifier = notifier;
    }

    public void stop() {
        _scheduler.shutdown();
        log.info("Thread pool "+_scheduler+" shut down...");
    }


    public void conflate(K key, V value, boolean force) {
        if (force) {
            V previousValue = _previousValues.put(key, value);
            if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"forced("+key+"->["+previousValue+"=>"+value+"])");
            notifyFtMsgListeners(key, value);
            Object lock = _locksByKey.computeIfAbsent(key, l -> new Object());
            synchronized (lock) {
                ValueAndFuture eventAndFuture = _valueAndFutureByKey.remove(key);
                if (eventAndFuture!=null) {
                    if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"dropped "+key+"->"+eventAndFuture._value);
                    eventAndFuture._future.cancel(true); // mayInterruptIfRunning
                }
            }
            return;
        }

        if (_conflationInterval<=0) {
            V previousValue = _previousValues.put(key, value);
            if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"immediate("+key+"->["+previousValue+"=>"+value+"])");
            if (!value.equals(previousValue)) notifyFtMsgListeners(key, value);
            return;
        }

        if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"adding "+key+"->"+value);
        ScheduledFuture<?> replacementFuture =
                _scheduler.schedule(
                        () -> {
                            Object lock = _locksByKey.get(key);
                            synchronized (lock) {
                                ValueAndFuture valueAndFuture = _valueAndFutureByKey.remove(key);
                                V latestValue = valueAndFuture._value;
                                V previousValue = _previousValues.put(key, latestValue);
                                if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"onTimer("+key+"->["+previousValue+"=>"+latestValue+"])");
                                if (!latestValue.equals(previousValue)) notifyFtMsgListeners(key, latestValue);
                            }
                        },
                        _conflationInterval, TimeUnit.MILLISECONDS);
        Object lock = _locksByKey.computeIfAbsent(key, l -> new Object());
        synchronized (lock) {
            ValueAndFuture eventAndFuture = _valueAndFutureByKey.put(key, new ValueAndFuture(value, replacementFuture));
            if (eventAndFuture!=null) {
                if (log.isDebugEnabled()) log.info(_notifier.getNotifierId()+"dropped "+key+"->"+eventAndFuture._value);
                eventAndFuture._future.cancel(true); // mayInterruptIfRunning
            }
        }
    }




    private class ValueAndFuture {
        public V _value;
        public ScheduledFuture<?> _future;

        public ValueAndFuture(V value, ScheduledFuture<?> future) {
            _value = value; // logging only
            _future = future;
        }

        @Override
        public String toString() {
            return "(" + _value + ")";
        }
    }
}
