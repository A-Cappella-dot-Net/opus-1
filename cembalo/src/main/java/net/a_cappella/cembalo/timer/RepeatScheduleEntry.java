package net.a_cappella.cembalo.timer;

import java.util.List;

import net.a_cappella.cembalo.message.TimerMsgs;

public class RepeatScheduleEntry extends ScheduleEntry {
    private final int _interval;
    private final RepeatTimerAction _repeatAction;
    private final SlotTimerAction _slotAction;

    public RepeatScheduleEntry(String time, int interval, RepeatTimerAction repeatAction, SlotTimerAction slotAction) {
        super(time);
        _interval = interval;
        _repeatAction = repeatAction;
        _slotAction = slotAction;
    }

    public void getEventTimes(List<TimeAndMessages> timeAndMessageList) {
        for (int i=_repeatAction._count; i>0; i--) {
            TimerMsgs msgs = new TimerMsgs();
            timeAndMessageList.add(new TimeAndMessages(_time-i*_interval, msgs));
            msgs.add(_repeatAction._book, _repeatAction._operation);
            if (i==_slotAction._slot) {
                msgs.add(_slotAction._book, _slotAction._operation);
            }
        }
    }

    public String toString() {
        return _time+" "+_interval+" "+_repeatAction+" "+_slotAction;
    }
}
