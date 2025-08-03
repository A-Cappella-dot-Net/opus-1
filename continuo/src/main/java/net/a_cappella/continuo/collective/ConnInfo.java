package net.a_cappella.continuo.collective;

import net.a_cappella.continuo.utils.Utils;

import java.util.Objects;

public class ConnInfo {
    private static final int DFT_SERVER_PORT = 9430;

    private String _host = Utils._localhost;
    private int _port = DFT_SERVER_PORT;
    private String _conn = _host+":"+_port;

    public ConnInfo() {}

    public ConnInfo(ConnInfo other) {
        this(other._host, other._port);
    }

    public ConnInfo(String str) {
        if (str==null || "".equals(str.trim())) return; // use default values
        int pos = str.indexOf('@');
        if (pos<0) {
        } else if (pos==0) {
            parseHostPort(str.substring(1));
        } else {
            parseHostPort(str.substring(pos+1));
        }
        if ("localhost".equalsIgnoreCase(_host)) {
            _host = Utils._localhost;
        }
        setConn();
    }

    public ConnInfo(String host, int port) {
        _host = host;
        _port = port;
        setConn();
    }

    public String getHost() {
        return _host;
    }
    public int getPort() {
        return _port;
    }
    public String getConn() {
        return _conn;
    }
    public void setConn() {
        _conn = _host+":"+_port;
    }

    private void parseHostPort(String str) {
        int pos = str.indexOf(':');
        if (pos<0) {
            _host = str;
        } else if (pos==0) {
            _port = Integer.parseInt(str.substring(pos+1));
        } else {
            _host = str.substring(0, pos);
            _port = Integer.parseInt(str.substring(pos+1));
        }
    }

    public boolean equals(Object obj) {
        if (obj instanceof ConnInfo) {
            ConnInfo other = (ConnInfo) obj;
            return _conn.equals(other._conn);
        }
        return false;
    }
    public int hashCode() {
        return Objects.hash(_conn);
    }
    public String toString() {
        return _conn;
    }
}
