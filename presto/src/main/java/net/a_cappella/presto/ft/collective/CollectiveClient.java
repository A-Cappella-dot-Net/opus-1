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

package net.a_cappella.presto.ft.collective;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.socket.BaseClientPipe;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ft.beans.GroupAndInstance;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.msg.FtMemberMsg;
import net.a_cappella.presto.msg.FtMonitorMsg;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.obj.FtMonitorObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.utils.conflator.MemConflator;
import net.a_cappella.presto.utils.conflator.MonConflator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import static net.a_cappella.continuo.PrestoConstants.YES;
import static net.a_cappella.presto.ft.constants.FtMsgOp.*;
import static net.a_cappella.presto.ft.constants.FtMsgType.REQUEST;
import static net.a_cappella.presto.ft.constants.FtMsgType.RESPONSE;

public class CollectiveClient implements IFtMemberClient, IFtMonitorClient, IFtMsgListenerNotifier {
    private static final Logger log = LoggerFactory.getLogger(CollectiveClient.class);

    public static final short NONE  = 0;
    public static final short ZERO  = 1 << 0;
    public static final short ONE   = 1 << 1;
    public static final short TWO   = 1 << 2;
    public static final short THREE = 1 << 3;

    private final String _cmId;
    protected AppInfo _myInfo;
    protected ConnInfo _sinkInfo;

    private final ClientPipe _pipe;
    private int _reconnectIntervalMillis = 200;
    private int _connectionTimeoutMicros = 200;

    private final Map<GroupAndInstance, FtMemberMsg> _activeMemRequests = new HashMap<>();
    private final Map<String, FtMonitorMsg> _activeMonRequests = new HashMap<>();

    private final MonConflator _monConflator;
    private final MemConflator _memConflator;

    private final List<IFtMemberListener> _ftMemberListeners = new CopyOnWriteArrayList<>();
    private final List<IFtMonitorListener> _ftMonitorListeners = new CopyOnWriteArrayList<>();

    private volatile PrestoClient _prestoClient;
    private final FtMemberObj _memObj = new FtMemberObj();
    private final FtMonitorObj _monObj = new FtMonitorObj();

    public CollectiveClient(MsgCoder coder, String connInfoStr, String monConfInterval, String memConfInterval) {
        _myInfo = new AppInfo(connInfoStr);
        _sinkInfo = new ConnInfo(connInfoStr);
        _cmId = _myInfo.getId() + " ";
        _pipe = new ClientPipe(_cmId, coder, _myInfo, _sinkInfo);
        _monConflator = new MonConflator(Utils.parseAsLong("monConfInterval", monConfInterval, 100), this);
        _memConflator = new MemConflator(Utils.parseAsLong("memConfInterval", memConfInterval, 0), this);
    }

    public AppInfo getAppInfo() {
        return _myInfo;
    }

    public void setPrestoClient(PrestoClient prestoClient) {
        _prestoClient = prestoClient;
        log.info("setting prestoClient");
    }

    public void start() {
        _pipe.startPipe();
    }
    public void stop() {
        _pipe.stopPipe();
        _monConflator.stop();
        _memConflator.stop();
    }
    public boolean isStopped() {
        return _pipe.isStopped();
    }
    public boolean isConnected() {
        return _pipe.isConnected();
    }

    @Override
    public void notifyFtMemberListeners(String groupName, int instance, FtMsgOp action, int sliceNo, int ofSlices) {
        log.info("{}onFtMemMsg({}-{} '{}' {}/{})", _cmId, groupName, instance, action, sliceNo, ofSlices);
        for (IFtMemberListener listener : _ftMemberListeners) {
            listener.onFtAction(groupName, instance, action, sliceNo, ofSlices);
        }
        try {
            if (_prestoClient!=null) _prestoClient.publish(_memObj.set(groupName, instance, action, sliceNo, ofSlices, System.currentTimeMillis()));
        } catch (Exception e) {
            log.error("Could not publish "+_memObj, e);
        }
    }

