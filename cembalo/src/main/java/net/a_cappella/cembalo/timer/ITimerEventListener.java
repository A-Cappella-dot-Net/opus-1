package net.a_cappella.cembalo.timer;

import net.a_cappella.cembalo.message.TimerMsgs;

public interface ITimerEventListener {
    void onTimerEvent(TimerMsgs msgs);
}
