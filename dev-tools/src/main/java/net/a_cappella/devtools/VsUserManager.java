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

package net.a_cappella.devtools;

import com.google.gson.JsonObject;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.IUserManagerClient;
import net.a_cappella.presto.ps.AeronClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;

public class VsUserManager {
    private static final Logger log = LoggerFactory.getLogger(VsUserManager.class);

    private final PrestoClient _client;
    private final IUserManagerClient _userMgr;

    private Map<Integer, SessionHandler> _handlersByReqId = new HashMap<>(); // pending requests to MUM
    private Map<String, String> _loggedInUsers = new HashMap<>(); // (uid, pwd) - caches credentials of logged in users

    // logout affects all sessions associated to the initiating host and leaves the others unchanged
    private Map<String, Map<String, Set<SessionHandler>>> _handlersByHostAnUid = new HashMap<>(); // (host, (uid, handler))

    private Consumer<UserStatusObj> _consumer = (userStatus) -> {
        String uid = userStatus.getUid();
        int reqId = userStatus.getReqId();

        if (reqId < 0) { // unsolicited logoff (e.g., when the password is changed)
            _loggedInUsers.remove(uid);
            _handlersByHostAnUid.forEach((host, handlersByUid) -> {
                Set<SessionHandler> handlers = handlersByUid.get(uid);
                if (handlersByUid != null) {
                    handlers.forEach(h -> h.forceLogout());
                }
            });
        } else {
            SessionHandler handler = _handlersByReqId.remove(reqId);
            if (handler != null) {
                // the password is not coming back in UserStatusObj so it's retrieved from handler
                String pwd = handler._password;
                if (userStatus.getReqStatus() == MadrigalUserStatus.On) {
                    _loggedInUsers.put(uid, pwd);
                    handler.authenticated(uid, pwd);
                    _handlersByHostAnUid.computeIfAbsent(handler._host, h -> new HashMap<>())
                            .computeIfAbsent(uid, u -> new HashSet<>())
                            .add(handler);
                    handler.sendMessage(loginSucceeded(uid, pwd));
                } else { // userStatus.getReqStatus() == MadrigalUserStatus.Off
                    handler.sendMessage(loginFailed(uid));
                }
            }
        }
    };



    public VsUserManager(PrestoClient client) {
        _client = client;
        if (_client instanceof AeronClient) {
            _userMgr = new VsUserManagerClient(_client, _consumer);
        } else {
            _userMgr = new LoopbackUserManagerClient(_consumer);
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
        if (_loggedInUsers.containsKey(uid)) {
            String verPwd = _loggedInUsers.get(uid);
            if (verPwd.equals(pwd)) {
                handler.authenticated(uid, pwd);
                _handlersByHostAnUid.computeIfAbsent(handler._host, h -> new HashMap<>())
                        .computeIfAbsent(uid, u -> new HashSet<>())
                        .add(handler);
                handler.sendMessage(loginSucceeded(uid, pwd));
            } else {
                handler.notAuthenticated(uid, null);
                _handlersByHostAnUid.computeIfAbsent(handler._host, h -> new HashMap<>())
                        .computeIfAbsent(uid, u -> new HashSet<>())
                        .remove(handler);
                handler.sendMessage(loginFailed(uid));
            }
        } else { // need to login
            int reqId = _userMgr.login(uid, pwd, false);
            handler.notAuthenticated(uid, pwd); // optimistically storing the pwd in the handler
            _handlersByReqId.put(reqId, handler);
        }
    }

    public void logout(SessionHandler handler, String uid, String pwd) {
        Map<String, Set<SessionHandler>> handlersByUid = _handlersByHostAnUid.get(handler._host);
        if (handlersByUid != null) {
            Set<SessionHandler> handlers = handlersByUid.get(uid);
            if (handlers != null) {
                handlers.stream().filter(h -> h._password.equals(pwd)).forEach(h -> h.forceLogout());
            }
        }
    }

    public boolean reauth(SessionHandler handler, String uid) {
        Map<String, Set<SessionHandler>> handlersByUid = _handlersByHostAnUid.get(handler._host);
        if (handlersByUid != null) {
            Set<SessionHandler> handlers = handlersByUid.get(uid);
            if (handlers != null) {
                return handlers.contains(handler);
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    public void onSessionEnd(SessionHandler handler) {
        Map<String, Set<SessionHandler>> handlersByUid = _handlersByHostAnUid.get(handler._host);
        if (handlersByUid != null) {
            Set<SessionHandler> handlers = handlersByUid.get(handler._username);
            if (handlers != null) {
                handlers.remove(handler);
            }
        }
    }
}
