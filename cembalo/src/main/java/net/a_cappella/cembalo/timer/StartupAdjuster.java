package net.a_cappella.cembalo.timer;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import net.a_cappella.cembalo.constants.Operation;
import net.a_cappella.cembalo.message.TimerMsgs;
import net.a_cappella.cembalo.message.TimerMsg;

public class StartupAdjuster {
    private final List<TimerMsg> _startMsgs = new ArrayList<>();

    public TimeAndMessages getAdjustments(long timeOfLastEvent) {
        if (_startMsgs.isEmpty()) {
            return null;
        }
        TimerMsgs msgs = new TimerMsgs();
        for (TimerMsg msg : _startMsgs) {
            msgs.add(msg._book, msg._operation);
        }
        _startMsgs.clear();
        return new TimeAndMessages(timeOfLastEvent, msgs);
    }

    public void accumulateAdjustments(TimeAndMessages timeAndMessages) {
        List<TimerMsg> msgs = timeAndMessages._msgs.getMsgs();
        for (int i=0; i<msgs.size(); i++) {
            TimerMsg msg = msgs.get(i);
            if (msg._operation == Operation.CLOSE) {
                Iterator<TimerMsg> iterator = _startMsgs.iterator();
                while (iterator.hasNext()) {
                    TimerMsg msg2 = iterator.next();
                    if (msg._book == msg2._book) {
                        iterator.remove();
                    }
                }
            } else if (msg._operation != Operation.IMBALANCE) {
                _startMsgs.add(msg);
            }
        }
    }
}
