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

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.msg.RegistrationRequest;
import net.a_cappella.continuo.msg.RegistrationResponse;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.EmbeddedMediaDriver;
import net.a_cappella.presto.msg.PathsSubjectsMsg;
import net.a_cappella.presto.obj.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;

import static net.a_cappella.continuo.utils.Utils.sleep;

public class ClientInstantiator {
    private static final Logger log = LoggerFactory.getLogger(ClientInstantiator.class);

    private final MsgCoder _msgCoder = new MsgCoder();
    private final TightLoopThread _tightLoopThread = new TightLoopThread();
    private final PublicationHelper _pubHelper = new PublicationHelper();
    private final AeronClient _client;

    {
        try {
            ObjectManager objectManager = ObjectManager.getInstance();
            objectManager.setMsgInstantiators(
                    Arrays.asList(
                            new MsgInstantiator(RegistrationRequest.class.getName()),
                            new MsgInstantiator(RegistrationResponse.class.getName()),
                            new MsgInstantiator(PathsSubjectsMsg.class.getName()),
                            new MsgInstantiator(MapObj.class.getName(), MapCoder.class.getName(), null),
                            new MsgInstantiator(TestObj.class.getName(), TestCoder.class.getName(), null),
                            new MsgInstantiator(PingObj.class.getName(), PingCoder.class.getName(), null)
                    )
            );
        } catch (Exception e) {
            log.error("", e);
        }

        _tightLoopThread.setMicroThreshold("100000");
        _tightLoopThread.setIdleStrategy("backoff");
        _tightLoopThread.start();
    }

    public ClientInstantiator(String connInfoStr, boolean embeddedDriver, String channelType) {
        if (embeddedDriver) {
            new EmbeddedMediaDriver().start();
            sleep(1_000);
        }

        _client = new AeronClient(_msgCoder, connInfoStr, "100", "0", _tightLoopThread, _pubHelper, null);
        _client.setChannelType(channelType);
        _client.start();
        _client.waitUntilInitialized();
    }


    public AeronClient getClient() {
        return _client;
    }

}
