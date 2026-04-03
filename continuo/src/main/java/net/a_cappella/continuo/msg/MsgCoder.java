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

package net.a_cappella.continuo.msg;

import net.a_cappella.continuo.managed.ObjectManager;

import java.nio.ByteBuffer;
import java.util.List;

public class MsgCoder {
    public void decode(ByteBuffer buffer, List<Msg> msgs) {
        int msgCnt = 0;
        int offset = buffer.position();
        int length = buffer.limit() - offset;

        if (offset+4<length) { // do I have a full header (length field)?
            buffer.mark();
            int len = buffer.getInt(offset);
            offset += len;
            if (offset>length) {
                buffer.reset();
            } else {
                do {
                    msgCnt++; // one more full message
                    if (offset+4<length) { // do I have the next full header?
                        buffer.mark();
                        len = buffer.getInt(offset);
                        offset += len;
                    } else { // not a full header; will get this incomplete message next time
                        buffer.reset();
                        break;
                    }
                } while (offset<=length); // do I have the payload also?
            }
        }

        offset = buffer.position();
        length = buffer.limit() - offset;

        for (int i=0; i<msgCnt; i++) {
            int pos = buffer.position();
            int len = buffer.getInt();
            int msgType = buffer.getInt();
            Msg msg = ObjectManager.getInstance().acquire(msgType);
            if (msg == null) {
                buffer.position(pos + len); // skip; will have been reported by 'acquire'
            } else {
                msg = msg.decode(buffer, len - 8);
                msgs.add(msg);
            }
        }
    }

    public int encode(Msg[] msgs, ByteBuffer buffer) {
        int len = 0;
        int msgCnt = msgs.length;
        for (int i=0; i<msgCnt; i++) {
            len += encode(msgs[i], buffer);
        }
        return len;
    }

    public int encode(Msg msg, ByteBuffer buffer) {
        int start = buffer.position();
        buffer.putInt(0);
        buffer.putInt(msg.getMsgType());
        msg.encode(buffer);
        int len = buffer.position() - start;
        buffer.putInt(start, len);
        return len;
    }
}
