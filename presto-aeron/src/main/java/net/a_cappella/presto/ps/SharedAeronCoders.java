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

import org.agrona.BitUtil;
import org.agrona.BufferUtil;
import org.agrona.concurrent.UnsafeBuffer;

public class SharedAeronCoders extends SharedCoders {
    private static final int BUFFER_SIZE = 4096;

    private final UnsafeBuffer _buffer = new UnsafeBuffer(BufferUtil.allocateDirectAligned(BUFFER_SIZE, BitUtil.CACHE_LINE_LENGTH));
    private int _len;

    public UnsafeBuffer getBuffer() {
        return _buffer;
    }

    public void setLen(int len) {
        _len = len;
    }
    public int getLen() {
        return _len;
    }
}
