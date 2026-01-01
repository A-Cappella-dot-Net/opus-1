package net.a_cappella.madrigal.user;

import com.google.common.annotations.VisibleForTesting;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.CredentialsObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.obj.FtMonitorObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MONITOR;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.FT_USER_PREFIX;
import static net.a_cappella.madrigal.common.constants.MadrigalLogOp.login;
import static net.a_cappella.madrigal.common.constants.MadrigalLogOp.logout;
import static net.a_cappella.madrigal.common.constants.MadrigalUserStatus.Off;
import static net.a_cappella.madrigal.common.constants.MadrigalUserStatus.On;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class MadrigalUserManager {
	private static final Logger log = LoggerFactory.getLogger(MadrigalUserManager.class);

    private static final String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";
    private static final String _ftMonitorSubSql = "select * from "+SUBJ_FT_MONITOR;
    private static final String _credentialsSubSql = "select * from credentials";
	private static final String _userStatusSql = "select * from user.status";

	private final PrestoClient _client;
	private final AppInfo _appInfo;
    private final String _ftGroup;
    private final int _ftInstance;
    private boolean _active;

    private final Map<String, CredentialsObj> _credentialsCache = new HashMap<>();

    private final Map<String, StatusAndClIds> _cache = new HashMap<>();

    private static class StatusAndClIds {
		private UserStatusObj _userStatus;
		private final Set<String> _clIds = new HashSet<>();

		public StatusAndClIds(UserStatusObj userStatus) {
			_userStatus = userStatus;
		}
	}

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

    public MadrigalUserManager(PrestoClient client) {
    	_client = client;
    	_appInfo = client.getAppInfo();
		_ftGroup = "FT.UM." + _appInfo.getShard();
		_ftInstance = _appInfo.getInstance();
    }

	public void start() {
		_client.waitUntilInitialized();
		
        try {
        	// Madrigal credentials
            _client.snapSubscribe(_credentialsSubSql, (obj, subsId) -> {
            	onCredentialsMessage((CredentialsObj) obj);
            });
            // user status requests and responses
            _client.snapSubscribe(_userStatusSql, (obj, subsId) -> {
            	onUserStatus((UserStatusObj) obj);
            });
            // update this process' active/inactive status
            _client.subscribe(String.format(_ftMemberSubSql, _ftGroup, _ftInstance), (obj, subsId) -> {
            	onFtMemberMessage((FtMemberObj) obj);
        	});
            // monitor events
            _client.subscribe(_ftMonitorSubSql, (obj, subsId) -> {
            	onFtMonitorMessage((FtMonitorObj) obj);
        	});
        } catch (Exception e) {log.error("", e);}

        _client.registerFtMember(_ftGroup, _ftInstance, 1);

        ShutdownHook.registerShutdownAction(() -> stop());
	}

	public void stop() {}

	@VisibleForTesting
	public void onCredentialsMessage(CredentialsObj credentials) {
		String uid = credentials.getUid();
		CredentialsObj prevCredentials = _credentialsCache.put(uid, credentials);
		if (prevCredentials != null && !prevCredentials.getPwd().equals(credentials.getPwd())) {
			StatusAndClIds statusAndClIds = _cache.get(uid);
			if (statusAndClIds != null) for (String clId : statusAndClIds._clIds) {
				statusAndClIds._userStatus = publishResponse(clId, -1, uid, logout, Off, Off, "Password Reset");
			}
		}
	}

	@VisibleForTesting
	public void onUserRequestMessage(UserStatusObj request, boolean checkCredentials) {
        log.info("{} onUserRequestMessage {} {} onLoopback={}", _appInfo, checkCredentials, request, request.isOnLoopback());
        String uid = request.getUid();
        String clId = request.getClId();
		int reqId = request.getReqId();
        boolean rejectIfAlreadyLoggedIn = request.isRejectIfLoggedIn();
        boolean forceLogout = request.isForceLogout();
        MadrigalLogOp op = request.getOp();

        CredentialsObj credentials = _credentialsCache.get(uid);
        if (credentials==null) {
            publishResponse(clId, reqId, uid, op, Off, Off, "Unknown user "+uid);
            return;
        }

		StatusAndClIds statusAndClIds = _cache.computeIfAbsent(uid, i -> new StatusAndClIds(new UserStatusObj()));
		MadrigalUserStatus status = statusAndClIds._userStatus.getStatus();

		if (checkCredentials && !credentials.getPwd().equals(request.getPwd())) {
			statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, status, Off, "Invalid credentials "+uid);
            return;
        }

        Set<String> clIdSet = statusAndClIds._clIds;
        if (login == op) { // I want to login
            if (On == status) { // I am already logged in
                if (clIdSet.contains(clId)) {
                	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, On, uid+"/"+clId+" already logged in");
                } else if (rejectIfAlreadyLoggedIn) {
                	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, Off, uid+" already logged in");
                } else {
                	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, On, uid+" already logged in");
                    clIdSet.add(clId);
                }
            } else { // I am logged out => login
            	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, On, "");
                clIdSet.add(clId);
            }
        } else if (logout == op) { // I want to logout
            if (On == status) { // I am logged in
            	if (forceLogout) {
                    clIdSet.clear();
                    statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, Off, Off, "");
                } else if (clIdSet.contains(clId)) {
                	String text = (checkCredentials) ? "" : request.getText();
                    clIdSet.remove(clId);
                    if (clIdSet.isEmpty()) {
                    	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, Off, Off, text);
                    } else {
                    	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, Off, text);
                    }
                } else { // logout request from a clientId that never logged in
                	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, On, Off, uid+"/"+clId+" never logged in");
                }
            } else { // I am already logged out
            	statusAndClIds._userStatus = publishResponse(clId, reqId, uid, op, Off, Off, uid+" already logged out");
            }
        } else {
            log.error("{} Unknown command '{}'", _appInfo, op);
        }
    }

	@VisibleForTesting
    public UserStatusObj publishResponse(String clId, int reqId, String uid, MadrigalLogOp op, MadrigalUserStatus userStatus, MadrigalUserStatus reqStatus, String text) {
		UserStatusObj response = new UserStatusObj();
		response.setResponse(uid, clId, reqId, op, userStatus, reqStatus, text, System.currentTimeMillis());

        if (_active) {
            log.info("{} publishResponse {} '{}'", _appInfo, _active, response);

			try {
				_client.publish(response);
			} catch (Exception e) {
				log.error("", e);
			}
    	}

    	return response;
	}

	@VisibleForTesting
	public void onUserResponseMessage(UserStatusObj response) {
        String uid = response.getUid();
        String clId = response.getClId();
        MadrigalUserStatus status = response.getStatus();
        MadrigalUserStatus reqStatus = response.getReqStatus();

		StatusAndClIds statusAndClIds = _cache.computeIfAbsent(uid, i -> new StatusAndClIds(response));
		Set<String> clIds = statusAndClIds._clIds;

        if (On == reqStatus) {
            clIds.add(clId);
        } else {
            clIds.remove(clId);
        }

        log.info("{} User Status {}/{} {}/{} ({})", _appInfo, uid, clId, status, reqStatus, clIds);
	}

	@VisibleForTesting
	public void onFtMemberMessage(FtMemberObj ftMem) {
        log.info("{} onFtMemberMessage({})", _appInfo, ftMem);

        if (ftMem.getAction() == ACTIVATE) {
			_active = true;
		} else if (ftMem.getAction() == DEACTIVATE) {
			_active = false;
		}
	}


	private void onUserStatus(UserStatusObj userStatus) {
        if (userStatus.getMadrigalMode() == MadrigalMode.REQUEST) {
            onUserRequestMessage(userStatus, true);
        } else if (userStatus.getMadrigalMode() == MadrigalMode.RESPONSE) {
            String group = FT_USER_PREFIX+userStatus.getUid()+"."+userStatus.getClId();
	        if (On == userStatus.getReqStatus()) { // clId logged in
                _client.registerFtMonitor(group);
	        } else { // Off - clId logged out
	        	_client.unregisterFtMonitor(group);
	        }
	        onUserResponseMessage(userStatus);
        }
	}

	public void onFtMonitorMessage(FtMonitorObj ftMem) {
		String groupName = ftMem.getGroupName();
		int actives = ftMem.getActives();

		if (!groupName.startsWith(FT_USER_PREFIX)) return;

		log.info("{} onFtMonitorMessage {} {}", _appInfo, groupName, actives);

		String[] groupComps = groupName.split("\\.");
		int compCount = groupComps.length;
		String uid = groupComps[compCount-2];
		String clId = groupComps[compCount-1];
		
		StatusAndClIds statusAndClIds = _cache.get(uid);
        if (statusAndClIds != null) {
    		UserStatusObj sta = statusAndClIds._userStatus;
            if (actives==0) { // process that logged in crashes without logging out
                if (On == sta.getStatus()) { // currently Logged In
                	// process a logoutRequest due to 'client disconnect'
            		try {
                        UserStatusObj logoutRequest = _userStatusObjThreadLocal.get();
            			logoutRequest.setRequest(uid, clId, 0, logout, null, false, false, System.currentTimeMillis());
            			logoutRequest.setText("client disconnect");
        				onUserRequestMessage(logoutRequest, false);
            		} catch (Exception e) {
            			log.error("", e);
            		}

            		// remove clId from the monitoring group
                    _client.unregisterFtMonitor(groupName);
                } // already logged out, do nothing
            } // else still active, do nothing
        }
	}
}
