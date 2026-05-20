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

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.msg.Msg;

import java.nio.ByteBuffer;
import java.util.Objects;

import static net.a_cappella.continuo.PrestoConstants.VOTE_MSG;

public class VoteMsg extends Msg {

    private AppInfo _ofMember;
    private AppInfo _forMember;

    public VoteMsg() {
        this(null, null);
    }

    public VoteMsg(AppInfo ofMember, AppInfo forMember) {
        _ofMember = ofMember;
        _forMember = forMember;
    }

    public VoteMsg(VoteMsg other) {
        _ofMember = new AppInfo(other._ofMember);
        _forMember = new AppInfo(other._forMember);
    }

    @Override
    public VoteMsg clone() {
        return new VoteMsg(this);
    }

    @Override
    public int getMsgType() {
        return VOTE_MSG;
    }

    public AppInfo ofMember() {
        return _ofMember;
    }

    public AppInfo forMember() {
        return _forMember;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        putString(buffer, _ofMember.getApp());
        buffer.putShort(_ofMember.getStripe());
        buffer.putShort(_ofMember.getInstance());

        putString(buffer, _forMember.getApp());
        buffer.putShort(_forMember.getStripe());
        buffer.putShort(_forMember.getInstance());
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        String app = getString(buffer);
        short stripe = buffer.getShort();
        short instance = buffer.getShort();
        _ofMember = new AppInfo(app, stripe, instance);

        app = getString(buffer);
        stripe = buffer.getShort();
        instance = buffer.getShort();
        _forMember = new AppInfo(app, stripe, instance);

        return this;
    }

    @Override
    public void reset() {
        _ofMember = null;
        _forMember = null;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null) return false;
        if (getClass() != obj.getClass()) return false;
        VoteMsg other = (VoteMsg) obj;

        if (_ofMember == null) {
            if (other._ofMember != null) return false;
        } else if (!_ofMember.equals(other._ofMember)) return false;

        if (_forMember == null) {
            if (other._forMember != null) return false;
        } else if (!_forMember.equals(other._forMember)) return false;

        return true;
    }

    @Override
    public int hashCode() {
        return Objects.hash(_ofMember, _forMember);
    }

    @Override
    public String toString() {
        return "{" + _ofMember + " voted for " + _forMember + "}";
    }
}
