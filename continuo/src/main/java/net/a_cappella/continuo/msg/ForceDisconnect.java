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

package net.a_cappella.continuo.msg;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.FORCE_DISCONNECT;

public class ForceDisconnect extends Msg {

    public ForceDisconnect() {}

    @Override
    public int getMsgType() {
        return FORCE_DISCONNECT;
    }

    @Override
    public void encode(ByteBuffer buffer) {}

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        return this;
    }

    @Override
    public void reset() {}

    @Override
    public boolean equals(Object obj) {
        return obj instanceof ForceDisconnect;
    }

    @Override
    public int hashCode() {
        return 0;
    }

    @Override
    public String toString() {
        return "";
    }
}
