package net.a_cappella.cembalo.timer;

import static net.a_cappella.cembalo.constants.Book.CLOSE_BK;
import static net.a_cappella.cembalo.constants.Book.CONTINUOUS_BK;
import static net.a_cappella.cembalo.constants.Book.OPEN_BK;
import static net.a_cappella.cembalo.constants.Operation.ALL;
import static net.a_cappella.cembalo.constants.Operation.AUCTION;
import static net.a_cappella.cembalo.constants.Operation.CLOSE;
import static net.a_cappella.cembalo.constants.Operation.IMBALANCE;
import static net.a_cappella.cembalo.constants.Operation.MATCHING;
import static net.a_cappella.cembalo.constants.Operation.NON_MATCHING;
import static net.a_cappella.cembalo.constants.Operation.ONLY_NEW;
import static net.a_cappella.cembalo.constants.Operation.OPEN;
//import static org.junit.Assert.assertEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.message.TimerMsgs;

public class InternalTimerTest {
    private static final Logger log = LoggerFactory.getLogger(InternalTimerTest.class);

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        log.info("--------------------------------------------- "+testInfo.getDisplayName());
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        log.info("============================================= "+testInfo.getDisplayName());
    }

    @Test
    public void translationAndDelayedStartupTest() {
        List<TimeAndMessages> actualTimesAndMessages = InternalTimer.getEventTimes(6,
                Arrays.asList(new ScheduleEntry[] {
                        new ListScheduleEntry("5", Arrays.asList(
                                new TimerAction(OPEN_BK, OPEN),
                                new TimerAction(OPEN_BK, ALL),
                                new TimerAction(CLOSE_BK, OPEN),
                                new TimerAction(CLOSE_BK, ALL),
                                new TimerAction(CONTINUOUS_BK, OPEN),
                                new TimerAction(CONTINUOUS_BK, NON_MATCHING)
                        )),
                        new RepeatScheduleEntry("10", 1,
                                new RepeatTimerAction(OPEN_BK, IMBALANCE, 3),
                                new SlotTimerAction(OPEN_BK, ONLY_NEW, 2)
                        ),
                        new ListScheduleEntry("10", Arrays.asList(
                                new TimerAction(OPEN_BK, AUCTION),
                                new TimerAction(OPEN_BK, CLOSE),
                                new TimerAction(CONTINUOUS_BK, MATCHING)
                        )),
                        new RepeatScheduleEntry("15", 1,
                                new RepeatTimerAction(Book.CLOSE_BK, IMBALANCE, 3),
                                new SlotTimerAction(CLOSE_BK, ONLY_NEW, 1)
                        ),
                        new ListScheduleEntry("15", Arrays.asList(
                                new TimerAction(CONTINUOUS_BK, CLOSE),
                                new TimerAction(CLOSE_BK, AUCTION),
                                new TimerAction(CLOSE_BK, CLOSE)
                        ))
                })
        );
        log.info(""+actualTimesAndMessages);
        List<TimeAndMessages> expectedTimesAndMessages = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(11, new TimerMsgs().add(OPEN_BK, OPEN).add(OPEN_BK, ALL).add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING)),
                new TimeAndMessages(13, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(14, new TimerMsgs().add(OPEN_BK, IMBALANCE).add(OPEN_BK, ONLY_NEW)),
                new TimeAndMessages(15, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(16, new TimerMsgs().add(OPEN_BK, AUCTION).add(OPEN_BK, CLOSE).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages.toString(), actualTimesAndMessages.toString());

        List<TimeAndMessages> actualTimesAndMessages1 = start(12, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages1);
        List<TimeAndMessages> expectedTimesAndMessages1 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(12, new TimerMsgs().add(OPEN_BK, OPEN).add(OPEN_BK, ALL).add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING)),
                new TimeAndMessages(13, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(14, new TimerMsgs().add(OPEN_BK, IMBALANCE).add(OPEN_BK, ONLY_NEW)),
                new TimeAndMessages(15, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(16, new TimerMsgs().add(OPEN_BK, AUCTION).add(OPEN_BK, CLOSE).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages1.toString(), actualTimesAndMessages1.toString());

        List<TimeAndMessages> actualTimesAndMessages2 = start(13, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages2);
        List<TimeAndMessages> expectedTimesAndMessages2 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(13, new TimerMsgs().add(OPEN_BK, OPEN).add(OPEN_BK, ALL).add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING)),
                new TimeAndMessages(14, new TimerMsgs().add(OPEN_BK, IMBALANCE).add(OPEN_BK, ONLY_NEW)),
                new TimeAndMessages(15, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(16, new TimerMsgs().add(OPEN_BK, AUCTION).add(OPEN_BK, CLOSE).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages2.toString(), actualTimesAndMessages2.toString());

        List<TimeAndMessages> actualTimesAndMessages3 = start(14, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages3);
        List<TimeAndMessages> expectedTimesAndMessages3 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(14, new TimerMsgs().add(OPEN_BK, OPEN).add(OPEN_BK, ALL).add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(OPEN_BK, ONLY_NEW)),
                new TimeAndMessages(15, new TimerMsgs().add(OPEN_BK, IMBALANCE)),
                new TimeAndMessages(16, new TimerMsgs().add(OPEN_BK, AUCTION).add(OPEN_BK, CLOSE).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages3.toString(), actualTimesAndMessages3.toString());

        List<TimeAndMessages> actualTimesAndMessages4 = start(15, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages4);
        List<TimeAndMessages> expectedTimesAndMessages4 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(15, new TimerMsgs().add(OPEN_BK, OPEN).add(OPEN_BK, ALL).add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(OPEN_BK, ONLY_NEW)),
                new TimeAndMessages(16, new TimerMsgs().add(OPEN_BK, AUCTION).add(OPEN_BK, CLOSE).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages4.toString(), actualTimesAndMessages4.toString());

        List<TimeAndMessages> actualTimesAndMessages5 = start(16, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages5);
        List<TimeAndMessages> expectedTimesAndMessages5 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(16, new TimerMsgs().add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages5.toString(), actualTimesAndMessages5.toString());

        List<TimeAndMessages> actualTimesAndMessages6 = start(17, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages6);
        List<TimeAndMessages> expectedTimesAndMessages6 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(17, new TimerMsgs().add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages6.toString(), actualTimesAndMessages6.toString());

        List<TimeAndMessages> actualTimesAndMessages7 = start(18, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages7);
        List<TimeAndMessages> expectedTimesAndMessages7 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(18, new TimerMsgs().add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, IMBALANCE)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages7.toString(), actualTimesAndMessages7.toString());

        List<TimeAndMessages> actualTimesAndMessages8 = start(19, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages8);
        List<TimeAndMessages> expectedTimesAndMessages8 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(19, new TimerMsgs().add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(CONTINUOUS_BK, MATCHING)),
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, IMBALANCE).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages8.toString(), actualTimesAndMessages8.toString());

        List<TimeAndMessages> actualTimesAndMessages9 = start(20, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages9);
        List<TimeAndMessages> expectedTimesAndMessages9 = Arrays.asList(new TimeAndMessages[] {
                new TimeAndMessages(20, new TimerMsgs().add(CLOSE_BK, OPEN).add(CLOSE_BK, ALL).add(CONTINUOUS_BK, OPEN).add(CONTINUOUS_BK, NON_MATCHING).add(CONTINUOUS_BK, MATCHING).add(CLOSE_BK, ONLY_NEW)),
                new TimeAndMessages(21, new TimerMsgs().add(CONTINUOUS_BK, CLOSE).add(CLOSE_BK, AUCTION).add(CLOSE_BK, CLOSE)),
        });
        assertEquals(expectedTimesAndMessages9.toString(), actualTimesAndMessages9.toString());

        List<TimeAndMessages> actualTimesAndMessages0 = start(21, actualTimesAndMessages);
        log.info(""+actualTimesAndMessages0);
        List<TimeAndMessages> expectedTimesAndMessages0 = Collections.emptyList();
        assertEquals(expectedTimesAndMessages0.toString(), actualTimesAndMessages0.toString());
    }





    private List<TimeAndMessages> start(long startAt, List<TimeAndMessages> timesAndMessages) {
        List<TimeAndMessages> result = new ArrayList<>();
        StartupAdjuster startupAdjuster = new StartupAdjuster();
        for (int i=0; i<timesAndMessages.size(); i++) {
            TimeAndMessages timeAndMessages = timesAndMessages.get(i);
            if (timeAndMessages._timeOfEvent <= startAt) {
                startupAdjuster.accumulateAdjustments(timeAndMessages);
            } else {
                TimeAndMessages adjustments = startupAdjuster.getAdjustments(startAt);
                if (adjustments!=null) result.add(adjustments);
                result.add(timeAndMessages);
            }
        }
        return result;
    }
}
