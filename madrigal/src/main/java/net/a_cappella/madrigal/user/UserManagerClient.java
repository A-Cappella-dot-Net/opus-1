package net.a_cappella.madrigal.user;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.FT_USER_PREFIX;
import static net.a_cappella.madrigal.common.constants.MadrigalLogOp.login;
import static net.a_cappella.madrigal.common.constants.MadrigalLogOp.logout;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DISCONNECT;

public class UserManagerClient {
    private static final Logger log = LoggerFactory.getLogger(UserManagerClient.class);

    private static final String _loopbackTimerSql = "select * from ping where onLoopback=true";
    private static final String _loopbackUserRequestsSql = "select * from user.status where mode=REQUEST and onLoopback=true";
    private static final String _userStatusSql = "select * from user.status where mode=RESPONSE and clId='%s'";
    private static final String _ecnUserStatusAllEcnsSql = "select * from ecn.user.status where mode=RESPONSE";
    private static final String _ecnUserStatusSql = "select * from ecn.user.status where mode=RESPONSE and ecn='%s'";
    private static final String _ftMemSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";

	private static final int TIMER_INTERVAL_MILLIS = 1_000;
    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(UserManagerClient.class.getSimpleName() + "-%d").setDaemon(true).build();
    private static final ThreadLocal<UserStatusObj> _userStatusObjThreadLocal = new ThreadLocal<>() {
		public UserStatusObj initialValue() {
			return new UserStatusObj();
		}
		public UserStatusObj get() {
			UserStatusObj obj = super.get();
			obj.reset();
			return obj;
		}
	};

