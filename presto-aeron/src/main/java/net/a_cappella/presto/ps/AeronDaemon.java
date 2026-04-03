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

import io.aeron.driver.MediaDriver;
import io.aeron.driver.ThreadingMode;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.presto.ft.collective.CollectiveMember;
import org.agrona.concurrent.IdleStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.channels.SelectionKey;

import static net.a_cappella.continuo.utils.Utils.keyHash;
import static org.agrona.SystemUtil.loadPropertiesFile;

public class AeronDaemon extends CollectiveMember {
    private static final Logger log = LoggerFactory.getLogger(AeronDaemon.class);

    public final String _mediaDriverProps;

    public AeronDaemon(MsgCoder coder, int coreListVers, String coreList) {
        this(coder, coreListVers, coreList, null);
    }

    public AeronDaemon(MsgCoder coder, int coreListVers, String coreList, String mediaDriverProps) {
        super(coder, coreListVers, coreList);
        _mediaDriverProps = mediaDriverProps;
    }

    private IdleStrategy _conductorIdleStrategy = net.a_cappella.continuo.utils.Utils.BACKOFF_IDLE_STRATEGY;
    public void setConductorIdleStrategy(Object conductorIdleStrategy) {
        _conductorIdleStrategy = net.a_cappella.continuo.utils.Utils.getIdleStrategy(conductorIdleStrategy, "backoff");
    }

    private IdleStrategy _receiverIdleStrategy = net.a_cappella.continuo.utils.Utils.NO_OP_IDLE_STRATEGY;
    public void setReceiverIdleStrategy(Object receiverIdleStrategy) {
        _receiverIdleStrategy = net.a_cappella.continuo.utils.Utils.getIdleStrategy(receiverIdleStrategy, "nop");
    }

    private IdleStrategy _senderIdleStrategy = net.a_cappella.continuo.utils.Utils.NO_OP_IDLE_STRATEGY;
    public void setSenderIdleStrategy(Object senderIdleStrategy) {
        _senderIdleStrategy = net.a_cappella.continuo.utils.Utils.getIdleStrategy(senderIdleStrategy, "nop");
    }

    private ThreadingMode _threadingMode = ThreadingMode.SHARED;
    public void setThreadingMode(String threadingMode) {
        _threadingMode = Utils.getThreadingMode(threadingMode, ThreadingMode.SHARED);
    }

    private int _pinToCpu = 0;
    public void setPinToCpu(String pinToCpu) {
        _pinToCpu = net.a_cappella.continuo.utils.Utils.parseAsInt("pinToCpu", pinToCpu, _pinToCpu);
    }

    @Override
    public void start() {
        AeronDaemon daemon = this;

        super.start();

        new Thread( () -> {
            if (_mediaDriverProps != null) loadPropertiesFile(_mediaDriverProps);

            final MediaDriver.Context ctx = new MediaDriver.Context()
                    .termBufferSparseFile(false)
                    .threadingMode(_threadingMode)
                    .conductorIdleStrategy(_conductorIdleStrategy)
                    .receiverIdleStrategy(_receiverIdleStrategy)
                    .senderIdleStrategy(_senderIdleStrategy);
            ctx.socketMulticastTtl(32);

            if (_threadingMode == ThreadingMode.SHARED) {
                ctx.sharedThreadFactory(new PinnedThreadFactory("md-shared", _pinToCpu));
            } else if (_threadingMode == ThreadingMode.SHARED_NETWORK) {
                ctx
                        .conductorThreadFactory(new PinnedThreadFactory("md-conductor", _pinToCpu))
                        .sharedNetworkThreadFactory(new PinnedThreadFactory("md-shared-network", _pinToCpu-1));
            } else { // DEDICATED
                ctx
                        .conductorThreadFactory(new PinnedThreadFactory("md-conductor", _pinToCpu))
                        .senderThreadFactory(new PinnedThreadFactory("md-sender", _pinToCpu-1))
                        .receiverThreadFactory(new PinnedThreadFactory("md-receiver", _pinToCpu-2));
            }

            try (MediaDriver ignored = MediaDriver.launch(ctx)) {
                ShutdownHook.barrierAwait();
                log.info("Stopping Aeron MediaDriver");
                daemon.stop();
            }
        }).start();
    }

    @Override
    protected void onRegistrationResponse(ClientPipe pipe) {
        log.info("onRegistrationResponse {}", pipe);
    }

    @Override
    protected void onMsg(ClientPipe pipe, Msg msg) {
        log.info("onMsg received {} on ClientPipe {}", msg, pipe);
    }

    @Override
    protected void onMsg(SelectionKey key, Msg msg) {
        log.info("onMsg received {} on SelectionKey {}", msg, keyHash(key));
    }
}
