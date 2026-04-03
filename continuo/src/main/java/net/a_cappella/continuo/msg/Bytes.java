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

import static net.a_cappella.continuo.PrestoConstants.BYTES;

public class Bytes extends Msg {
    private final byte[] _bytes;
    private int _count;

    public Bytes(Integer len) {
        _bytes = new byte[len];
    }

    public Bytes(String str) {
        _count = str.length();
        _bytes = str.getBytes();
    }

    @Override
    public int getMsgType() {
        return BYTES;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.put(_bytes, 0, _count);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _count = len;
        buffer.get(_bytes, 0, _count);
        return this;
    }

    @Override
    public void reset() {
        _count = 0;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof Bytes)) {
            return false;
        }
        Bytes other = (Bytes) obj;
        if (_count != other._count) {
            return false;
        }
        for (int i = 0; i < _count; i++) {
            if (_bytes[i] != other._bytes[i]) {
                return false;
            }
        }
        return true;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        for (int i = 0; i < _count; i++) {
            hash += _bytes[i];
        }
        return hash;
    }

    @Override
    public String toString() {
        return new String(_bytes, 0, _count);
    }

    public void init(String str) {
        _count = str.length();
        for (int i = 0; i < _count; i++) {
            _bytes[i] = (byte) str.charAt(i);
        }
    }
}
