package net.a_cappella.cembalo.timer;

import java.util.List;

import net.a_cappella.cembalo.message.TimerMsgs;

public class ListScheduleEntry extends ScheduleEntry {
    private final List<TimerAction> _actions;

    public ListScheduleEntry(String time, List<TimerAction> actions) {
        super(time);
        _actions = actions;
    }

    public void getEventTimes(List<TimeAndMessages> timeAndMessageList) {
        TimerMsgs msgs = new TimerMsgs();
        timeAndMessageList.add(new TimeAndMessages(_time, msgs));
        for (int i=0; i<_actions.size(); i++) {
            TimerAction ta = _actions.get(i);
            msgs.add(ta._book, ta._operation);
        }
    }

    public String toString() {
        return _time+" "+_actions;
    }
}
