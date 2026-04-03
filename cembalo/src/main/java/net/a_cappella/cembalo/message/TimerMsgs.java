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

package net.a_cappella.cembalo.message;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;
import net.a_cappella.continuo.msg.Msg;

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_TIMER_MSG;

public class TimerMsgs extends Msg {

    private final List<TimerMsg> _list = new ArrayList<>();

    public TimerMsgs() {}

    public TimerMsgs add(Book book, Operation type) {
        _list.add(new TimerMsg(book, type));
        return this;
    }

    @Override
    public int getMsgType() {
        return TYPE_TIMER_MSG;
    }

    public List<TimerMsg> getMsgs() {
        return _list;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        int size = _list.size();
        buffer.putInt(size);
        for (int i=0; i<size; i++) {
            TimerMsg msg = _list.get(i);
            buffer.putChar(Book.toFix(msg._book));
            buffer.putChar(Operation.toChar(msg._operation));
        }
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        int size = buffer.getInt();
        for (int i=0; i<size; i++) {
            TimerMsg msg = new TimerMsg(Book.fromFix(buffer.getChar()), Operation.fromChar(buffer.getChar()));
            _list.add(i, msg);
        }
        return this;
    }

    @Override
    public void reset() {
        _list.clear();
    }

    public String toString() {
        return _list.toString();
    }
}
