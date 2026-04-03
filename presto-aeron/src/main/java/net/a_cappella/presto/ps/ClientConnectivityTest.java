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

import io.aeron.Aeron;
import io.aeron.Publication;
import io.aeron.Subscription;

public class ClientConnectivityTest {

    private final Aeron _aeron = Aeron.connect(new Aeron.Context());

    private final Publication _publication;
    private final Subscription _subscription;

    private static String _channel = "aeron:udp?endpoint=224.1.2.3:40123|interface=10.10.10.0/24|ttl=32";
    private final int _stream = 10;

    public ClientConnectivityTest() {
        _publication = _aeron.addPublication(_channel, _stream);
        _subscription = _aeron.addSubscription(_channel, _stream);
    }

    public void waitUntilConnected() {
        System.out.println("Connecting...");

        while (!_publication.isConnected());
        while (!_subscription.isConnected());

        System.out.println("Connected...");
    }

    public static void main(String[] args) {
        if (args.length>0) _channel = args[0];
        System.out.println("channel = "+_channel);
        ClientConnectivityTest cct = new ClientConnectivityTest();
        cct.waitUntilConnected();
    }
}
