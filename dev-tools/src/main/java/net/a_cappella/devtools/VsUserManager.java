package net.a_cappella.devtools;

import com.google.gson.JsonObject;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.IUserManagerClient;
import net.a_cappella.presto.ps.AeronClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.websocket.api.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

import static javax.management.timer.Timer.ONE_DAY;

public class VsUserManager {
    private static final Logger log = LoggerFactory.getLogger(VsUserManager.class);

    private final PrestoClient _client;
    private final IUserManagerClient _userMgr;

    private Map<String, AuthDetails> _authDetailsByUid = new HashMap<>(); // (pwd, expiry)
    private Map<String, Map<String, AuthDetails>> _uidAuthDetailsByHost = new HashMap<>(); // (host, (uid, (pwd, expiry)))

    private Map<Integer, SessionHandler> _sessionHandlersByReqId = new HashMap<>();

    private Consumer<UserStatusObj> _consumer = (userStatus) -> {
        String uid = userStatus.getUid();
        String pwd = userStatus.getPwd();
        int reqId = userStatus.getReqId();
        SessionHandler handler = _sessionHandlersByReqId.remove(reqId);
        Session session = handler._session;
        JsonObject result;
        if (userStatus.getReqStatus() == MadrigalUserStatus.On) {
            handler._username = uid;
            handler._password = pwd;
            handler._isAuthenticated = true;

            result = loginSucceeded(uid, pwd);
        } else {
            result = loginFailed(uid);
        }
        sendMessage(session, result);
    };

    public void sendMessage(Session session, JsonObject msg) {
        try {
            session.getRemote().sendString(msg.toString());
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }


    public VsUserManager(PrestoClient client) {
        _client = client;
        if (_client instanceof AeronClient) {
            _userMgr = new MyUserManagerClient(_client, _consumer);
        } else {
            _userMgr = new DummyUserManagerClient(_consumer);
        }
    }

    public void start() {
        _userMgr.start();
    }

    private JsonObject loginSucceeded(String username, String password) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "login_response");
        response.addProperty("success", true);
        response.addProperty("username", username);
        return response;
    }

    private JsonObject loginFailed(String username) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "login_response");
        response.addProperty("success", false);
        response.addProperty("message", "Invalid username or password");
        return response;
    }

    public void login(SessionHandler handler, String uid, String pwd) {
        Session session = handler._session;
        String host = ((InetSocketAddress) session.getRemoteAddress()).getHostName();
        AuthDetails ad = _authDetailsByUid.get(uid);
        if (ad != null && ad._pwd != null && System.currentTimeMillis() < ad._expiry) {
            if (pwd.equals(ad._pwd)) {
                ad._expiry = System.currentTimeMillis() + ONE_DAY;
                Map<String, AuthDetails> uidAuthDetail = _uidAuthDetailsByHost.computeIfAbsent(host, h -> new HashMap<>());
                if (!uidAuthDetail.containsKey(uid)) {
                    uidAuthDetail.put(uid, ad);
                } // otherwise it's the ad object which we just updated
                sendMessage(session, loginSucceeded(uid, pwd));
            } else {
                sendMessage(session, loginFailed(uid));
            }
        } else { // need to login
            int reqId = _userMgr.login(uid, pwd, false);
            _sessionHandlersByReqId.put(reqId, handler);
        }
    }

    public void logout(SessionHandler handler, String uid, String pwd) {
        AuthDetails ad = _authDetailsByUid.get(uid);
        if (ad != null) {
            ad._pwd = null;
        }
        _userMgr.logout(uid, pwd, false);
    }

    public boolean reauth(SessionHandler handler, String uid) {
        AuthDetails ad = _authDetailsByUid.get(uid);
        if (ad != null || ad._expiry < System.currentTimeMillis() || ad._pwd == null) {
            return false;
        } else {
            return true;
        }
    }

    private static class AuthDetails {
        private String _pwd;
        private long _expiry;

        public AuthDetails(String pwd) {
            _pwd = pwd;
            _expiry = System.currentTimeMillis() + 24 * 3_600 * 1_000; // 24 hours from now
        }
    }
}
