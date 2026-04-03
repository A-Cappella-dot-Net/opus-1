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

package net.a_cappella.test.aeron.presto;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

public class PubSubUnfolded extends PubSubBase {
    private static final Logger log = LoggerFactory.getLogger(PubSubUnfolded.class);

	private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(PubSubUnfolded.class.getSimpleName() + "-%d").setDaemon(true).build();
	private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);

    public PubSubUnfolded(PrestoClient client, String channelType, String mediaDriverType) {
    	super(client, channelType, mediaDriverType);
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_statsLogger.logHeader(configHeader() + _statsTestsParams.header());
    	_statsTestsParams.initTestParams();

        startNextTest();
    }

	ISubscriptionListener _subscriptionListener = (obj, subsId) -> {
		try {
			obj.startUsing();
			handlePingMsg(obj);
		} catch (Exception x) {
			log.error("", x);
		} finally {
			obj.stopUsing();
		}
	};

	private void startNextTest() {
    	try {
	    	_subsId = _client.subscribe(getSql(), _subscriptionListener);

	        _msg = getObj();

			_h.reset();

	        System.gc();
			_scheduler.schedule(
					() -> {
				    	_i = - WUP_SIZE;
				        if (_i == 0) {
				            log.info("starting test...");
				    	} else {
				            log.info("starting warmup...");
				    	}

				        boolean selectable;
				        do {
					        selectable = prepareNextMsg();
					        try {
								_client.publish(_msg);
							} catch (Exception e) {
								log.error("", e);
							}
				        } while (!selectable);
					},
					BEFORE_WARMUP_WAIT_MILLIS, TimeUnit.MILLISECONDS);

    	} catch (Exception x) {
    		log.error("", x);
    	}
    }

    private void handlePingMsg(Obj obj) throws Exception {
		recordLatency(obj);

		logObj(obj);

		while (_i<TST_SIZE) {
			if (_i==0) {
				log.info("done warming up!");
				_scheduler.schedule(
						() -> {
				            log.info("starting test...");
							prepareNextMsg();
				            try {
								_client.publish(_msg);
							} catch (Exception e) {
								log.error("", e);
							}
						},
						BEFORE_TEST_WAIT_MILLIS, TimeUnit.MILLISECONDS);
				return;
			}
			boolean selectable = prepareNextMsg();
            _client.publish(_msg);
            if (selectable) return;
		}

		_client.unsubscribe(_subsId);

		log.info("test ended!");
    	_statsLogger.logRow(_h, currentConfigValues() + _statsTestsParams.currentTestParams());

    	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_TEST, 10);
    	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_PING, 10);

    	if (_statsTestsParams.nextTestParams()) {
    		startNextTest();
    	} else {
    		log.info("Done!");

    		new Thread(() -> {
	    		if (_mediaDriver!=null) _mediaDriver.stop();
	        	_client.stop();
	        	if (_tightLoopThread!=null) _tightLoopThread.stop();
	        	if (_mediaDriver!=null) _mediaDriver.stop();
    		}).start();
    	}
	}

	private boolean prepareNextMsg() {
        int id = _i % ONE_IN_N;
        long startNanoTime = (_i>=0) ? System.nanoTime() : 0;
        setTestFields(id, startNanoTime);
        _i++;
        return (_selIn == SelectorIn.NO) ? true : id == 0;
	}
}
