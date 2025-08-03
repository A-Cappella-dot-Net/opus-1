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
