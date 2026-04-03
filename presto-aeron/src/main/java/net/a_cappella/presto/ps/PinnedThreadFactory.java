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

import net.openhft.affinity.Affinity;
import net.openhft.affinity.AffinityLock;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ThreadFactory;

public class PinnedThreadFactory implements ThreadFactory {
    private static final Logger log = LoggerFactory.getLogger(PinnedThreadFactory.class);

    private final String _name;
    private final int _cpu;

    public PinnedThreadFactory(String name, int cpu) {
        _name = name;
        _cpu = cpu;
    }

    @Override
    public Thread newThread(@NotNull Runnable r) {
        String name = _name + "-pinned-to-" + _cpu;

        return new Thread(() -> {
            if (_cpu>0) {
                Affinity.setAffinity(_cpu);
                log.info("Pinned to CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
            } else {
                log.info("Starting on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
            }

            r.run();

            if (_cpu<=0) log.info("Ending on CPU "+Affinity.getCpu()+" of "+AffinityLock.BASE_AFFINITY);
        }, name);
    }

}
