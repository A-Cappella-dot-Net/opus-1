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

package net.a_cappella.presto.ft.collective.proxy;

import net.a_cappella.presto.ft.collective.proxy.events.ProxyEvent;
import net.a_cappella.presto.ft.collective.proxy.events.ProxyStartEvent;
import net.a_cappella.presto.ft.collective.proxy.events.ProxyStopEvent;
import net.a_cappella.presto.testagent.CntFromTo;
import net.a_cappella.presto.testagent.ThreadMarker;
import org.agrona.concurrent.BackoffIdleStrategy;
import org.agrona.concurrent.IdleStrategy;
import org.jctools.queues.MpscLinkedQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Queue;
import java.util.concurrent.CountDownLatch;

public class NioProxy {
    private static final Logger log = LoggerFactory.getLogger(NioProxy.class);

    // graceful shutdown
    private volatile boolean _stop = false;
    private CountDownLatch _stopLatch;

    private SinkAndPipes[] _sinkAndPipesArr;
    private final Queue<ProxyEvent> _eventQueue = new MpscLinkedQueue<>();

    public NioProxy(CntFromTo[] cntFromToArr) {
        _sinkAndPipesArr = new SinkAndPipes[cntFromToArr.length];
        for (int i = 0; i < cntFromToArr.length; i++) {
            _sinkAndPipesArr[i] = new SinkAndPipes(_eventQueue, cntFromToArr[i]._from, cntFromToArr[i]._to, cntFromToArr[i]._cnt);
        }
    }

    public void start() {
        _stop = false;
        _stopLatch = new CountDownLatch(1);

        _eventQueue.add(new ProxyStartEvent(this));

        Thread eventThread = new Thread(() -> {
            ThreadMarker.setMark(null); // prevent proxy-internal threads from inheriting test-agent routing marks
            IdleStrategy idleStrategy = new BackoffIdleStrategy();
            while (!_stop) {
                ProxyEvent e;
                int workCount = 0;
                while ((e = _eventQueue.poll()) != null) {
                    try {
                        e.apply();
                    } catch (Exception x) {
                        log.error("", x);
                    }
                    workCount++;
                }
                idleStrategy.idle(workCount);
            }
        });
        eventThread.setName("ProxyEventThread");
        eventThread.start();
    }
    public void handleStartEvent() {
        log.info("Starting NioProxy");
        for (int i = 0; i < _sinkAndPipesArr.length; i++) {
            _sinkAndPipesArr[i].start();
        }
    }

    public void stop() {
        _eventQueue.add(new ProxyStopEvent(this));
        try {
            _stopLatch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    public void handleStopEvent() {
        log.info("Stopping NioProxy");
        _stop = true;
        for (int i = 0; i < _sinkAndPipesArr.length; i++) {
            _sinkAndPipesArr[i].stop();
        }
        _stopLatch.countDown();
        log.info("NioProxy Stopped");
    }

}
