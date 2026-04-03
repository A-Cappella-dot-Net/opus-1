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
import sbe.generated.SbeBoolean;
import sbe.generated.UserStatusObjDecoder;
import sbe.generated.UserStatusObjEncoder;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;

public class UserStatusCoder extends AeronCoderImpl<UserStatusObj> {

    private final UserStatusObjEncoder ENCODER = new UserStatusObjEncoder();
    private static final UserStatusObjDecoder DECODER = new UserStatusObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public UserStatusCoder() {}

    @Override
    public void decodeKeys() {
        _obj.setMadrigalMode(EnumConverters.convert(DECODER.mode()));
        _obj.setUid(DECODER.uid());
        _obj.setClId(DECODER.clId());
        _obj.setReqId(DECODER.reqId());
    }
    @Override
    public void encodeKeys() {
        ENCODER
            .mode(EnumConverters.convert(_obj.getMadrigalMode()))
            .uid(_obj.getUid())
            .clId(_obj.getClId())
            .reqId(_obj.getReqId())
        ;
    }

    @Override
    public void decodeBody() {
        _obj.setOp(EnumConverters.convert(DECODER.op()));

        if (REQUEST == _obj.getMadrigalMode()) {
            _obj.setPwd(DECODER.pwd());
            _obj.setRejectIfLoggedIn(DECODER.rejectIfLoggedIn() == SbeBoolean.TRUE);
            _obj.setForceLogout(DECODER.forceLogout() == SbeBoolean.TRUE);
        } else { // RESPONSE == _madrigalMsgType
            _obj.setStatus(EnumConverters.convert(DECODER.status()));
            _obj.setReqStatus(EnumConverters.convert(DECODER.reqStatus()));
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

        if (REQUEST == _obj.getMadrigalMode()) {
            ENCODER
                .pwd(_obj.getPwd())
                .rejectIfLoggedIn(_obj.isRejectIfLoggedIn()?SbeBoolean.TRUE:SbeBoolean.FALSE)
                .forceLogout(_obj.isForceLogout()?SbeBoolean.TRUE:SbeBoolean.FALSE)
            ;
        } else { // RESPONSE == _madrigalMsgType
            ENCODER
                .status(EnumConverters.convert(_obj.getStatus()))
                .reqStatus(EnumConverters.convert(_obj.getReqStatus()))
            ;
        }
        ENCODER.ts(_obj.getTs());

        String text = null;
        if (RESPONSE == _obj.getMadrigalMode()) text = _obj.getText();
        ENCODER.text(text==null ? "" : text);
    }
}
