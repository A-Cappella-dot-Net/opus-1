package net.a_cappella.continuo;

import org.agrona.concurrent.ShutdownSignalBarrier;

import java.util.ArrayList;
import java.util.List;

public class ShutdownHook {
    private static final ShutdownSignalBarrier _shutdownSignalBarrier = new ShutdownSignalBarrier();
    private static final List<Runnable> _shutdownActions = new ArrayList<>();
    private static final Object _lock = new Object();

    static {
        Thread thread =
                new Thread(() -> {
                    _shutdownSignalBarrier.await();
                    synchronized (_lock) {
                        _shutdownActions.stream().forEach(action -> action.run());
                    }
                });
        thread.setDaemon(true);
        thread.start();
    }

    public static void barrierAwait() {
        _shutdownSignalBarrier.await();
    }

    public static void barrierSignal() {
        _shutdownSignalBarrier.signalAll();
    }

    public static void registerShutdownAction(Runnable action) {
        synchronized (_lock) {
            _shutdownActions.add(action);
        }
    }
}
