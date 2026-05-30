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

package net.a_cappella.continuo.utils.tightloop;

import java.util.ArrayList;
import java.util.List;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.utils.Utils;
import org.agrona.concurrent.IdleStrategy;
import org.agrona.concurrent.ManyToOneConcurrentArrayQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.openhft.affinity.Affinity;
import net.openhft.affinity.AffinityLock;

public class TightLoopThread {
    private static final Logger log = LoggerFactory.getLogger(TightLoopThread.class);
    private static final int QUEUE_LEN = 100;
    private static final boolean LOCK_FREE = true;

    private final Thread _thread;
    private final List<TightLoopSnippet> _snippetsToBeAddedL = (LOCK_FREE) ? null : new ArrayList<>();
    private final ManyToOneConcurrentArrayQueue<TightLoopSnippet> _snippetsToBeAddedQ = (LOCK_FREE) ? new ManyToOneConcurrentArrayQueue<>(QUEUE_LEN) : null;

    private IdleStrategy _idleStrategy = Utils.getIdleStrategy("backoff");
    public void setIdleStrategy(Object idleStrategyObj) {
        _idleStrategy = Utils.getIdleStrategy(idleStrategyObj, "backoff");
    }

    private long _microThreshold = 10;
    private long _nanoThreshold = _microThreshold*1000;
    public void setMicroThreshold(String microThreshold) {
        _microThreshold = Utils.parseAsLong("microThreshold", microThreshold, _microThreshold);
        _nanoThreshold = _microThreshold*1000;
    }

    private int _pinToCpu = 0;
    public void setPinToCpu(String pinToCpu) {
        _pinToCpu = Utils.parseAsInt("pinToCpu", pinToCpu, _pinToCpu);
    }

    private volatile boolean _stop = false;

    public TightLoopThread() {
        ShutdownHook.registerShutdownAction(() -> stop());

        _thread = new Thread("TightLoopThread") {
            private final List<TightLoopSnippet> _snippets = new ArrayList<>();
            private final List<TightLoopSnippet> _snippetsToBeRemoved = new ArrayList<>();

            public void run() {
                if (_pinToCpu>0) {
                    Affinity.setAffinity(_pinToCpu);
                    log.info("Pinned to CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
                } else {
                    log.info("Starting on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
                }

                if (log.isDebugEnabled()) {
                    while (!_stop) {
                        int workCount = 0;
                        for (int i=0; i<_snippets.size(); i++) {
                            final TightLoopSnippet snippet = _snippets.get(i);

                            long startNanos = System.nanoTime();

                            Exception e = null;
                            int wc;
                            try {
                                wc = snippet.executeSnippet();
                            } catch (Exception x) {
                                e = x;
                                wc = -1;
                            }

                            long elapsedNanos = System.nanoTime()-startNanos;
                            if (elapsedNanos > _nanoThreshold) {
                                log.warn(String.format("%s took %,d>%,d micros to execute. This negatively impacts the performance of the TightLoopThread. Consider alternatives...", snippet, elapsedNanos/1000, _microThreshold));
                            }

                            if (wc < 0) {
                                if (e != null) log.error("", e);
                                _snippetsToBeRemoved.add(snippet);
                            } else {
                                workCount += wc;
                            }
                        }

                        if (!_snippetsToBeRemoved.isEmpty()) {
                            _snippets.removeAll(_snippetsToBeRemoved);
                            _snippetsToBeRemoved.clear();
                        }
                        if (LOCK_FREE) {
                            TightLoopSnippet s = _snippetsToBeAddedQ.poll();
                            while (s != null) {
                                _snippets.add(s);
                                s = _snippetsToBeAddedQ.poll();
                            }
                        } else {
                            synchronized (TightLoopThread.this) {
                                if (!_snippetsToBeAddedL.isEmpty()) {
                                    _snippets.addAll(_snippetsToBeAddedL);
                                    _snippetsToBeAddedL.clear();
                                }
                            }
                        }

                        _idleStrategy.idle(workCount);
                    }
                } else {
                    while (!_stop) {
                        int workCount = 0;
                        for (int i=0; i<_snippets.size(); i++) {
                            final TightLoopSnippet snippet = _snippets.get(i);

                            Exception e = null;
                            int wc;
                            try {
                                wc = snippet.executeSnippet();
                            } catch (Exception x) {
                                e = x;
                                wc = -1;
                            }

                            if (wc < 0) {
                                if (e != null) log.error("", e);
                                _snippetsToBeRemoved.add(snippet);
                            } else {
                                workCount += wc;
                            }
                        }

                        if (!_snippetsToBeRemoved.isEmpty()) {
                            _snippets.removeAll(_snippetsToBeRemoved);
                            _snippetsToBeRemoved.clear();
                        }
                        if (LOCK_FREE) {
                            TightLoopSnippet s = _snippetsToBeAddedQ.poll();
                            while (s != null) {
                                _snippets.add(s);
                                s = _snippetsToBeAddedQ.poll();
                            }
                        } else {
                            synchronized (TightLoopThread.this) {
                                if (!_snippetsToBeAddedL.isEmpty()) {
                                    _snippets.addAll(_snippetsToBeAddedL);
                                    _snippetsToBeAddedL.clear();
                                }
                            }
                        }

                        _idleStrategy.idle(workCount);
                    }
                }

                if (_pinToCpu<=0) log.info("Ending on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
                log.info("TightLoopThread Stopped");
            }
        };
    }

    public void start() {
        log.info("IdleStrategy = " + _idleStrategy);
        _thread.start();
    }

    public void stop() {
        log.info("Stopping TightLoopThread");
        _stop = true;
    }

    public boolean isCurrentThread() {
        return _thread == Thread.currentThread();
    }

    public void add(TightLoopSnippet op) {
        if (LOCK_FREE) {
            boolean added;
            do {
                added = _snippetsToBeAddedQ.offer(op);
            } while (!added) ;
        } else {
            synchronized (this) {
                _snippetsToBeAddedL.add(op);
            }
        }
    }
}
