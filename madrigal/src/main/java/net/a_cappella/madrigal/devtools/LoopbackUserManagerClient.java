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

package net.a_cappella.madrigal.devtools;

import net.a_cappella.continuo.utils.Delayer;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.IUserManagerClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

public class LoopbackUserManagerClient implements IUserManagerClient {
    private static final Logger log = LoggerFactory.getLogger(LoopbackUserManagerClient.class);

    private static final Map<String, String> USERS = new HashMap<>();
    static {
        // Hardcoded users for demo
        USERS.put("admin", "admin");
        USERS.put("user", "password");
    }
    private Consumer<UserStatusObj> _consumer;
    private int _reqId = 0;

    private final Delayer<UserStatusObj> _responseDelayer = new Delayer<>("UserStatus",
            userStatus -> {
                try {
                    onUserStatusResult(userStatus);
                    userStatus.stopUsing();
                } catch (Exception x) {
                    log.error("", x);
                }
            });

    private int _responseDelayMillis = 100;


    public LoopbackUserManagerClient(Consumer<UserStatusObj> consumer) {
        _consumer = consumer;
    }

    @Override
    public void start() {
        _responseDelayer.start();
    }

    @Override
    public int login(String username, String password, boolean rejectIfLoggedIn) {
        int reqId = _reqId++;

        String storedPassword = USERS.get(username);
        boolean authenticated = storedPassword != null && storedPassword.equals(password);
        UserStatusObj userStatus = new UserStatusObj();
        MadrigalUserStatus status = (authenticated) ? MadrigalUserStatus.On : MadrigalUserStatus.Off;
        userStatus.setResponse(username, "", reqId, MadrigalLogOp.login, status, status, null, System.currentTimeMillis());
        _responseDelayer.add(_responseDelayMillis, userStatus);

        // return now and respond later asynchronously
        return reqId;
    }

    @Override
    public int logout(String uid, String pwd, boolean forceLogout) {
        return _reqId++;
    }

    @Override
    public void onUserStatusResult(UserStatusObj userStatus) {
        if (userStatus.getOp() == MadrigalLogOp.login) { // I was trying to login
            _consumer.accept(userStatus);
        }
    }

    @Override
    public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {
    }
}
