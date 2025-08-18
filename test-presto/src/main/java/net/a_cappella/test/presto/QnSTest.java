package net.a_cappella.test.presto;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.ps.ISnSListener;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class QnSTest implements ISnSListener {
    private static final Logger log = LoggerFactory.getLogger(QnSTest.class);

    private Long _subsId1;
    private Long _subsId2;
    private final PrestoClient _client;

    public QnSTest(PrestoClient client) {
    	_client = client;
    }

    public void start() throws Exception {
		_client.waitUntilInitialized();

		_subsId1 = _client.snapSubscribe("select * from credentials", this);
    	_subsId2 = _client.snapSubscribe("select * from ecn.credentials where ecn=btec", this);
    }

	@Override // ISubscriptionListener
	public void onSubscriptionMessage(Obj obj, long subsId) {
		try {
			obj.startUsing();
			if (subsId==_subsId1) log.info("-------------- "+obj);
			else if (subsId==_subsId2) log.info("========== "+obj);
		} catch (Exception x) {
			log.error("", x);
		} finally {
			obj.stopUsing();
		}
	}

	@Override // ISnapCompleteListener
	public void onSnapComplete(long subId) {
		log.info("done snapping "+subId);
	}
}
