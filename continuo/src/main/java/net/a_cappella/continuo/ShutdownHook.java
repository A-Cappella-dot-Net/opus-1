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
