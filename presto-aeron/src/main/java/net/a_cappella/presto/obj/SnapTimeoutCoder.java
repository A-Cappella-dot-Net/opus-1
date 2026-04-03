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

package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.SnapTimeoutObjDecoder;
import sbe.generated.SnapTimeoutObjEncoder;

public class SnapTimeoutCoder extends AeronCoderImpl<SnapTimeoutObj> {
    private final SnapTimeoutObjEncoder ENCODER = new SnapTimeoutObjEncoder();
    private static final SnapTimeoutObjDecoder DECODER = new SnapTimeoutObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public SnapTimeoutCoder() {
    }

    @Override
    public void encodeKeys() {
    }
    @Override
    public void encodeBody() {
        ENCODER.ts(_obj.getTs());
    }

    @Override
    public void decodeKeys() {
    }
    @Override
    public void decodeBody() {
        _obj.setTs(DECODER.ts());
    }
}
