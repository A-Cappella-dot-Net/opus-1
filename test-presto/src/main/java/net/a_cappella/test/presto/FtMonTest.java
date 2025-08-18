package net.a_cappella.test.presto;

import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.ft.collective.IFtMonitorListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FtMonTest implements IFtMonitorListener {
    private static final Logger log = LoggerFactory.getLogger(FtMonTest.class);

    private static final int NUM_ITERATIONS = 1;
    private static final int CYCLE_INTERVAL = 1000;
    private static final int OP_INTERVAL = 1000;

    private final CollectiveClient _client;

    public FtMonTest(CollectiveClient client) {
    	_client = client;
    }

    public void start() {
    	try {
            _client.registerFtMonitorListener(this);
			Thread.sleep(2000);

			for (int i=0; i<NUM_ITERATIONS; i++) {
				_client.registerFtMonitor("foo");

				if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);

//				client.unregisterFtMonitor("foo");
				Thread.sleep(CYCLE_INTERVAL);
			}

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

	@Override // IFtMonitorListener
	public void onActivesChanged(String groupName, int actives) {
		log.info("onActivesChanged("+groupName+" "+actives+")");
	}
}
