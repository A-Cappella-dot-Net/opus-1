package net.a_cappella.continuo.msg;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;

import java.nio.ByteBuffer;
import java.util.Objects;

import static net.a_cappella.continuo.PrestoConstants.REGISTRATION_REQUEST;

public class RegistrationRequest extends Msg {

    private AppInfo _appInfo;
    private ConnInfo _myConnInfo;
    private long _startTime;

    public RegistrationRequest() {
        this(null, 0);
    }

    public RegistrationRequest(RegistrationRequest other) {
        this(new AppInfo(other._appInfo), other._startTime);
        _myConnInfo = other._myConnInfo;
    }

    public RegistrationRequest(AppInfo appInfo, long startTime) {
        _appInfo = appInfo;
        _startTime = startTime;
        _myConnInfo = null;
    }

    public void setStartTime() {
        _startTime = System.currentTimeMillis();
    }

    public AppInfo getAppInfo() {
        return _appInfo;
    }

    public void setMyConnInfo(ConnInfo myConnInfo) {
        _myConnInfo = myConnInfo;
    }
    public ConnInfo getMyConnInfo() {
        return _myConnInfo;
    }
    public boolean isFromDaemon() {
        return _myConnInfo != null;
    }

    public String getKey() {
        if (isFromDaemon())	return _myConnInfo.getConn();
        return _appInfo.getId();
    }

    @Override
    public int getMsgType() {
        return REGISTRATION_REQUEST;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putLong(_startTime);
        putString(buffer, _appInfo.getApp());
        buffer.putShort(_appInfo.getStripe());
        buffer.putShort(_appInfo.getInstance());

        if (_myConnInfo == null) {
            buffer.putShort((short) 0);
        } else {
            buffer.putShort((short) 1);
            putString(buffer, _myConnInfo.getHost());
            buffer.putInt(_myConnInfo.getPort());
        }
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _startTime = buffer.getLong();
        String app = getString(buffer);
        short stripe = buffer.getShort();
        short instance = buffer.getShort();
        _appInfo = new AppInfo(app, stripe, instance);

        short hasConn = buffer.getShort();
        if (hasConn == 1) {
            String host = getString(buffer);
            int port = buffer.getInt();
            _myConnInfo = new ConnInfo(host, port);
        }
        return this;
    }

    @Override
    public void reset() {
        _appInfo = null;
        _startTime = 0;
        _myConnInfo = null;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null) return false;
        if (getClass() != obj.getClass()) return false;
        RegistrationRequest other = (RegistrationRequest) obj;

        if (_myConnInfo == null) {
            if (other._myConnInfo != null) return false;
        } else if (!_myConnInfo.equals(other._myConnInfo)) return false;

        return _appInfo.equals(other._appInfo) && _startTime == other._startTime;
    }

    @Override
    public int hashCode() {
        return Objects.hash(_startTime, _appInfo, _myConnInfo);
    }

    @Override
    public String toString() {
        return _appInfo + ((_myConnInfo==null) ? "" : ("@" + _myConnInfo)) + "[" + _startTime + "]";
    }
}
