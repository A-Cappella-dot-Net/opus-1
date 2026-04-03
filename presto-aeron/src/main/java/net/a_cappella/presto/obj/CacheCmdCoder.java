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
import sbe.generated.CacheCmdObjDecoder;
import sbe.generated.CacheCmdObjEncoder;

public class CacheCmdCoder extends AeronCoderImpl<CacheCmdObj> {
    private final CacheCmdObjEncoder ENCODER = new CacheCmdObjEncoder();
    private static final CacheCmdObjDecoder DECODER = new CacheCmdObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public CacheCmdCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .command(_obj.getCommand())
                .cacheSubject(_obj.getCacheSubject());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .whereClause(_obj.getWhereClause());
    }

    @Override
    public void decodeKeys() {
        _obj.setCommand(DECODER.command());
        _obj.setCacheSubject(DECODER.cacheSubject());
    }
    @Override
    public void decodeBody() {
        _obj.setWhereClause(DECODER.whereClause());
    }
}
