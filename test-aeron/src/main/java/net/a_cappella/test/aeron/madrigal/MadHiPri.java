package net.a_cappella.test.aeron.madrigal;

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

public class MadHiPri extends MadMixBase {
    private static final Logger log = LoggerFactory.getLogger(MadHiPri.class);

    private static final int TST_SIZE = MadMix.TST_SIZE;
    private static final int MSGS_PER_SEC = 100;
    private static final int TESTING_DELAY_MILLIS = 1000 / MSGS_PER_SEC;
    private static final int MSG_SPACING_MICROS = 10;

    private final OrderObj _obj = new OrderObj();

    public MadHiPri(MadMix madMix, boolean dummyTest) {
    	super(madMix, "order", TimeUnit.MILLISECONDS.toNanos(200), dummyTest);
	}

    @SuppressWarnings("unused")
	@Override
	public void runTest(MadMix.TestParams params) throws Exception {
    	long seqNo = -1;
    	long warmupCnt = 0;
    	long testCnt = 0;

    	while (_madMix.getTestingPhase() != MadMix.TestingPhase.DONE) {
            switch (_madMix.getTestingPhase()) {
            case DONE:
            case STARTING:
            case BREAK:
        		Utils.busyMicrosDelay(MSG_SPACING_MICROS);
            	continue;
            case WARMUP:
        		Utils.busyMicrosDelay(MSG_SPACING_MICROS);
        		warmupCnt--;
        		seqNo = warmupCnt;
        		break;
            case TESTING:
        		Utils.sleepMillisDelay(TESTING_DELAY_MILLIS);
        		testCnt++;
        		seqNo = testCnt;
        		break;
            }

    		updateObj(_obj, 0, seqNo, params.getOneInN());
    		if (TST_SIZE<=10) log.info(">>> "+_obj);
            _madMix.publish(_obj);
    	}

    	log.info("Completed " + -warmupCnt + "/" + testCnt);
    }

    private void updateObj(OrderObj obj, int tstCnt, long seqNo, int oneInN) {
        obj.setAddRequest("ecn", "uid", "ordId", 0, "clOrdId", "instrId", MadrigalOrdType.LIMIT, MadrigalTimeInForce.DAY, MadrigalSide.Buy, 100.0, 10.0, 1.0, 0);
        super.updateObj(obj, seqNo, oneInN);
    }
}
