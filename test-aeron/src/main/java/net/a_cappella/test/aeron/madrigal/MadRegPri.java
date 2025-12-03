package net.a_cappella.test.aeron.madrigal;

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

public class MadRegPri extends MadMixBase {
    private static final Logger log = LoggerFactory.getLogger(MadRegPri.class);

    private static final int TST_SIZE = MadMix.TST_SIZE;
    private static final int MSGS_PER_SEC = 10;
    private static final int TESTING_DELAY_MILLIS = 1000 / MSGS_PER_SEC;
    private static final int MSG_SPACING_MICROS = 10;

    private final UserStatusObj _obj = new UserStatusObj();

    public MadRegPri(MadMix madMix, boolean dummyTest) {
    	super(madMix, "user.status", TimeUnit.MILLISECONDS.toNanos(200), dummyTest);
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

    private void updateObj(UserStatusObj obj, int tstCnt, long seqNo, int oneInN) {
        obj.setRequest("uid", "clId", 0, MadrigalLogOp.login, "pwd", false, false, System.currentTimeMillis());
        super.updateObj(obj, seqNo, oneInN);
    }
}
