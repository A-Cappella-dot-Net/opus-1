package net.a_cappella.devtools;

import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;
import net.a_cappella.madrigal.common.obj.UserStatusObj;
import net.a_cappella.madrigal.user.IUserManagerClient;

import java.util.HashMap;
import java.util.Map;

public class DummyUserManagerClient implements IUserManagerClient {
    private static final Map<String, String> USERS = new HashMap<>();
    static {
        // Hardcoded users for demo
        USERS.put("admin", "admin");
        USERS.put("user", "password");
    }
    private TriConsumer<Boolean, String, String> _consumer;
    private int _reqId = 0;

    public DummyUserManagerClient(TriConsumer<Boolean, String, String> consumer) {
        _consumer = consumer;
    }

    @Override
    public void start() {}

    @Override
    public void adjustClId(String clId) {}

    @Override
    public int login(String username, String password, boolean rejectIfLoggedIn) {
        String storedPassword = USERS.get(username);
        _consumer.accept(storedPassword != null && storedPassword.equals(password), username, password);
        return _reqId++;
    }

    @Override
    public int logout(String uid, String pwd, boolean forceLogout) {
        return _reqId++;
    }

    @Override
    public void onUserStatusResult(UserStatusObj userStatus) {
    }

    @Override
    public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {
    }
}
