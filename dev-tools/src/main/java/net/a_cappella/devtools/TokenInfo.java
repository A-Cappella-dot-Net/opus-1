package net.a_cappella.devtools;

public class TokenInfo {
    private final String _username;
    private final long _expiryTimeMillis;

    public TokenInfo(String username, long expiryTimeMillis) {
        _username = username;
        _expiryTimeMillis = expiryTimeMillis;
    }

    public boolean isExpired() {
        return _expiryTimeMillis < System.currentTimeMillis();
    }

    public String getUsername() {
        return _username;
    }
}
