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
import sbe.generated.EcnCredentialsObjDecoder;
import sbe.generated.EcnCredentialsObjEncoder;

public class EcnCredentialsCoder extends AeronCoderImpl<EcnCredentialsObj> {

    private final EcnCredentialsObjEncoder ENCODER = new EcnCredentialsObjEncoder();
    private static final EcnCredentialsObjDecoder DECODER = new EcnCredentialsObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnCredentialsCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setUid(DECODER.uid());
        _obj.setEcn(DECODER.ecn());
    }
    @Override
    public void decodeBody() {
        _obj.setEcnUid(DECODER.ecnUid());
        _obj.setEcnPwd(DECODER.ecnPwd());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .uid(_obj.getUid())
                .ecn(_obj.getEcn())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .ecnUid(_obj.getEcnUid())
                .ecnPwd(_obj.getEcnPwd())
                .ts(_obj.getTs())
        ;
    }
}