	private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);
    private ScheduledFuture<?> _scheduledFuture = null;

    private final PingObj _ping = new PingObj();

    private final PrestoClient _client;
    private final int _instance;
    private final String _ecn;

    private final String _clId;

    private final Map<String, UserStatusObj> _userStatusByUid = new HashMap<>(); // (uid, userStatus)
    private final Map<String, Map<String, EcnUserStatusObj>> _ecnUserStatusMap = new HashMap<>(); // (ecn, (uid, ecnUserStatus))

    private final ActiveRequests _activeRequests = new ActiveRequests();


    public UserManagerClient(PrestoClient client, String ecn) {
        _client = client;
        _instance = _client.getAppInfo().getInstance();
        _ecn = "".equals(ecn) ? null : ecn;

        _clId = Utils.nextId();
    }

	public void start() {
        ShutdownHook.registerShutdownAction(() -> stop());

        try {
            _client.subscribe(_loopbackTimerSql, (obj, subsId) -> {
            	onTimeoutMsg((PingObj) obj);
            });

            _client.subscribe(_loopbackUserRequestsSql, (obj, subsId) -> {
            	onUserRequest((UserStatusObj) obj);
            });

            _client.snapSubscribe(String.format(_userStatusSql, _clId), (obj, subsId) -> {
                onUserStatus((UserStatusObj) obj);
            });

            _client.snapSubscribe((_ecn==null) ? _ecnUserStatusAllEcnsSql : String.format(_ecnUserStatusSql, _ecn), (obj, subsId) -> {
                onEcnUserStatus((EcnUserStatusObj) obj);
            });
        } catch (Exception e) {
            log.error("", e);
        }

        _scheduledFuture = _scheduler.scheduleAtFixedRate(() -> {
            try {
            	_client.loopback(_ping);
            } catch (Exception x) {
            	log.error("", x);
            }
        }, TIMER_INTERVAL_MILLIS, TIMER_INTERVAL_MILLIS, TimeUnit.MILLISECONDS);
	}

	public void stop() {
        if (_scheduledFuture!=null) {
        	_scheduledFuture.cancel(false);
        	_scheduledFuture = null;
        }
        _scheduler.shutdown();
	}

    public void onUserStatusResult(UserStatusObj userStatus) {}
    public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {}

    public boolean isLoggedIn(String uid) {
    	if (!_client.onTLT()) throw new RuntimeException("method UserManagerClient.isLoggedIn should be invoked on the TLT");
    	UserStatusObj userStatus = _userStatusByUid.get(uid);
    	if (userStatus == null) return false;
    	return (userStatus.getReqStatus() == MadrigalUserStatus.On);
    }

    public boolean isLoggedIn(String uid, String ecn) {
    	if (!isLoggedIn(uid)) return false;

    	Map<String, EcnUserStatusObj> map = _ecnUserStatusMap.get(ecn);
    	if (map == null) return false;
    	EcnUserStatusObj ecnUserStatus = map.get(uid);
    	if (ecnUserStatus == null) return false;
    	return ecnUserStatus.getStatus() == MadrigalUserStatus.On;
    }

    public void login(String uid, String pwd, boolean rejectIfLoggedIn) {
    	if (_client.onTLT()) {
    		handleLoginRequest(uid, pwd, rejectIfLoggedIn);
    	} else {
    		loopback(login, uid, pwd, rejectIfLoggedIn, false);
    	}
    }

    public void logout(String uid, String pwd, boolean forceLogout) {
    	if (_client.onTLT()) {
    		handleLogoutRequest(uid, pwd, forceLogout);
    	} else {
    		loopback(logout, uid, pwd, false, forceLogout);
    	}
    }





    private void onTimeoutMsg(PingObj ping) {
		_activeRequests._userStatusRequests.forEach(reqAndSubsId -> {
			String uid = reqAndSubsId._req.getUid();
			if (!isLoggedIn(uid)) {
				publish(login, uid, reqAndSubsId._req.getPwd(), reqAndSubsId._req.isRejectIfLoggedIn(), false);
			}
		});
	}

	private void onUserRequest(UserStatusObj userStatus) {
		log.info("onUserRequest {}", userStatus);

		String uid = userStatus.getUid();
        String pwd = userStatus.getPwd();

        MadrigalLogOp op = userStatus.getOp();
        if (op == MadrigalLogOp.login) {
        	handleLoginRequest(uid, pwd, userStatus.isRejectIfLoggedIn());
        } else if (op == MadrigalLogOp.logout) {
        	handleLogoutRequest(uid, pwd, userStatus.isForceLogout());
        }
    }

    private void onUserStatus(UserStatusObj userStatus) {
        String uid = userStatus.getUid();
        _userStatusByUid.put(uid, userStatus);
        onUserStatusResult(userStatus);
    }

    private void onEcnUserStatus(EcnUserStatusObj ecnUserStatus) {
        String ecn = ecnUserStatus.getEcn();
        String uid = ecnUserStatus.getUid();
    	_ecnUserStatusMap.computeIfAbsent(ecn, u -> new HashMap<>()).put(uid, ecnUserStatus);
    	onEcnUserStatusResult(ecnUserStatus);
    }

    private void handleLoginRequest(String uid, String pwd, boolean rejectIfLoggedIn) {
    	if (isLoggedIn(uid)) return;

    	RequestAndSubId requestAndSubId = _activeRequests.activateRequest(uid, pwd, rejectIfLoggedIn);
    	if (requestAndSubId == null) return; // already active and subscription already exists

    	String group = FT_USER_PREFIX+uid+"."+_clId;
        _client.registerFtMember(group, _instance, 1);
		try {
			requestAndSubId._subId = _client.subscribe(String.format(_ftMemSubSql, group, _instance), (obj, subsId) -> {
            	onFtMemberMessage((FtMemberObj) obj);
            });
		} catch (Exception e) {
			log.error("", e);
		}
    }

    private void handleLogoutRequest(String uid, String pwd, boolean forceLogout) {
    	RequestAndSubId requestAndSubId = _activeRequests.deactivateRequest(uid);
    	if (requestAndSubId == null) return; // was not active to start with

    	String group = FT_USER_PREFIX+uid+"."+_clId;
        _client.unregisterFtMember(group, _instance);
		_client.unsubscribe(requestAndSubId._subId);
   		publish(logout, uid, pwd, false, forceLogout); // may be pending login
    }

    private void publish(MadrigalLogOp op, String uid, String pwd, boolean rejectIfLoggedIn, boolean forceLogout) {
    	if (log.isDebugEnabled()) log.info("publish {} {} {}", op, uid, pwd);
		try {
	        UserStatusObj req = _userStatusObjThreadLocal.get();
			req.setRequest(uid, _clId, op, pwd, rejectIfLoggedIn, forceLogout, System.currentTimeMillis());
			_client.publish(req);
		} catch (Exception e) {
			log.error("", e);
		}
    }

    private void loopback(MadrigalLogOp op, String uid, String pwd, boolean rejectIfLoggedIn, boolean forceLogout) {
    	if (log.isDebugEnabled()) log.info("loopback {} {} {}", op, uid, pwd);
		try {
	        UserStatusObj obj = _userStatusObjThreadLocal.get();
			obj.setRequest(uid, _clId, op, pwd, rejectIfLoggedIn, forceLogout, System.currentTimeMillis());
			_client.loopback(obj);
		} catch (Exception e) {
			log.error("", e);
		}
    }

	private void onFtMemberMessage(FtMemberObj ftMem) {
        log.info("onFtMemberMessage("+ftMem.getGroupName()+"_"+ftMem.getInstance()+" '"+ftMem.getAction()+"' "+ftMem.getSliceNo()+"/"+ftMem.getOfSlices()+")");
        if (ftMem.getAction() == DISCONNECT) {
        	_userStatusByUid.forEach((uid, userStatus) -> {
        		userStatus.setStatus(MadrigalUserStatus.Off);
        		userStatus.setReqStatus(MadrigalUserStatus.Off);
    			userStatus.setText("Disconnected");
    			log.info("onDisconnect {}", userStatus);
        	});
        	_ecnUserStatusMap.forEach((ecn, ecnUserStatusByUid) -> {
        		ecnUserStatusByUid.forEach((uid, ecnUserStatus) -> {
        			ecnUserStatus.setStatus(MadrigalUserStatus.Off);
        			ecnUserStatus.setText("Disconnected");
        			log.info("onDisconnect {}", ecnUserStatus);
        		});
        	});
        }
	}


    private static class RequestAndSubId {
    	UserStatusObj _req;
    	long _subId;
    }

    private static class ActiveRequests {
        List<RequestAndSubId> _userStatusRequests = new ArrayList<>();

        RequestAndSubId activateRequest(String uid, String pwd, boolean rejectIfLoggedIn) {
        	for (RequestAndSubId elem : _userStatusRequests) {
        		if (elem._req.getUid().equals(uid)) {
        			// update password
        			elem._req.setPwd(pwd);
        			elem._req.setRejectIfLoggedIn(rejectIfLoggedIn);
        			return null;
        		}
        	}
        	
        	RequestAndSubId elem = new RequestAndSubId();
        	elem._req = new UserStatusObj();
        	elem._req.setUid(uid);
        	elem._req.setPwd(pwd);
			elem._req.setRejectIfLoggedIn(rejectIfLoggedIn);
			_userStatusRequests.add(elem);
        	return elem;
        }

        RequestAndSubId deactivateRequest(String uid) {
        	for (RequestAndSubId elem : _userStatusRequests) {
        		if (elem._req.getUid().equals(uid)) {
        			_userStatusRequests.remove(elem);
        			return elem;
        		}
        	}
			return null;
        }
    }
}
