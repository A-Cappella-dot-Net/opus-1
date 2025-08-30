package net.a_cappella.test.aeron.presto;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.atomic.AtomicLong;

public class DropPing {
    private static final Logger log = LoggerFactory.getLogger(DropPing.class);

    public static final boolean USE_MINE = true;

    private static final int TOLERANCE = 3;

    private final PrestoClient _client;

    public DropPing(PrestoClient client) {
    	_client = client;
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	log.info("starting threads");
    	new PubSubThread((short) 1).start();
    	new PubSubThread((short) 3).start();
    	new PubSubThread((short) 5).start();
    }



    private class PubSubThread extends Thread {
    	private final short _mine;
        private final PingObj _obj;
	    private long _lastSentId = 0;
        private final AtomicLong _lastReceivedId = new AtomicLong(0);

        public PubSubThread(short mine) throws Exception {
        	_mine = mine;
            String pingSql = "select * from ping where " + ((USE_MINE) ? "mine" : "id") + "=" + (mine + 1);
        	log.info("subscribing to " + pingSql);
        	_client.subscribe(pingSql, (obj, subsId) -> {
        		obj.startUsing();
                handlePongMsg(obj);
        		obj.stopUsing();
        	});

        	_obj = new PingObj();
            _obj.setMine(_mine);
            _obj.setTsNanos(System.nanoTime());
        }

        public void run() {
			while (true) {
				long lastReceivedId = _lastReceivedId.get();
				if (_lastSentId >= lastReceivedId + TOLERANCE) {
		    		log.error("{} Trying to send {} before {} has been received", _mine, _lastSentId + 1, lastReceivedId + 1);
		    		try {Thread.sleep(500);} catch (InterruptedException x) {}
		    		System.exit(1);
				}

    			long numberOfMessages = 1 + Math.round(0.49 + Math.random() * 2);
    			for (int i=0; i<numberOfMessages; i++) {
        			try {
        		    	_obj.setPayload(++_lastSentId);
        		    	_client.publish(_obj);
        			} catch (Exception e) {
    					log.error("", e);
    				}
    			}

    			long intervalBetweenMessages = 1000 + Math.round(0.49 + Math.random() * 200);
	    		try {Thread.sleep(intervalBetweenMessages);} catch (InterruptedException x) {}
			}
    	}

        private void handlePongMsg(Obj obj) {
        	PingObj pingObj = (PingObj) obj;
        	long receivedId = pingObj.getPayload();
        	long expectedReceivedId = receivedId - 1;
        	if (!_lastReceivedId.compareAndSet(expectedReceivedId, receivedId)) {
        		log.error("{} Received {} when expecting {}", _mine, receivedId, expectedReceivedId);
        		try {Thread.sleep(500);} catch (InterruptedException x) {}
        		System.exit(1);
        	}
    	}
    }
}
