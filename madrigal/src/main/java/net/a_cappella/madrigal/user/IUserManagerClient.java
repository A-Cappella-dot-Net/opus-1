package net.a_cappella.madrigal.user;

import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;

public interface IUserManagerClient {
    void start();
    void adjustClId(String clId);
    int login(String uid, String pwd, boolean rejectIfLoggedIn);
    int logout(String uid, String pwd, boolean forceLogout);

    void onUserStatusResult(UserStatusObj userStatus);
    void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus);
}
