package net.a_cappella.continuo.msg;

import static net.a_cappella.continuo.PrestoConstants.TEST_MSG;

public class TestMsg extends Msg {
    private long _timeNanos;

    public TestMsg() {}

    @Override
    public int getMsgType() {
        return TEST_MSG;
    }

    @Override
    public void reset() {
        _timeNanos = 0;
    }

    @Override
    public String toString() {
        return "{"+_timeNanos+":"+getNumUsers()+":"+isPooled()+"}";
    }

    public void setTimeNanos(long timeNanos) {
        _timeNanos = timeNanos;
    }
    public long getTimeNanos() {
        return _timeNanos;
    }

}
