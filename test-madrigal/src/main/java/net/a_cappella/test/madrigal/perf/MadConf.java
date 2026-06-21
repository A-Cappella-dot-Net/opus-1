/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.test.madrigal.perf;

import java.util.concurrent.TimeUnit;

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.presto.ps.PublicationHelper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MadConf extends MadMixBase {
    private static final Logger log = LoggerFactory.getLogger(MadConf.class);

    private static final int LOG_EVERY_N_RECORDS = 2_000_000;

    private static final int WUP_SIZE = MadMix.WUP_SIZE;
    private static final int TST_SIZE = MadMix.TST_SIZE;

    private final EcnPriceObj _obj = new EcnPriceObj();

    public MadConf(MadMix madMix, boolean dummyTest) {
    	super(madMix, "ecn.price", TimeUnit.MILLISECONDS.toNanos(200), dummyTest);
	}

    @SuppressWarnings("unused")
    @Override
	public void runTest(MadMix.TestParams params) throws Exception {

        log.info("starting "+((WUP_SIZE <= 0)?"test":"warmup")+"...");
        _madMix.setTestingPhase((WUP_SIZE <= 0)? MadMix.TestingPhase.TESTING: MadMix.TestingPhase.WARMUP);

    	int burstCnt = params.getBurstCnt();
    	int lullCnt = 0;

    	for (int j=-WUP_SIZE; j<TST_SIZE; j++) {
            if (j==0) {
	            log.info("done warming up!");
                _madMix.setTestingPhase(MadMix.TestingPhase.BREAK);
    	        System.gc();
	            Thread.sleep(2000);
	        	burstCnt = params.getBurstCnt();
	        	lullCnt = 0;
	            log.info("starting test...");
                _madMix.setTestingPhase(MadMix.TestingPhase.TESTING);
            }

            updateObj(_obj, TST_SIZE, j, params.getOneInN());
            if (TST_SIZE<=10 || (j%LOG_EVERY_N_RECORDS==0 && j!=0)) log.info(">>> "+_obj);

            int result = _madMix.publish(_obj);

        	if (!PublicationHelper.isPublished(result)) {
        		if (burstCnt > 0) {
        			burstCnt--;
        		} else { // burstCnt == 0
        			if (lullCnt == 0) {
            			lullCnt = params.getLullCnt();
            			log.info("Switching to LULL mode in " + lullCnt + " " + j);
        			} else {
        				// lullCnt > 0 => continue lull until no more bp
        			}
        		}
        	} else { // published
        		if (burstCnt > 0) {
        			// continue burst until !published
        		} else { // burstCnt == 0
        			if (lullCnt > 0) {
        				lullCnt--;
        			} else { // lullCnt == 0 => start burst again
        				burstCnt = params.getBurstCnt();
            			log.info("Switching to BURST mode in " + burstCnt + " " + j);
        			}
        		}
        	}

            if (lullCnt > 0) {
            	Utils.sleepMillisDelay(params.getSleepMillis());
        	}
        	Utils.busyMicrosDelay(params.getBusyMicros());
        }

		log.info("test ended!");

        _madMix.setTestingPhase(MadMix.TestingPhase.DONE);
    }

    private void updateObj(EcnPriceObj obj, int tstCnt, long seqNo, int oneInN) {
    	obj.setInstrId("INST1");
    	obj.setEcn("ECN1");

    	obj.setBidSize4(10.0);
    	obj.setBid4(105.0);
    	obj.setBidSize3(10.0);
    	obj.setBid3(106.0);
    	obj.setBidSize2(10.0);
    	obj.setBid2(107.0);
    	obj.setBidSize1(10.0);
    	obj.setBid1(108.0);
    	obj.setBidSize0(10.0);
    	obj.setBid0(109.0);

    	obj.setOffer0(110.0);
    	obj.setOfferSize0(10.0);
    	obj.setOffer1(111.0);
    	obj.setOfferSize1(10.0);
    	obj.setOffer2(112.0);
    	obj.setOfferSize2(10.0);
    	obj.setOffer3(113.0);
    	obj.setOfferSize3(10.0);
    	obj.setOffer4(114.0);
    	obj.setOfferSize4(10.0);

    	long timeMillis = System.currentTimeMillis();
        obj.setTs(timeMillis);
        obj.setTsx(timeMillis);

        super.updateObj(obj, seqNo, oneInN);
    }


    private static final int W_DURATION_SECONDS = 10_000;
    private static final int T_DURATION_SECONDS = 15_000;

    @Override
    protected void runDummyTest(MadMix.TestParams params) throws Exception {
        log.info("starting warmup...");
        _madMix.setTestingPhase(MadMix.TestingPhase.WARMUP);
        Thread.sleep(W_DURATION_SECONDS);
        log.info("done warming up!");
        _madMix.setTestingPhase(MadMix.TestingPhase.BREAK);
        System.gc();
        Thread.sleep(2000);
        log.info("starting test...");
        _madMix.setTestingPhase(MadMix.TestingPhase.TESTING);
        Thread.sleep(T_DURATION_SECONDS);
        log.info("test ended!");
        _madMix.setTestingPhase(MadMix.TestingPhase.DONE);
	}
}
