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

package net.a_cappella.presto.ft.collective.proxy.events;

import net.a_cappella.presto.ft.collective.proxy.ProxyPipe;
import net.a_cappella.presto.ft.collective.proxy.SingleProxy;

public class MsgFromDstEvent implements ProxyEvent {
    private final SingleProxy _singleProxy;
    private final ProxyPipe _pipe;
    private final byte[] _bytes;

    public MsgFromDstEvent(SingleProxy singleProxy, ProxyPipe pipe, byte[] bytes) {
        _singleProxy = singleProxy;
        _pipe = pipe;
        _bytes = bytes;
    }

    @Override
    public void apply() {
        _singleProxy.handleMsgFromDstEvent(_pipe, _bytes);
    }
}
