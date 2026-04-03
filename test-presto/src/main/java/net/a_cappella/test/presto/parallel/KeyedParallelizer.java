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

package net.a_cappella.test.presto.parallel;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.function.Supplier;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.util.concurrent.ThreadFactoryBuilder;

import net.a_cappella.continuo.ShutdownHook;

public class KeyedParallelizer<T, S> implements IKeyedParallelizer<T> {
    private static final Logger log = LoggerFactory.getLogger(KeyedParallelizer.class);

    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(KeyedParallelizer.class.getSimpleName() + "-%d").build();

    private final int _poolSize;
    private final IKPHandler<T, S> _messageHandler;

    private final ExecutorService _executor;
    private BlockingQueue<IKPMessage<T>> _queues[];
    private final Supplier<S> _supplier;

    public KeyedParallelizer(IKPHandler<T, S> eventHandler, int poolSize) {
        this(eventHandler, poolSize, null);
    }
    @SuppressWarnings("unchecked")
    public KeyedParallelizer(IKPHandler<T, S> messageHandler, int poolSize, Supplier<S> supplier) {
        _messageHandler = messageHandler;
        _poolSize = poolSize;
        _supplier = supplier;

        _executor = Executors.newFixedThreadPool(poolSize, _threadFactory);
        _queues = new LinkedBlockingQueue[poolSize];
        for (int i = 0; i < poolSize; i++) {
            _queues[i] = new LinkedBlockingQueue<>();
        }
    }

    @Override
    public void init() {
		ShutdownHook.registerShutdownAction(() -> stop());
        for (int i = 0; i < _poolSize; i++) {
            _executor.submit(new ThreadProcessor(_queues[i], (_supplier == null) ? null : _supplier.get()));
        }
    }

    @Override
    public void stop() {
        log.info("Stopping KeyedParallelizer");
        PoisonPill poisonPill = new PoisonPill();
        for (int i = 0; i < _poolSize; i++) {
        	_queues[i].offer(poisonPill);
        }
        _executor.shutdown();
    }

    @Override
    public void parallelize(IKPMessage<T> msg) {
        T msgKey = msg.getThreadKey();
        int hash = Math.abs(msgKey.hashCode()) % _poolSize;
        _queues[hash].offer(msg);
    }

    private class ThreadProcessor implements Runnable {
        private final BlockingQueue<IKPMessage<T>> _queue;
        private final S _threadLocalObject;

        private ThreadProcessor(BlockingQueue<IKPMessage<T>> queue, S threadLocalObject) {
            _queue = queue;
            _threadLocalObject = threadLocalObject;
        }

        @Override
        public void run() {
            log.info("Starting ThreadProcessor");
            while (true) {
                try {
                    IKPMessage<T> t = _queue.take();
                    if (t instanceof KeyedParallelizer.PoisonPill) break;
                    _messageHandler.handleMessage(t, _threadLocalObject);
                } catch (Exception x) {
                    log.error("", x);
                }
            }
            log.info("ThreadProcessor Stopped");
        }
    }
    
    private class PoisonPill implements IKPMessage<T> {
		@Override
		public T getThreadKey() {
			return null;
		}

		@Override
		public void setThreadKey(T key) {}
    }
}
