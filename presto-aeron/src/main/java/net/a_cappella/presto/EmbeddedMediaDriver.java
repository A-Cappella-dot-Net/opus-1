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

package net.a_cappella.presto;

import io.aeron.driver.MediaDriver;
import io.aeron.driver.ThreadingMode;
import net.a_cappella.continuo.ShutdownHook;
import org.agrona.concurrent.BackoffIdleStrategy;
import org.agrona.concurrent.BusySpinIdleStrategy;
import org.agrona.concurrent.IdleStrategy;
import org.agrona.concurrent.NoOpIdleStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class EmbeddedMediaDriver {
    private static final Logger log = LoggerFactory.getLogger(EmbeddedMediaDriver.class);

    private String _mediaDriverType = "shared";
    public String getMediaDriverType() {
        return _mediaDriverType;
    }
    public void setMediaDriverType(String mediaDriverType) {
        _mediaDriverType = mediaDriverType;
        if ("shared".equals(mediaDriverType)) {

        } else if ("dedicated".equals(mediaDriverType)) {
            _threadingMode = ThreadingMode.DEDICATED;
            _conductorIdleStrategy = new BusySpinIdleStrategy();
            _receiverIdleStrategy = new BusySpinIdleStrategy();
            _senderIdleStrategy = new BusySpinIdleStrategy();
        } else {
            _mediaDriverType = "shared";
            log.warn("Unrecognized mediaDriverType '" + mediaDriverType + "'; defaulting to 'shared'");
        }
    }
    private boolean _mediaDriverEnabled = true;
    public void setMediaDriverEnabled(boolean mediaDriverEnabled) {
        _mediaDriverEnabled = mediaDriverEnabled;
    }

    private ThreadingMode _threadingMode = ThreadingMode.SHARED;
    private IdleStrategy _conductorIdleStrategy = new BackoffIdleStrategy(1, 1, 1, 1);
    private IdleStrategy _receiverIdleStrategy = new NoOpIdleStrategy();
    private IdleStrategy _senderIdleStrategy = new NoOpIdleStrategy();

    private MediaDriver _driver = null;

    public void start() {
        if (_mediaDriverEnabled)
            new Thread(() -> {
                final MediaDriver.Context ctx = new MediaDriver.Context()
                        .termBufferSparseFile(false)
                        .threadingMode(_threadingMode)
                        .conductorIdleStrategy(_conductorIdleStrategy)
                        .receiverIdleStrategy(_receiverIdleStrategy)
                        .senderIdleStrategy(_senderIdleStrategy);

                try (MediaDriver ignored = _driver = MediaDriver.launch(ctx)) {
                    ShutdownHook.barrierAwait();
                    log.info("Stopping Aeron MediaDriver");
                }
            }).start();
    }

    public void stop() {
        if (_mediaDriverEnabled) {
            _driver.close();
            ShutdownHook.barrierSignal();
        }
    }
}
