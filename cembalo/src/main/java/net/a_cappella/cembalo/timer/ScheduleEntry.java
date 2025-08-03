package net.a_cappella.cembalo.timer;

import java.time.LocalTime;
import java.util.List;

public abstract class ScheduleEntry {
    protected long _time;
    private boolean _relative;

    public ScheduleEntry(String time) {
        try {
            _time = Integer.parseInt(time);
            _relative = true;
        } catch (NumberFormatException x) {
            _time = LocalTime.parse(time).toSecondOfDay();
        }
    }

    public void getEventTimes(long nowSeconds, List<TimeAndMessages> timeAndMessageList) {
        if (_relative) _time += nowSeconds;
        getEventTimes(timeAndMessageList);
    }

    public abstract void getEventTimes(List<TimeAndMessages> timeAndMessageList);

}
