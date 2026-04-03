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

import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.UserManagerClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.function.Consumer;

public class VsUserManagerClient extends UserManagerClient {
    private static final Logger log = LoggerFactory.getLogger(VsUserManagerClient.class);

    private String _userStatusResult = "";
    private String _ecnUserStatusResult = "";
    private Consumer<UserStatusObj> _consumer;

    public VsUserManagerClient(PrestoClient client, Consumer<UserStatusObj> consumer) {
        super(client, null);
        _consumer = consumer;
    }

    @Override
    public void onUserStatusResult(UserStatusObj userStatus) {
        String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
        _userStatusResult = now+" onUserStatusResult="+userStatus;
        log.info("{} {}", _userStatusResult, _ecnUserStatusResult);
        if (userStatus.getOp() == MadrigalLogOp.login) { // I was trying to login
            _consumer.accept(userStatus);
        }
    }

    @Override
    public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {
        String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
        _ecnUserStatusResult = now+" onEcnUserStatusResult="+ecnUserStatus;
        log.info("{} {}", _userStatusResult, _ecnUserStatusResult);
    }
}
