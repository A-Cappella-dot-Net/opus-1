package net.a_cappella.continuo.msg;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.FORCE_DISCONNECT;

public class ForceDisconnect extends Msg {

    public ForceDisconnect() {}

    @Override
    public int getMsgType() {
        return FORCE_DISCONNECT;
    }

    @Override
    public void encode(ByteBuffer buffer) {}

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        return this;
    }

    @Override
    public void reset() {}

    @Override
    public boolean equals(Object obj) {
        return obj instanceof ForceDisconnect;
    }

    @Override
    public int hashCode() {
        return 0;
    }

    @Override
    public String toString() {
        return "";
    }
}
