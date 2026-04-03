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
import sbe.generated.EcnImbalanceObjDecoder;
import sbe.generated.EcnImbalanceObjEncoder;

public class EcnImbalanceCoder extends AeronCoderImpl<EcnImbalanceObj> {

    private final EcnImbalanceObjEncoder ENCODER = new EcnImbalanceObjEncoder();
    private static final EcnImbalanceObjDecoder DECODER = new EcnImbalanceObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnImbalanceCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setEcn(DECODER.ecn());
        _obj.setSecurityID(DECODER.securityID());
        _obj.setBook(EnumConverters.convert(DECODER.book()));
    }
    @Override
    public void decodeBody() {
        _obj.setAuction(EnumConverters.convert(DECODER.auction()));
        _obj.setSide(EnumConverters.convert(DECODER.side()));
        _obj.setMatched(DECODER.matched());
        _obj.setSurplus(DECODER.surplus());
        _obj.setPrice(DECODER.price());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
			.ecn(_obj.getEcn())
	        .securityID(_obj.getSecurityID())
	        .book(EnumConverters.convert(_obj.getBook()))
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .auction(EnumConverters.convert(_obj.isAuction()))
                .side(EnumConverters.convert(_obj.getSide()))
                .matched(_obj.getMatched())
                .surplus(_obj.getSurplus())
                .price(_obj.getPrice())
                .ts(_obj.getTs())
        ;
    }

}
