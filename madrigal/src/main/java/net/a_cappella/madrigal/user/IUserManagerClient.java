package net.a_cappella.madrigal.user;

public interface IUserManagerClient {
    void start();
    void adjustClId(String clId);
    void login(String uid, String pwd, boolean rejectIfLoggedIn);
    void logout(String uid, String pwd, boolean forceLogout);
}
