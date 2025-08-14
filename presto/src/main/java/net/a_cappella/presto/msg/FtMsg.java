package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.FtMsgType;

import java.nio.ByteBuffer;

public class FtMsg extends Msg {
    public FtMsgType _type; // {REQUEST, RESPONSE}
    public FtMsgOp _op; // {REGISTER, UNREGISTER}
    public char _fromApp; // {YES, NO}
    public String _groupName;

    public FtMsg() {
        this(FtMsgType.NONE, FtMsgOp.NONE, ' ', null);
    }

    public FtMsg(FtMsg other) {
        this(other._type, other._op, other._fromApp, other._groupName);
    }

    public FtMsg(FtMsgType type, FtMsgOp op, char fromApp, String groupName) {
        set(type, op, fromApp);
        _groupName = groupName;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putChar(FtMsgType.toChar(_type));
        buffer.putChar(FtMsgOp.toChar(_op));
        buffer.putChar(_fromApp);
        putString(buffer, _groupName);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _type = FtMsgType.toEnum(buffer.getChar());
        _op = FtMsgOp.toEnum(buffer.getChar());
        _fromApp = buffer.getChar();
        _groupName = getString(buffer);
        return this;
    }

    public void set(FtMsgType type, FtMsgOp op, char fromApp) {
        _type = type;
        _op = op;
        _fromApp = fromApp;
    }

    @Override
    public void reset() {
        set(FtMsgType.NONE, FtMsgOp.NONE, ' ');
        _groupName = null;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof FtMsg)) {
            return false;
        }
        FtMsg other = (FtMsg) obj;
        return _type == other._type && _op == other._op && _fromApp == other._fromApp && _groupName.equals(other._groupName);
    }

    @Override
    public int hashCode() {
        return _groupName.hashCode() * 10191 + FtMsgType.toChar(_type) + FtMsgOp.toChar(_op) + _fromApp;
    }

    @Override
    public String toString() {
        return _type+" "+_op+" "+_fromApp+" "+_groupName;
    }
}
