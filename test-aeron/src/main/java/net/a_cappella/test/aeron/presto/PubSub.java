package net.a_cappella.test.aeron.presto;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PubSub extends PubSubBase {
    private static final Logger log = LoggerFactory.getLogger(PubSub.class);

    public PubSub(PrestoClient client, String channelType, String mediaDriverType) {
    	super(client, channelType, mediaDriverType);
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_statsLogger.dataPointHeader(configHeader() + _statsTestsParams.header());
    	_statsTestsParams.initTestParams();

		new Thread(() -> {
			try {
				runAllTests();
			} catch (Exception x) {
				log.error("", x);
			}
		}).start();
    }

	Object _lock = new Object();
	boolean _received = false;

	ISubscriptionListener _subscriptionListener = (obj, subsId) -> {
		try {
			obj.startUsing();

			recordLatency(obj);
			logObj(obj);

			synchronized (_lock) {
    			_lock.notify();
    			_received = true;
			}

		} catch (Exception x) {
			log.error("", x);
		} finally {
			obj.stopUsing();
		}
	};

	private void runAllTests() throws Exception {
    	do {
	    	_subsId = _client.subscribe(getSql(), _subscriptionListener);
	
	        _msg = getObj();
			_h.reset();
	
	        System.gc();
	
	        if (WUP_SIZE>0) {
	        	Thread.sleep(BEFORE_WARMUP_WAIT_MILLIS);
	            log.info("starting warmup...");
	        }
	
	        for (_i = -WUP_SIZE; _i<TST_SIZE; _i++) {
		        if (_i == 0) {
		        	if (WUP_SIZE>0) {
						log.info("done warming up!");
		        	}
		        	Thread.sleep(BEFORE_TEST_WAIT_MILLIS);
		            log.info("starting test...");
		    	}
	        	
		        boolean selectable = prepareNextMsg();
		        try {
					_client.publish(_msg);
				} catch (Exception e) {
					log.error("", e);
				}

		        if (selectable) {
			        synchronized (_lock) {
				        while(!_received) _lock.wait();
				        _received = false;
			        }
		        }
	        }
	
			_client.unsubscribe(_subsId);
	
			log.info("test ended!");
	    	_statsLogger.logResults(_h, currentConfigValues() + _statsTestsParams.currentTestParams());
	
	    	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_TEST, 10);
	    	ObjectManager.getInstance().verifyPoolSize(PrestoConstants.TYPE_PING, 10);
	
    	} while (_statsTestsParams.nextTestParams());

    	log.info("Done!");
    	if (_mediaDriver!=null) _mediaDriver.stop();
    	_client.stop();
    	if (_tightLoopThread!=null) _tightLoopThread.stop();
    	if (_mediaDriver!=null) _mediaDriver.stop();
    }

	private boolean prepareNextMsg() {
        int id = _i % ONE_IN_N;
        long startNanoTime = (_i>=0) ? System.nanoTime() : 0;
        setTestFields(id, startNanoTime);
        return (_selIn == SelectorIn.NO) ? true : id == 0;
	}
}
