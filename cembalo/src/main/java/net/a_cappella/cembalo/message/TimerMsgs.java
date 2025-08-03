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
