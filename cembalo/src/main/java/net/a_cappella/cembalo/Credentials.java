package net.a_cappella.cembalo;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class Credentials {
    private final Map<String, String> _map = new HashMap<>();

    public Credentials(Map<String, Map<String, String>> map) {
        for (Map.Entry<String, Map<String, String>> entry : map.entrySet()) {
            String org = entry.getKey();
            for (Map.Entry<String, String> cred : entry.getValue().entrySet()) {
                String uid = cred.getKey();
                String pwd = cred.getValue();
                _map.put(org+"."+uid, pwd);
            }
        }
    }

    public boolean allowed(String orgUid, String pwd) {
        return Objects.equals(_map.get(orgUid), pwd);
    }
}
