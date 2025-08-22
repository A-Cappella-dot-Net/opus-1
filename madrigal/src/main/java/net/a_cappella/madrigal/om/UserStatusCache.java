package net.a_cappella.madrigal.om;

import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class UserStatusCache {
    private static final Logger log = LoggerFactory.getLogger(UserStatusCache.class);

    private final Map<String, UserStatus> _byEcnUid = new HashMap<>(); // (ecnUid, status)
	private final Map<String, UserStatus> _byOrdId = new HashMap<>(); // (ordId, status)

	public boolean isLoggedIn(OrderObj order) {
		String ordId = order.getOrdId();
		int ultPos = ordId.indexOf("~");
		if (ultPos > 0) ordId = ordId.substring(0, ultPos);

		UserStatus status = _byOrdId.get(ordId);
		if (status != null) {
			if (log.isDebugEnabled()) log.info("loggedIn "+ordId+" => "+status);
			return status._loggedIn;
		}

		String ecnUid = order.getEcnUid(); // order has ecnUid already populated

		status = _byEcnUid.get(ecnUid);
		if (status == null) {
			status = new UserStatus();
			status._uid = order.getUid();
			_byEcnUid.put(ecnUid, status);
		}
		status._ecnUid = ecnUid;
		_byOrdId.put(ordId, status);
		if (log.isDebugEnabled()) log.info("loggedIn "+ordId+" =>>> "+status);

		return status._loggedIn;
	}

	public void populateUids(OrderObj order) {
		String ordId = order.getOrdId();
		int ultPos = ordId.indexOf("~");
		if (ultPos > 0) ordId = ordId.substring(0, ultPos);

		UserStatus status = _byOrdId.get(ordId);
		if (status == null) {
			log.error("populateUids did not find UserStatus for {}", order);
		} else {
			if (log.isDebugEnabled()) log.info("populateUids {} => {}", status, ordId);
			order.setUid(status._uid);
			order.setEcnUid(status._ecnUid);
		}
	}

	public void onUserStatusUpdate(EcnUserStatusObj ecnUserStatusObj) {
		log.info("onUserStatusUpdate {}", ecnUserStatusObj);
		String ecnUid = ecnUserStatusObj.getEcnUid();
		UserStatus status = _byEcnUid.get(ecnUid);
		if (status == null) {
			status = new UserStatus();
			status._uid = ecnUserStatusObj.getUid();
			status._ecnUid = ecnUserStatusObj.getEcnUid();
			_byEcnUid.put(ecnUid, status);
		}
		status._loggedIn = ecnUserStatusObj.getStatus() == MadrigalUserStatus.On;
	}

	public void finalizeOrder(String ordId) {
		if (log.isDebugEnabled()) log.info("finalizeOrder {}", ordId);
		_byOrdId.remove(ordId);
	}


	public static class UserStatus {
		public String _uid;
		public String _ecnUid;
		public boolean _loggedIn;

		@Override
		public String toString() {
			return "{"+_uid+" "+_ecnUid+" "+_loggedIn+"}";
		}
	}
}