    @Override
    public void registerFtMember(String groupName, int instance, int activeGoal) {
        log.info("{}registerFtMember({}-{}@{})", _cmId, groupName, instance, activeGoal);
        GroupAndInstance key = new GroupAndInstance(groupName, instance);
        FtMemberMsg req;
        synchronized (_activeMemRequests) {
            req = _activeMemRequests.get(key);
            if (req==null) {
                req = new FtMemberMsg(REQUEST, REGISTER, YES, groupName, instance, activeGoal, 0, 0);
                _activeMemRequests.put(key, req);
            }
        }
        if (_pipe.isConnected()) {
            _pipe.sendMsg(req);
        } else {
            log.info("{}NOT connected", _cmId);
            _memConflator.conflate(groupName, instance, DISCONNECT, 0, 0, true);
        }
    }

    @Override
    public void unregisterFtMember(String groupName, int instance) {
        log.info("{}unregisterFtMember({}-{})", _cmId, groupName, instance);
        GroupAndInstance key = new GroupAndInstance(groupName, instance);
        FtMemberMsg req;
        synchronized (_activeMemRequests) {
            req = _activeMemRequests.remove(key);
        }
        if (req==null) {
            log.warn("{}{}-{} NOT registered", _cmId, groupName, instance);
        } else {
            if (_pipe.isConnected()) {
                req._op = UNREGISTER;
                _pipe.sendMsg(req);
            } else {
                log.warn("{}{}-{} NOT connected", _cmId, groupName, instance);
            }
        }
    }





    @Override
    public void notifyFtMonitorListeners(String groupName, int actives) {
        log.info("{}notifyFtMonitorListeners({} {})", _cmId, groupName, actives);
        for (IFtMonitorListener listener : _ftMonitorListeners) {
            listener.onActivesChanged(groupName, actives);
        }
        try {
            if (_prestoClient!=null) _prestoClient.publish(_monObj.set(groupName, actives, System.currentTimeMillis()));
        } catch (Exception e) {
            log.error("Could not publish "+_monObj, e);
        }
    }

    @Override
    public String getNotifierId() {
        return _cmId;
    }

    @Override
    public void registerFtMonitor(String groupName) {
        log.info("{}registerFtMonitor({})", _cmId, groupName);
        FtMonitorMsg req;
        synchronized (_activeMonRequests) {
            req = _activeMonRequests.get(groupName);
            if (req==null) {
                req = new FtMonitorMsg(groupName, REQUEST, REGISTER, YES, NONE);
                _activeMonRequests.put(groupName, req);
            }
        }
        if (_pipe.isConnected()) {
            _pipe.sendMsg(req);
        } else {
            _monConflator.conflate(groupName, NONE, true);
        }
    }

    @Override
    public void unregisterFtMonitor(String groupName) {
        log.info("{}unregisterFtMonitor({})", _cmId, groupName);
        FtMonitorMsg req;
        synchronized (_activeMonRequests) {
            req = _activeMonRequests.remove(groupName);
        }
        if (req==null) {
            log.warn("{}{} NOT registered", _cmId, groupName);
        } else {
            if (_pipe.isConnected()) {
                req._op = UNREGISTER;
                _pipe.sendMsg(req);
            } else {
                log.warn("{}{} NOT connected", _cmId, groupName);
            }
        }
    }



    protected void onRegistrationResponse(ClientPipe pipe) {}
    protected boolean onMsg(Msg msg) {
        return false;
    }
    protected void onDisconnect() {
        for (GroupAndInstance gi : _activeMemRequests.keySet()) {
            _memConflator.conflate(gi._groupName, gi._instance, DISCONNECT, 0, 0, true);
        }
        for (String groupName : _activeMonRequests.keySet()) {
            _monConflator.conflate(groupName, NONE, true);
        }
    }




