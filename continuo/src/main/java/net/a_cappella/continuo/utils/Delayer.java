package net.a_cappella.continuo.utils;

import java.util.function.Consumer;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.managed.IPoolable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Delayer<T extends IPoolable> {
    private static final Logger log = LoggerFactory.getLogger(Delayer.class);

    private final String _threadName;
    private final Consumer<T> _consumer;
    private final boolean _stopOnEmptyQueue;

    public Delayer(String name, Consumer<T> consumer) {
        this(name, consumer, false);
    }

    public Delayer(String name, Consumer<T> consumer, boolean stopOnEmptyQueue) {
        _threadName = name+"DelayerThread";
        _consumer = consumer;
        _stopOnEmptyQueue = stopOnEmptyQueue;
    }

    public void start() {
        final MyDelayThread mdt = new MyDelayThread();
        mdt.setName(_threadName);
        mdt.start();
    }

    public void add(long delayInMillis, T payload) {
        _delayQueue.add(delayInMillis, payload);
    }


    private class MyDelayThread extends Thread {
        private final MyDelayedObj _obj = new MyDelayedObj();

        public void run() {
            ShutdownHook.registerShutdownAction(() -> signalStop());
            log.info("Starting "+_threadName);
            while (true) {
                try {
                    _delayQueue.take(_obj);
                    if (_obj.isPoisonPill()) break;
                    _consumer.accept(_obj._payload);
                    if (_stopOnEmptyQueue && _delayQueue.size() == 0) break;
                } catch (Exception e) {
                    log.error(""+_obj, e);
                } finally {
                    if (!_obj.isPoisonPill()) _obj._payload.stopUsing();
                }
            }
            log.info(_threadName+" Stopped");
        }

        public void signalStop() {
            log.info("Stopping "+_threadName);
            _delayQueue.addPoisonPill();
        }
    }

    private final MyDelayQueue _delayQueue = new MyDelayQueue(new MyDelayedObj());

    private class MyDelayQueue extends DelayQueue<MyDelayedObj> {
        public MyDelayQueue(MyDelayedObj clone) {
            super(100, clone);
        }

        public MyDelayedObj add(long delayInMillis, T payload) {
            MyDelayedObj obj = add(delayInMillis);
            payload.startUsing();
            obj._payload = payload;
            return obj;
        }

        @Override
        public void updateFrom(MyDelayedObj dst, MyDelayedObj src) {
            super.updateFrom(dst, src);
            dst._payload = src._payload;
        }
    }

    private class MyDelayedObj extends DelayedObj {
        private T _payload;
        private MyDelayedObj() {}
        public MyDelayedObj newInstance() {
            return new MyDelayedObj();
        }
    }
}
