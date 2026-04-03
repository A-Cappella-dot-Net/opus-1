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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.EcnUserStatusObjDecoder;
import sbe.generated.EcnUserStatusObjEncoder;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;

public class EcnUserStatusCoder extends AeronCoderImpl<EcnUserStatusObj> {

    private final EcnUserStatusObjEncoder ENCODER = new EcnUserStatusObjEncoder();
    private static final EcnUserStatusObjDecoder DECODER = new EcnUserStatusObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnUserStatusCoder() {}

    @Override
    public void decodeKeys() {
        _obj.setMadrigalMode(EnumConverters.convert(DECODER.mode()));
        _obj.setInstance(DECODER.instance());
        _obj.setUid(DECODER.uid());
        _obj.setEcn(DECODER.ecn());
        _obj.setEcnUid(DECODER.ecnUid());
    }
    @Override
    public void encodeKeys() {
        ENCODER
            .mode(EnumConverters.convert(_obj.getMadrigalMode()))
            .instance(_obj.getInstance())
            .uid(_obj.getUid())
            .ecn(_obj.getEcn())
            .ecnUid(_obj.getEcnUid())
        ;
    }

    @Override
    public void decodeBody() {
        _obj.setOp(EnumConverters.convert(DECODER.op()));
        _obj.setEcnPwd(DECODER.ecnPwd());
        if (RESPONSE == _obj.getMadrigalMode()) {
            _obj.setStatus(EnumConverters.convert(DECODER.status()));
        }
        _obj.setTs(DECODER.ts());

        String text = null;
        if (RESPONSE == _obj.getMadrigalMode()) {
		    text = DECODER.text();
		    if (text.isEmpty()) text = null;
        }
        _obj.setText(text);
    }

    @Override
    public void encodeBody() {
        ENCODER.op(EnumConverters.convert(_obj.getOp()));
        ENCODER.ecnPwd(_obj.getEcnPwd());
        if (RESPONSE == _obj.getMadrigalMode()) {
            ENCODER.status(EnumConverters.convert(_obj.getStatus()));
        }
        ENCODER.ts(_obj.getTs());

        String text = null;
        if (RESPONSE == _obj.getMadrigalMode()) text = _obj.getText();
        ENCODER.text(text==null ? "" : text);
    }
}
