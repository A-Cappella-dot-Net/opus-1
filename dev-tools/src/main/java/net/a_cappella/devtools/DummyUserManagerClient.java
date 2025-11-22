package net.a_cappella.devtools;

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
    private TriConsumer<Boolean, String, String> msgBack;

    public DummyUserManagerClient(TriConsumer<Boolean, String, String> msgBack) {
        this.msgBack = msgBack;
    }

    @Override
    public void start() {}

    @Override
    public void adjustClId(String clId) {}

    @Override
    public void login(String username, String password, boolean rejectIfLoggedIn) {
        String storedPassword = USERS.get(username);
        msgBack.accept(storedPassword != null && storedPassword.equals(password), username, password);
    }

    @Override
    public void logout(String uid, String pwd, boolean forceLogout) {
    }
}
