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

package net.a_cappella.madrigal.user;

import com.google.common.annotations.VisibleForTesting;
import net.a_cappella.continuo.utils.Delayer;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMarketStatus;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.MarketStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.lh.om.OrderManagerService;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.SUBJ_MARKET_STATUS;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class EcnUserManager implements IEcnUserManager { // IFtMemberListener
	private static final Logger log = LoggerFactory.getLogger(EcnUserManager.class);

    private static final String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";
    private static final String _marketStatusSubSql = "select * from " + SUBJ_MARKET_STATUS + " where ecn='%s' and gwt=ORDER_MANAGER";
    private static final String _ecnCredentialsSubSql = "select * from ecn.credentials where ecn=%s";
    private static final String _userStatusSubSql = "select * from user.status where mode=RESPONSE";
    private static final String _ecnUserStatusSubSql = "select * from ecn.user.status where ecn='%s' and mode=RESPONSE";

	private PrestoClient _client;
    private final String _ftGroup;
	protected final int _ftInstance;
	protected String _cmId;

	private final String _ecn;
	private final ILoginManagerAdaptor _adaptor;

	private boolean _active;

	private MadrigalMarketStatus _marketStatus = MadrigalMarketStatus.CLOSED;

    private final Map<String, EcnCredentialsObj> _ecnCredentialsByUid = new HashMap<>();
    private final Map<String, UserStatusObj> _userStatusByUid = new HashMap<>();
    private final Map<String, EcnUserStatusObj> _ecnUserStatusByUid = new HashMap<>();

    private final PendingRequests _pendingRequests = new PendingRequests();

	private final Delayer<FtMemberObj> _loopbackDelayer = new Delayer<>("FtMember",
		ftMem -> {
			try {
				_client.loopback(ftMem);
				ftMem.stopUsing();
			} catch (Exception x) {
				log.error(_cmId, x);
			}
		});

    private int _loopbackDelayMillis = 100;
    public void setLoopbackDelayMillis(String loopbackDelayMillis) {
    	_loopbackDelayMillis = Utils.parseAsInt("loopbackDelayMillis", loopbackDelayMillis, _loopbackDelayMillis);
    }

    private OrderManagerService _orderManagerService; // TODO
    public void setOrderManagerService(OrderManagerService orderManagerService) {
    	_orderManagerService = orderManagerService;
    }



	public EcnUserManager(PrestoClient client, String ecn, ILoginManagerAdaptor adaptor) {
    	_client = client;
    	_ftGroup = "FT.EUM." + client.getAppInfo().getShard();
    	_ftInstance = client.getAppInfo().getInstance();
    	_cmId = _ftInstance+" ";
    	_ecn = ecn;
    	_adaptor = adaptor;
    }

	public void start() {
        _loopbackDelayer.start();

        _client.waitUntilInitialized();

        try {
            _client.subscribe(String.format(_ftMemberSubSql, _ftGroup, _ftInstance), (obj, subsId) -> {
            	onFtMemberMessage((FtMemberObj) obj);
        	});
            _client.snapSubscribe(String.format(_marketStatusSubSql, _ecn), (obj, subsId) -> {
            	onMarketStatusMessage((MarketStatusObj) obj);
            });
	        _client.snapSubscribe(String.format(_ecnCredentialsSubSql, _ecn), (obj, subsId) -> {
	        	onEcnCredentialsMessage((EcnCredentialsObj) obj);
	        });
            _client.snapSubscribe(_userStatusSubSql, (obj, subsId) -> {
            	onUserStatusMessage((UserStatusObj) obj);
            });
	        _client.snapSubscribe(String.format(_ecnUserStatusSubSql, _ecn), (obj, subsId) -> {
	        	onEcnUserStatusMessage((EcnUserStatusObj) obj);
	        });
        } catch (Exception e) {log.error(_cmId, e);}

    	_client.registerFtMember(_ftGroup, _ftInstance, 1);
	}

	public void stop() {
		
	}

	@Override
    public void publishEcnUserLogOpResponse(String ecnUid, MadrigalUserStatus status, String text) { // this is the response from the exchange / line handler
		log.info("{} publishEcnUserLogOpResponse({}, {}, {})", _cmId, ecnUid, status, text);
		EcnUserStatusObj ecnUserStatus = new EcnUserStatusObj();
		ecnUserStatus.setResponse(_ftInstance, null, _ecn, ecnUid, null, MadrigalLogOp.NULL_VAL, status, text, System.currentTimeMillis());
		try {
			_client.loopback(ecnUserStatus);
		} catch (Exception e) {
			log.error(_cmId, e);
		}
	}

	@VisibleForTesting
	public void onFtMemberMessage(FtMemberObj ftMem) {
        log.info("{} onLoopback={} onFtMemberMessage({}_{} '{}' {}/{})", _cmId, ftMem.isOnLoopback(), ftMem.getGroupName(), ftMem.getInstance(), ftMem.getAction(), ftMem.getStripeNo(), ftMem.getOfStripes());
    	if (!ftMem.isOnLoopback() && _loopbackDelayMillis != 0) {
    		ftMem.startUsing();
        	_loopbackDelayer.add(_loopbackDelayMillis, ftMem);
    	} else {
        	boolean active = (ftMem.getAction() == ACTIVATE) ? true : (ftMem.getAction() == DEACTIVATE) ? false : _active;
        	if (active!=_active) {
        		_active = active;
        		if (!_active) {
        			_pendingRequests.clear();
        			return;
        		}
            	evaluateState();
        	}
    	}
	}

	@VisibleForTesting
	public void onMarketStatusMessage(MarketStatusObj marketStatusObj) {
		MadrigalMarketStatus marketStatus = marketStatusObj.getStatus();
        log.info("{} onMarketStatus({} {})", _cmId, marketStatus, marketStatusObj.getGwt());
		if (_marketStatus != marketStatus) {
			_marketStatus = marketStatus;
			if (_marketStatus == MadrigalMarketStatus.CLOSED) {
				handleMarketClosed(_ecnUserStatusByUid.values());
			} else {
				evaluateState();
			}
		}
	}

	private void handleMarketClosed(Collection<EcnUserStatusObj> currentStatuses) {
		for (EcnUserStatusObj obj : currentStatuses) {
			String uid = obj.getUid();
			if (!_pendingRequests.handleMarketClosed(uid)) { // no pending requests for this uid
				if (obj.getStatus() != MadrigalUserStatus.Off) { // current status for uid is On
					log.info("{} forcing logout {}", _cmId, obj);
					String ecnUid = obj.getEcnUid();
					String ecnPwd = obj.getEcnPwd();
					publishEcnUserStatus(uid, ecnUid, ecnPwd, MadrigalLogOp.logout, MadrigalUserStatus.Off, "Market CLOSED");
					_pendingRequests.evalQueuedState(uid);
				}
			}
		}
		_pendingRequests.handleMarketClosed();
	}

	@VisibleForTesting
	public void onEcnCredentialsMessage(EcnCredentialsObj ecnCredentials) {
		log.info("{} onEcnCredentials({})", _cmId, ecnCredentials);
		String uid = ecnCredentials.getUid();
    	_ecnCredentialsByUid.put(uid, ecnCredentials);
       	evaluateState(uid);
	}

	@VisibleForTesting
	public void onUserStatusMessage(UserStatusObj userStatus) {
        log.info("{} onUserStatus({})", _cmId, userStatus);
        String uid = userStatus.getUid();
        _userStatusByUid.put(uid, userStatus);
       	evaluateState(uid);
	}

	@VisibleForTesting
	public void onEcnUserStatusMessage(EcnUserStatusObj ecnUserStatus) {
		log.info("{} onEcnUserStatus({})", _cmId, ecnUserStatus);

		if (ecnUserStatus.isOnLoopback()) {
			_pendingRequests.handleEcnResponse(ecnUserStatus.getEcnUid(), ecnUserStatus.getStatus(), ecnUserStatus.getText());
		} else {
			String uid = ecnUserStatus.getUid();
	    	_ecnUserStatusByUid.put(uid, ecnUserStatus);
	    	evaluateState(uid);
		}
	}

	private void evaluateState() {
		for (String uid : _userStatusByUid.keySet()) {
			evaluateState(uid);
		}
	}
	private void evaluateState(String uid) {
		if (_pendingRequests.hasPendRequestFor(uid)) {
			_pendingRequests.queueEval(uid);
		} else {
			if (!_active) return;
	
			EcnCredentialsObj ecnCredentials = _ecnCredentialsByUid.get(uid);
			if (ecnCredentials == null) return;
	
			String targetEcnUid = ecnCredentials.getEcnUid();
			String targetEcnUidPwd = ecnCredentials.getEcnPwd();
			MadrigalUserStatus existingStatus = MadrigalUserStatus.Off;
			String existingEcnUid = null;
			String existingEcnPwd = null;
			MadrigalLogOp existingOp = null;
			int instance = _ftInstance;
			EcnUserStatusObj ecnUserStatus = _ecnUserStatusByUid.get(uid);
			if (ecnUserStatus!=null) {
				existingStatus = ecnUserStatus.getStatus();
				existingEcnUid = ecnUserStatus.getEcnUid();
				existingEcnPwd = ecnUserStatus.getEcnPwd();
				existingOp = ecnUserStatus.getOp();
				instance = ecnUserStatus.getInstance();
			}
			MadrigalUserStatus targetStatus =
					computeTargetStatus(instance, uid, existingOp, existingStatus, existingEcnUid, targetEcnUid, existingEcnPwd, targetEcnUidPwd);
			if (log.isDebugEnabled()) log.info("{} === evaluateState({}) {}/{}/{}/{} => {}/{}/{}/{}", _cmId, uid, instance, existingStatus, existingEcnUid, existingEcnPwd, _ftInstance, targetStatus, targetEcnUid, targetEcnUidPwd);

//			23:52:48,353 INFO [TightLoopThread][EcnUserManager] 0  === evaluateState(cl0mm) 0/Off/null/null => 0/Off/cl0.mm0/mm0Pwd

			if (existingStatus != targetStatus) { // status changes
				if (targetStatus == MadrigalUserStatus.On) {
					logOp(uid, targetEcnUid, targetEcnUidPwd, MadrigalLogOp.login);
				} else {
					logOp(uid, targetEcnUid, existingEcnPwd, MadrigalLogOp.logout);
				}
			} else if (!targetEcnUidPwd.equals(existingEcnPwd) || !targetEcnUid.equals(existingEcnUid) || instance!=_ftInstance) { // status stays the same but uid/password/instance changes
				if (targetStatus == MadrigalUserStatus.On) { // I am logged in and need to stay logged in but the ecnUid/ecnPwd have changed
					logOp(uid, existingEcnUid, existingEcnPwd, MadrigalLogOp.logout); // need to logout first
					_pendingRequests.queueEval(uid); // and when the replies comes back re-evaluate
				} // I am logged out and need to stay logged out
			} // same everything => do nothing
		}
	}

	private MadrigalUserStatus computeTargetStatus(int instance, String uid, MadrigalLogOp existingOp, MadrigalUserStatus existingStatus,
			String existingEcnUid, String targetEcnUid, String existingEcnPwd, String targetEcnPwd) {
		// active, market status, madrigal user status, credentials
		if (_marketStatus != MadrigalMarketStatus.OPEN) return MadrigalUserStatus.Off;      // market is closed
		UserStatusObj userStatus = _userStatusByUid.get(uid);
		if (userStatus==null || userStatus.getStatus() == MadrigalUserStatus.Off)
			return MadrigalUserStatus.Off;                                                  // madrigal user is not logged in

		if (instance!=_ftInstance) return MadrigalUserStatus.Off;                             // my status is cached from another instance => need to log off (if not already)

		if (existingStatus==MadrigalUserStatus.Off && existingOp==MadrigalLogOp.login && targetEcnPwd.equals(existingEcnPwd) && targetEcnUid.equals(existingEcnUid))
			return MadrigalUserStatus.Off;                                                  // I am logged out and last time I tried to login with the same credentials
		return MadrigalUserStatus.On;                                                       // I need to log in
	}

	private void logOp(String uid, String ecnUid, String ecnPwd, MadrigalLogOp op) {
		if (op == MadrigalLogOp.login) {
			_adaptor.login(ecnUid, ecnPwd);
		} else {
			if (_orderManagerService != null && !isLoggedIn(uid)) {
				_orderManagerService.cancelAllActiveOrders(ecnUid); // TODO
			}
			_adaptor.logout(ecnUid, ecnPwd);
		}

		try {
			EcnUserStatusObj ecnUserRequest = new EcnUserStatusObj();
            ecnUserRequest.setRequest(_ftInstance, uid, _ecn, ecnUid, ecnPwd, op, System.currentTimeMillis());
			_client.publish(ecnUserRequest);
			_pendingRequests.pendRequest(uid, ecnUid, ecnUserRequest);
			if (log.isDebugEnabled()) log.info("{} @@@ added {}", _cmId, ecnUserRequest);
		} catch (Exception e) {
			log.error(_cmId, e);
		}
	}

    private boolean isLoggedIn(String uid) {
		UserStatusObj userStatus = _userStatusByUid.get(uid);
		if (userStatus==null) return false;
		return userStatus.getStatus() == MadrigalUserStatus.On;
    }

    private void publishEcnUserStatus(String uid, String ecnUid, String ecnPwd, MadrigalLogOp op, MadrigalUserStatus status, String text) {
		EcnUserStatusObj ecnUserStatus = new EcnUserStatusObj();
		ecnUserStatus.setResponse(_ftInstance, uid, _ecn, ecnUid, ecnPwd, op, status, text, System.currentTimeMillis());
		_ecnUserStatusByUid.put(uid, ecnUserStatus);
		try {
			_client.publish(ecnUserStatus);
		} catch (Exception e) {
			log.error(_cmId, e);
		}
		if (_orderManagerService != null) {
			_orderManagerService.onEcnUserStatusResult(ecnUserStatus); // TODO
		}
	}


	private class PendingRequests {
		private final Map<String, EcnUserStatusObj> _pendEcnUserRequestsByUid = new HashMap<>();
		private final Map<String, EcnUserStatusObj> _pendEcnUserRequestsByEcnUid = new HashMap<>();
		private final Set<String> _queuedEvals = new HashSet<>();

		public boolean hasPendRequestFor(String uid) {
			return _pendEcnUserRequestsByUid.get(uid) != null;
		}

		public void pendRequest(String uid, String ecnUid, EcnUserStatusObj ecnUserRequest) {
			_pendEcnUserRequestsByUid.put(uid, ecnUserRequest);
			_pendEcnUserRequestsByEcnUid.put(ecnUid, ecnUserRequest);
		}
		
		public void queueEval(String uid) {
			_queuedEvals.add(uid);
		}

		public void evalQueuedState(String uid) {
			if (_queuedEvals.remove(uid)) {
				evaluateState(uid);
			}
		}

		public void clear() {
			if (_pendEcnUserRequestsByUid.size()>0) if (log.isDebugEnabled()) log.info("{} --- clearing {} pend entries", _cmId, _pendEcnUserRequestsByUid.size());
			_pendEcnUserRequestsByUid.clear();
			_pendEcnUserRequestsByEcnUid.clear();
			if (_queuedEvals.size()>0) if (log.isDebugEnabled()) log.info("{} --- clearing {} queued evaluations", _cmId, _queuedEvals.size());
			_queuedEvals.clear();
		}

		public boolean handleMarketClosed(String uid) {
			EcnUserStatusObj pend = _pendEcnUserRequestsByUid.remove(uid);
			if (pend!=null) {
				String ecnUid = pend.getEcnUid();
				String ecnPwd = pend.getEcnPwd();
				if (log.isDebugEnabled()) log.info("{} @@@ abandoned {}", _cmId, pend);
				_pendEcnUserRequestsByEcnUid.remove(ecnUid);
				publishEcnUserStatus(uid, ecnUid, ecnPwd, MadrigalLogOp.logout, MadrigalUserStatus.Off, "Market CLOSED");
				_queuedEvals.remove(uid); // abandon any queued evaluation
				return true;
			}
			return false;
		}

		public void handleMarketClosed() {
			for (EcnUserStatusObj pend : _pendEcnUserRequestsByUid.values()) {
				if (log.isDebugEnabled()) log.info("{} @@@ abandoned new {}", _cmId, pend);
				String uid = pend.getUid();
				String ecnUid = pend.getEcnUid();
				String ecnPwd = pend.getEcnPwd();
				_pendEcnUserRequestsByEcnUid.remove(ecnUid);
				publishEcnUserStatus(uid, ecnUid, ecnPwd, MadrigalLogOp.logout, MadrigalUserStatus.Off, "Market CLOSED");
				_queuedEvals.remove(uid); // abandon any queued evaluation
			}
			_pendEcnUserRequestsByUid.clear();
		}

		public void handleEcnResponse(String ecnUid, MadrigalUserStatus status, String text) {
			EcnUserStatusObj ecnUserRequest = _pendEcnUserRequestsByEcnUid.remove(ecnUid);
			if (ecnUserRequest!=null) {
				if (log.isDebugEnabled()) log.info("{} @@@ removed {}", _cmId, ecnUserRequest);
				String uid = ecnUserRequest.getUid();
				_pendEcnUserRequestsByUid.remove(uid);
				String ecnPwd = ecnUserRequest.getEcnPwd();
				MadrigalLogOp op = ecnUserRequest.getOp();
				publishEcnUserStatus(uid, ecnUid, ecnPwd, op, status, text);
				evalQueuedState(uid);
			}
		}
	}
}
