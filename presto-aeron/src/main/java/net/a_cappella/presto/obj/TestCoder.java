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
import sbe.generated.SbeBoolean;
import sbe.generated.SbeMyEnum;
import sbe.generated.TestObjDecoder;
import sbe.generated.TestObjEncoder;

public class TestCoder extends AeronCoderImpl<TestObj> {
    private final TestObjEncoder ENCODER = new TestObjEncoder();
    private static final TestObjDecoder DECODER = new TestObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public TestCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .aShort(_obj._aShort)
                .anInt(_obj._anInt)
                .aChar(_obj._aChar);
    }
    @Override
    public void encodeBody() {
        ENCODER
                .aLong(_obj._aLong)
                .aTimestamp(_obj._aTimestamp)
                .aNanos(_obj._aNanos)
                .aTime(_obj._aTime)
                .aDate(_obj._aDate)
                .aFloat(_obj._aFloat)
                .aDouble(_obj._aDouble)
                .aBoolean(_obj._aBoolean?SbeBoolean.TRUE:SbeBoolean.FALSE)
                .anEnum(convert(_obj._anEnum))
                .aString(_obj._aString==null ? "" : _obj._aString)
        ;
    }

    @Override
    public void decodeKeys() {
        _obj._aShort     = DECODER.aShort();
        _obj._anInt      = DECODER.anInt();
        _obj._aChar      = (char) DECODER.aChar();
    }
    @Override
    public void decodeBody() {
        _obj._aLong      = DECODER.aLong();
        _obj._aTimestamp = DECODER.aTimestamp();
        _obj._aNanos     = DECODER.aNanos();
        _obj._aTime      = DECODER.aTime();
        _obj._aDate      = DECODER.aDate();
        _obj._aFloat     = DECODER.aFloat();
        _obj._aDouble    = DECODER.aDouble();
        _obj._aBoolean   = DECODER.aBoolean() == SbeBoolean.TRUE;
        _obj._anEnum     = convert(DECODER.anEnum());
        _obj._aString    = DECODER.aString(); if (_obj._aString.isEmpty()) _obj._aString = null;
    }




    private SbeMyEnum convert(MyEnum pubType) {
        switch (pubType) {
            case ONE: return SbeMyEnum.ONE;
            case TWO: return SbeMyEnum.TWO;
            case THREE: return SbeMyEnum.THREE;
            default: return SbeMyEnum.ZERO;
        }
    }
    private MyEnum convert(SbeMyEnum sbePubType) {
        switch (sbePubType) {
            case ONE: return MyEnum.ONE;
            case TWO: return MyEnum.TWO;
            case THREE: return MyEnum.THREE;
            default: return MyEnum.ZERO;
        }
    }
}
