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

package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;

import java.nio.ByteBuffer;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

import static net.a_cappella.continuo.PrestoConstants.SOURCES_PORTS;

public class SourcesMsg extends Msg {
    public String _host;
    public Set<Short> _ports;

    public SourcesMsg() {
        this(null);
    }

    public SourcesMsg(String host) {
        _host = host;
    }

    @Override
    public int getMsgType() {
        return SOURCES_PORTS;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        putString(buffer, _host);
        if (_ports == null) {
            buffer.putShort((short) -1);
        } else {
            buffer.putShort((short) _ports.size());
            for (Short port : _ports) {
                buffer.putShort(port);
            }
        }
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _host = getString(buffer);
        short size = buffer.getShort();
        if (size >= 0) {
            _ports = new HashSet<>(size);
            for (int i = 0; i < size; i++) {
                _ports.add(buffer.getShort());
            }
        } else {
            _ports = null;
        }
        return this;
    }

    @Override
    public void reset() {
        _host = null;
        _ports = null;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof SourcesMsg)) {
            return false;
        }
        SourcesMsg other = (SourcesMsg) obj;
        return _host.equals(other._host) && Objects.equals(_ports, other._ports);
    }

    @Override
    public int hashCode() {
        return Objects.hash(_host, _ports);
    }

    @Override
    public String toString() {
        return "{" + _host + ":" + _ports + "}";
    }

    public void addPort(Short port) {
        if (_ports == null) _ports = new HashSet<>();
        _ports.add(port);
    }

}
