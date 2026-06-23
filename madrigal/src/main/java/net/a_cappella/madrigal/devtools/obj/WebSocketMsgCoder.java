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

package net.a_cappella.madrigal.devtools.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.WebSocketMsgObjDecoder;
import sbe.generated.WebSocketMsgObjEncoder;

public class WebSocketMsgCoder extends AeronCoderImpl<WebSocketMsgObj> {

    private final WebSocketMsgObjEncoder ENCODER = new WebSocketMsgObjEncoder();
    private static final WebSocketMsgObjDecoder DECODER = new WebSocketMsgObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public WebSocketMsgCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .remote(_obj.getRemote());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .msg(_obj.getMsg());
    }

    @Override
    public void decodeKeys() {
        _obj.setRemote(DECODER.remote());
    }
    @Override
    public void decodeBody() {
        _obj.setMsg(DECODER.msg());
    }

}
