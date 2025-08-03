package net.a_cappella.cembalo.timer;

import net.a_cappella.cembalo.message.TimerMsgs;
import net.a_cappella.continuo.managed.Poolable;

public class TimeAndMessages extends Poolable {
    public long _timeOfEvent;
    public TimerMsgs _msgs;

    public TimeAndMessages(long timeOfEvent, TimerMsgs msgs) {
        _timeOfEvent = timeOfEvent;
        _msgs = msgs;
    }

    public String toString() {
        return "{"+_timeOfEvent+","+_msgs+"}";
    }

    @Override
    public void reset() {
        _timeOfEvent = 0;
        _msgs = null;
    }

}