    public void setReconnectIntervalMillis(String reconnectIntervalMillis) {
        _reconnectIntervalMillis = Utils.parseAsInt("reconnectIntervalMillis", reconnectIntervalMillis, _reconnectIntervalMillis);
    }
    public void setConnectionTimeoutMicros(String connectionTimeoutMicros) {
        _connectionTimeoutMicros = Utils.parseAsInt("connectionTimeoutMicros", connectionTimeoutMicros, _connectionTimeoutMicros);
    }
    @Override
    public void registerFtMemberListener(IFtMemberListener listener) {
        _ftMemberListeners.add(listener);
    }
    @Override
    public void unregisterFtMemberListener(IFtMemberListener listener) {
        _ftMemberListeners.remove(listener);
    }
    @Override
    public void registerFtMonitorListener(IFtMonitorListener listener) {
        _ftMonitorListeners.add(listener);
    }
    @Override
    public void unregisterFtMonitorListener(IFtMonitorListener listener) {
        _ftMonitorListeners.remove(listener);
    }


    private void sendAccumulatedFtMemberRequests() {
        synchronized (_activeMemRequests) {
            for (FtMemberMsg req : _activeMemRequests.values()) {
                _pipe.sendMsg(req);
            }
        }
    }

    private void sendAccumulatedFtMonitorRequests() {
        synchronized (_activeMonRequests) {
            for (FtMonitorMsg req : _activeMonRequests.values()) {
                _pipe.sendMsg(req);
            }
        }
    }




    public class ClientPipe extends BaseClientPipe {
        public ClientPipe(String cmId, MsgCoder coder, AppInfo myInfo, ConnInfo connInfo) {
            super(coder, myInfo, connInfo, cmId, "CollectiveClient");
            setConnectionTimeoutMicros(CollectiveClient.this._connectionTimeoutMicros);
            setReconnectInterval(CollectiveClient.this._reconnectIntervalMillis);
        }
        @Override
        public void onRegistrationResponse() {
            super.onRegistrationResponse();
            sendAccumulatedFtMemberRequests();
            sendAccumulatedFtMonitorRequests();
            try {
                CollectiveClient.this.onRegistrationResponse(ClientPipe.this);
            } catch (Exception e) {
                log.error(_cmId, e);
            }
        }
        @Override
        public void onDisconnect() {
            super.onDisconnect();
            log.info("{}ClientPipe disconnected from collective member on port {}", _cmId, _sinkInfo.getPort());
            CollectiveClient.this.onDisconnect();
        }
        @Override
        public void onMsg(Msg msg) {
            super.onMsg(msg);
            if (log.isTraceEnabled()) log.trace("{}ClientPipe received {} from collective member on port {}", _cmId, msg, _sinkInfo.getPort());
            if (msg instanceof FtMemberMsg) {
                if (log.isDebugEnabled()) log.info("{}received {} from {}", _cmId, msg, this);
                FtMemberMsg resp = (FtMemberMsg) msg;
                if (resp._type==RESPONSE) {
                    _memConflator.conflate(resp._groupName, resp._instance, resp._op, resp._sliceNo, resp._ofSlices);
                } else {
                    log.warn("{}Illegal msgType received {}", _cmId, msg);
                }
            } else if (msg instanceof FtMonitorMsg) {
                if (log.isDebugEnabled()) log.info("{}received {} from {}", _cmId, msg, this);
                FtMonitorMsg mon = (FtMonitorMsg) msg;
                _monConflator.conflate(mon._groupName, mon._actives);
            } else {
                if (!CollectiveClient.this.onMsg(msg)) log.error("{}Unhandled msg type {}", _cmId, msg);
            }
        }
        @Override
        public void sendMsg(Msg msg) {
            try {
                if (log.isDebugEnabled()) log.info("{}sending {} to {}", _cmId, msg, this);
                super.sendMsg(msg);
            } catch (IOException e) {
                log.error(_cmId, e);
            }
        }
    }
}
