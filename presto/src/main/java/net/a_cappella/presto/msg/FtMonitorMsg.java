package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.FtMsgType;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.FT_MONITOR;
import static net.a_cappella.continuo.PrestoConstants.NO;
import static net.a_cappella.presto.ft.collective.CollectiveClient.NONE;

public class FtMonitorMsg extends FtMsg {
    public int _actives;

    public FtMonitorMsg() {
        this(null, FtMsgType.NONE, FtMsgOp.NONE, NO, NONE);
    }

    public FtMonitorMsg(FtMonitorMsg other) {
        this(other._groupName, other._type, other._op, other._fromApp, other._actives);
    }

    public FtMonitorMsg(String groupName, FtMsgType type, FtMsgOp op, char fromApp, int actives) {
        super(type, op, fromApp, groupName);
        _actives = actives;
    }

    @Override
    public int getMsgType() {
        return FT_MONITOR;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        super.encode(buffer);
        buffer.putInt(_actives);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        super.decode(buffer, len);
        _actives = buffer.getInt();
        return this;
    }

    @Override
    public void reset() {
        super.reset();
        _actives = 0;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = super.hashCode();
        result = prime * result + _actives;
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
        FtMonitorMsg other = (FtMonitorMsg) obj;
        if (_actives != other._actives)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "FtMonitor["+super.toString()+"|"+_actives+"]";
    }
}
