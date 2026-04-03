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
import sbe.generated.FtMonitorObjDecoder;
import sbe.generated.FtMonitorObjEncoder;

public class FtMonitorCoder extends AeronCoderImpl<FtMonitorObj> {
    private final FtMonitorObjEncoder ENCODER = new FtMonitorObjEncoder();
    private static final FtMonitorObjDecoder DECODER = new FtMonitorObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public FtMonitorCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER.groupName(_obj.getGroupName());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .actives(_obj.getActives())
                .ts(_obj.getTs());
    }

    @Override
    public void decodeKeys() {
        _obj.setGroupName(DECODER.groupName());
    }
    @Override
    public void decodeBody() {
        _obj.setActives(DECODER.actives());
        _obj.setTs(DECODER.ts());
    }

}
