package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.FtMsgType;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.FT_MEMBER;

public class FtMemberMsg extends FtMsg {

    public int _instance;
    public int _activeGoal;
    public int _sliceNo;
    public int _ofSlices;

    public FtMemberMsg() {
        this(FtMsgType.NONE, FtMsgOp.NONE, ' ', null, 0, 0, 0, 0);
    }

    public FtMemberMsg(FtMemberMsg other) {
        this(other._type, other._op, other._fromApp, other._groupName, other._instance, other._activeGoal, other._sliceNo, other._ofSlices);
    }

    public FtMemberMsg(FtMsgType type, FtMsgOp op, char fromApp, String groupName, int instance, int activeGoal, int sliceNo, int ofSlices) {
        super(type, op, fromApp, groupName);
        _instance = instance;
        _activeGoal = activeGoal;
        _sliceNo = sliceNo;
        _ofSlices = ofSlices;
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
        buffer.putInt(_sliceNo);
        buffer.putInt(_ofSlices);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        super.decode(buffer, len);
        _instance = buffer.getInt();
        _activeGoal = buffer.getInt();
        _sliceNo = buffer.getInt();
        _ofSlices = buffer.getInt();
        return this;
    }

    public void set(FtMsgType type, FtMsgOp op, char fromApp, int sliceNo, int ofSlices) {
        super.set(type, op, fromApp);
        _sliceNo = sliceNo;
        _ofSlices = ofSlices;
    }

    @Override
    public void reset() {
        super.reset();
        _instance = 0;
        _sliceNo = 0;
        _ofSlices = 0;
        _activeGoal = 0;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = super.hashCode();
        result = prime * result + _activeGoal;
        result = prime * result + _instance;
        result = prime * result + _sliceNo;
        result = prime * result + _ofSlices;
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
        if (_sliceNo != other._sliceNo)
            return false;
        if (_ofSlices != other._ofSlices)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "FtMember["+super.toString()+"-"+_instance+"]";
    }
}
