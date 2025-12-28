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
