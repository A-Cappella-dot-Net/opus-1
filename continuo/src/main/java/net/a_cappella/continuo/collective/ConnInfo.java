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
