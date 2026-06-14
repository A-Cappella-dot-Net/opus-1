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

package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.FtMsgType;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.FT_MEMBER;

public class FtMemberMsg extends FtMsg {

    public int _instance;
    public int _activeGoal;
    public int _stripeNo;
    public int _ofStripes;

    public FtMemberMsg() {
        this(FtMsgType.NONE, FtMsgOp.NONE, ' ', null, 0, 0, 0, 0);
    }

    public FtMemberMsg(FtMemberMsg other) {
        this(other._type, other._op, other._fromApp, other._groupName, other._instance, other._activeGoal, other._stripeNo, other._ofStripes);
    }

    public FtMemberMsg(FtMsgType type, FtMsgOp op, char fromApp, String groupName, int instance, int activeGoal, int stripeNo, int ofStripes) {
        super(type, op, fromApp, groupName);
        _instance = instance;
        _activeGoal = activeGoal;
        _stripeNo = stripeNo;
        _ofStripes = ofStripes;
    }

    @Override
    public FtMemberMsg clone() {
        return new FtMemberMsg(this);
    }

    @Override
    public int getMsgType() {
        return FT_MEMBER;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        super.encode(buffer);
        buffer.putInt(_instance);
        buffer.putInt(_activeGoal);
        buffer.putInt(_stripeNo);
        buffer.putInt(_ofStripes);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        super.decode(buffer, len);
        _instance = buffer.getInt();
        _activeGoal = buffer.getInt();
        _stripeNo = buffer.getInt();
        _ofStripes = buffer.getInt();
        return this;
    }

    public void set(FtMsgType type, FtMsgOp op, char fromApp, int stripeNo, int ofStripes) {
        super.set(type, op, fromApp);
        _stripeNo = stripeNo;
        _ofStripes = ofStripes;
    }

    @Override
    public void reset() {
        super.reset();
        _instance = 0;
        _stripeNo = 0;
        _ofStripes = 0;
        _activeGoal = 0;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = super.hashCode();
        result = prime * result + _activeGoal;
        result = prime * result + _instance;
        result = prime * result + _stripeNo;
        result = prime * result + _ofStripes;
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (!super.equals(obj))
            return false;
        if (getClass() != obj.getClass())
            return false;
        FtMemberMsg other = (FtMemberMsg) obj;
        if (_activeGoal != other._activeGoal)
            return false;
        if (_instance != other._instance)
            return false;
        if (_stripeNo != other._stripeNo)
            return false;
        if (_ofStripes != other._ofStripes)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "FtMember["+super.toString()+"-"+_instance+"]";
    }
}
