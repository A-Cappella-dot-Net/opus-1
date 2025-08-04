package net.a_cappella.cembalo.timer;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import net.a_cappella.continuo.utils.Delayer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.annotations.VisibleForTesting;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;

public class InternalTimer {
    private static final Logger log = LoggerFactory.getLogger(InternalTimer.class);

    private final long _nowFineTunedMillis;
    private final List<TimeAndMessages> _timesAndMessages;
    private ITimerEventListener _listener;

    private final Delayer<TimeAndMessages> _timeAndMessagesDelayer = new Delayer<>("TimeAndMessages",
            timeAndMessages -> {
                try {
                    fineTuneDelay(timeAndMessages._timeOfEvent);
                    _listener.onTimerEvent(timeAndMessages._msgs);
                } catch (Exception x) {
                    log.error("", x);
                }
            }, true);

    public InternalTimer(List<ScheduleEntry> schedule, String fineTuneMillis) {
        long nowSeconds = LocalTime.now().toSecondOfDay() + 1;
        int fineTuneMillisInt = 1;
        try {
            fineTuneMillisInt = Integer.parseInt(fineTuneMillis);
        } catch (NumberFormatException x) {
            // defaulting to 1
        }
        _nowFineTunedMillis = nowSeconds * 1_000 - fineTuneMillisInt;

        _timesAndMessages = getEventTimes(nowSeconds, schedule);
    }

    public void setListener(ITimerEventListener listener) {
        _listener = listener;
    }

    @VisibleForTesting
    public List<TimeAndMessages> getTimesAndMessages() {
        return _timesAndMessages;
    }

    public void start() {
        _timeAndMessagesDelayer.start();

        StartupAdjuster startupAdjuster = new StartupAdjuster();
        for (TimeAndMessages timeAndMessages : _timesAndMessages) {
            long timeOfEventMillis = timeAndMessages._timeOfEvent * 1000;
            if (_nowFineTunedMillis >= timeOfEventMillis) {
                startupAdjuster.accumulateAdjustments(timeAndMessages);
            } else {
                TimeAndMessages adjustments = startupAdjuster.getAdjustments(timeAndMessages._timeOfEvent);
                if (adjustments!=null) {
                    _timeAndMessagesDelayer.add(0, adjustments);
                }
                long delayMillis = timeOfEventMillis - _nowFineTunedMillis;
                _timeAndMessagesDelayer.add(delayMillis, timeAndMessages);
            }
        }
    }

    @VisibleForTesting
    public static List<TimeAndMessages> getEventTimes(long nowSeconds, List<ScheduleEntry> schedules) {
        log.info("schedules="+schedules);
        List<TimeAndMessages> eventTimes = new ArrayList<>();
        for (ScheduleEntry schedule : schedules) {
            schedule.getEventTimes(nowSeconds, eventTimes);
        }
        log.info("eventTimes="+eventTimes);
        return eventTimes;
    }

    private void fineTuneDelay(long expectedTimeSeconds) {
        long expectedTimeNanos = expectedTimeSeconds * 1_000_000_000;
        long nowNanos = LocalTime.now().toNanoOfDay();
        while (nowNanos < expectedTimeNanos) {
            nowNanos = LocalTime.now().toNanoOfDay();
        }
    }



    public static void main(String[] args) {
        InternalTimer it = new InternalTimer(
                Arrays.asList(new ListScheduleEntry[] {
                        new ListScheduleEntry("-10", Arrays.asList(
                                new TimerAction(Book.OPEN_BK, Operation.OPEN),
                                new TimerAction(Book.CLOSE_BK, Operation.OPEN)
                        )),
                        new ListScheduleEntry("-5", Arrays.asList(
                                new TimerAction(Book.OPEN_BK, Operation.CLOSE),
                                new TimerAction(Book.CONTINUOUS_BK, Operation.OPEN)
                        )),
                        new ListScheduleEntry("15", Arrays.asList(
                                new TimerAction(Book.CONTINUOUS_BK, Operation.CLOSE),
                                new TimerAction(Book.CLOSE_BK, Operation.CLOSE)
                        ))
                }),
                "20");
        it.setListener((msg) -> {
            System.out.println((LocalTime.now().toNanoOfDay() / 1_000_000)+" "+msg);
        });
        System.out.println(it._timesAndMessages);
        it.start();
    }
}
