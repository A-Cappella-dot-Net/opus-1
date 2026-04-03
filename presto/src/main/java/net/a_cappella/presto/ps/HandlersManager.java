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

package net.a_cappella.presto.ps;

import gnu.trove.map.TLongObjectMap;
import gnu.trove.map.hash.TLongObjectHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Consumer;

public class HandlersManager {
    private static final Logger log = LoggerFactory.getLogger(HandlersManager.class);

    public static final boolean USE_CAS = false;

    public final PubSubClient _client;

    private final AtomicInteger _cas = new AtomicInteger();
    private final Lock _lock = new ReentrantLock();

    private final TLongObjectMap<SnSHandler> _handlersBySubsId = new TLongObjectHashMap<>();
    private final HandlersBySubject _handlersBySubject = new HandlersBySubject();

    public HandlersManager(PubSubClient client) {
        _client = client;
    }

    public void register(SnSHandler handler) {
        if (USE_CAS) {
            while(!_cas.compareAndSet(0, 1));
            unsafeRegister(handler);
            _cas.set(0);
        } else {
            try {
                _lock.lock();
                unsafeRegister(handler);
            } finally {
                _lock.unlock();
            }
        }
    }
    private void unsafeRegister(SnSHandler handler) {
        _handlersBySubsId.put(handler.getSubId(), handler);
        _handlersBySubject.put(handler.getSubject(), handler);
    }

    public void unregister(long subId) {
        if (USE_CAS) {
            while(!_cas.compareAndSet(0, 1));
            unsafeUnregister(subId);
            _cas.set(0);
        } else {
            try {
                _lock.lock();
                unsafeUnregister(subId);
            } finally {
                _lock.unlock();
            }
        }
    }
    private void unsafeUnregister(long subId) {
        SnSHandler handler = _handlersBySubsId.remove(subId);
        if (handler==null) {
            log.info("unsubscribe({}) => Undefined subscription...", subId);
        } else {
            handler.shutdown();
            String subject = handler.getSubject();
            _handlersBySubject.remove(subject, handler);
            _client.deactivateSubject(subject);
        }
    }

    public void passMsgToAllSubjectSubscribers(String subject, Consumer<List<SnSHandler>> consumer) {
        if (USE_CAS) {
            while(!_cas.compareAndSet(0, 1));
            consumer.accept(_handlersBySubject.get(subject));
            _cas.set(0);
        } else {
            try {
                _lock.lock();
                consumer.accept(_handlersBySubject.get(subject));
            } finally {
                _lock.unlock();
            }
        }
    }
}
