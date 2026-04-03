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

import com.google.common.annotations.VisibleForTesting;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.msg.RegistrationRequest;
import net.a_cappella.continuo.socket.BaseClientPipe;
import net.a_cappella.continuo.socket.BaseServerSink;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ft.beans.MemberStatus;
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.ft.upgrade.UpgradeManager;
import net.a_cappella.presto.ft.upgrade.VersionedParamsCache;
import net.a_cappella.presto.msg.FtMemberMsg;
import net.a_cappella.presto.msg.FtMonitorMsg;
import net.a_cappella.presto.msg.VersionedStringMsg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.channels.NotYetConnectedException;
import java.nio.channels.SelectionKey;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class CollectiveMember {
    private static final Logger log = LoggerFactory.getLogger(CollectiveMember.class);

    public static final String VSM_NAME = "collective.cores.list";

    // logging
    private String _cmId;

    // message encoding / decoding
    private final MsgCoder _coder;

    // socket parameters
    private int _reconnectIntervalMillis = 200;
    private int _connectionTimeoutMicros = 200;

    // component info
    protected AppInfo _myInfo;
    protected ConnInfo _myConnInfo;

    // self aware
    private volatile boolean _iAmCore;
    private volatile boolean _iAmPrimary = false;

    // graceful shutdown
    private volatile boolean _stop = false;

    // sink and pipes
    private ServerSink _sink;
    private final AtomicReference<List<ClientPipe>> _pipes = new AtomicReference<>();

    // upgrade logic
    private final UpgradeManager _upgradeMgr;

    // FT logic
    private FtManager _ftManager;

    private final SinkToPipeLinkage _sinkToPipeLinkage = new SinkToPipeLinkage();

    public CollectiveMember(MsgCoder coder, int version, String coreList) {
        _coder = coder;

        _upgradeMgr = new UpgradeManager(this, version, coreList);
    }

    public synchronized void start() {
        _stop = false;

        _sink = new ServerSink(_coder, _myConnInfo);
        _sink.startSink();

        List<ClientPipe> pipes = new ArrayList<>();
        for (String infoStr : _upgradeMgr.getCoreList().split(",")) {
            ClientPipe pipe = createAndStartPipe(infoStr.trim());
            pipes.add(pipe);
        }
        calculateIAmCore(pipes);
        _pipes.set(pipes);

        _upgradeMgr.init();

        log.info("{}Starting {}core CollectiveMember. All core members are {}", _cmId, !_iAmCore?"non-":"", _pipes);
        log.info("{}Initial core list is {}", _cmId, _upgradeMgr.getCoreMembersListMsg());

        _ftManager = new FtManager(this);

        // wait until all pipes are started
        while (!allPipesStarted()) Utils.sleep(20);

        calculatePrimary();
    }

    public ClientPipe createAndStartPipe(String infoStr) {
        AppInfo appInfo = new AppInfo(infoStr);
        ConnInfo connInfo = new ConnInfo(infoStr);
        ClientPipe pipe = new ClientPipe(_coder, _myInfo, _myConnInfo, appInfo, connInfo, _cmId);
        pipe.setConnectionTimeoutMicros(_connectionTimeoutMicros);
        pipe.setReconnectInterval(_reconnectIntervalMillis);
        if (!pipe._myPipe) {
            pipe.startPipe();
        } else { // that's me and I am up
            pipe.setStatus(MemberStatusEnum.UP);
        }
        return pipe;
    }

    public void stop() {
        log.info("{}Stopping CollectiveMember", _cmId);
        _stop = true;
        _sink.stopSink();
        _sinkToPipeLinkage.removeAllLinkages();

        for (ClientPipe pipe : _pipes.get()) {
            if (!pipe._myPipe) {
                pipe.stopPipe();
            }
        }
    }

    public String getCmId() {
        return _cmId;
    }

    public boolean iAmCore() {
        return _iAmCore;
    }

    public boolean iAmPrimary() {
        return _iAmPrimary;
    }

    public boolean isStarted() {
        return _sink.isStarted() && allPipesStarted();
    }

    public boolean isStopped() {
        return _sink.isStopped() && allPipesStopped();
    }

    public boolean isUpgraded(int version) {
        return isStarted() && _upgradeMgr.getVersion() == version;
    }

    public ServerSink getSink() {
        return _sink;
    }

    public AtomicReference<List<ClientPipe>> getPipes() {
        return _pipes;
    }

    public void setMyInfo(String myInfoStr) {
        _myInfo = new AppInfo(myInfoStr);
        _myConnInfo = new ConnInfo(myInfoStr);
        _cmId = _myConnInfo.getPort() + " ";
    }

    public void setReconnectIntervalMillis(String reconnectIntervalMillis) {
        try {
            _reconnectIntervalMillis = Integer.parseInt(reconnectIntervalMillis);
        } catch (NumberFormatException x) {
            log.warn("Invalid reconnectIntervalMillis value {}. Defaulting to {}", reconnectIntervalMillis, _reconnectIntervalMillis);
        }
    }
    public void setConnectionTimeoutMicros(String connectionTimeoutMicros) {
        try {
            _connectionTimeoutMicros = Integer.parseInt(connectionTimeoutMicros);
        } catch (NumberFormatException x) {
            log.warn("Invalid connectionTimeoutMicros value {}. Defaulting to {}", connectionTimeoutMicros, _connectionTimeoutMicros);
        }
    }

    public void setVersionedParamsCache(VersionedParamsCache versionedParamsCache) {
        _upgradeMgr.setVersionedParamsCache(versionedParamsCache);
    }

    public boolean isCoreUp() {
        List<ClientPipe> pipes = _pipes.get();
        for (int i=0; i<pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            if (pipe.getStatus()==MemberStatusEnum.UP) {
                return true;
            }
        }
        return false;
    }

    public void sendMsg(SelectionKey key, Msg msg) {
        _sink.sendMsg(key, msg);
    }

    public void sendMsgToAllMembers(Msg msg) {
        _sink.sendMsgToAllDaemons(msg);
    }

    public boolean sendMsgToOtherCores(Msg msg) {
        boolean sent = false;
        for (ClientPipe pipe : _pipes.get()) {
            if (!pipe._myPipe) {
                sent |= sendMsgToCore(msg, pipe);
            }
        }
        return sent;
    }

    public boolean sendMsgToCore(Msg msg, ClientPipe pipe) {
        boolean sent = false;
        if (pipe.getPipeConnectionStatus()==MemberStatusEnum.UP) {
            try {
                pipe.sendMsg(msg);
                sent = true;
            } catch (IOException x) {
                log.info("{}Got '{}' while sending {} to {}", _cmId, x.getMessage(), msg, pipe);
            } catch (NotYetConnectedException x) {
                log.info("{}Got 'NotYetConnected' while sending {} to {}", _cmId, msg, pipe);
            }
        }
        return sent;
    }

    protected void onRegistrationResponse(ClientPipe pipe) throws Exception {}
    protected void onMsg(ClientPipe pipe, Msg msg) throws Exception {}
    protected void onMsg(SelectionKey key, Msg msg) {}
    protected void onClientDisconnect(SelectionKey key) {}
    protected void onClientDisconnect(ClientPipe pipe) {}
    protected void onClientStopped(ClientPipe pipe) {}



    private boolean allPipesStarted() {
        boolean result = true;
        for (ClientPipe pipe : _pipes.get()) {
            if (!pipe._myPipe) {
                result &= (pipe.isStarted() || pipe.isConnected() || pipe.isDisconnected());
            }
        }
        return result;
    }

    private boolean allPipesStopped() {
        boolean result = true;
        for (ClientPipe pipe : _pipes.get()) {
            if (!pipe._myPipe) {
                result &= pipe.isStopped();
            }
        }
        return result;
    }

    private synchronized void handleUpgradeMessage(VersionedStringMsg vsm, String source) {
        if (VSM_NAME.equals(vsm._name) && vsm._version>_upgradeMgr.getVersion()) {
            log.info("{}Got UPGRADE message {} from {}", _cmId, vsm, source);
            sendMsgToAllMembers(vsm); // send the upgrade message to all connected members (core or non core)

            log.info("{}Upgrading {}core CollectiveMember. All v.{} core members are {}", _cmId, !_iAmCore?"non-":"", _upgradeMgr.getVersion(), _pipes);
            _upgradeMgr.upgrade(vsm);
            log.info("{}   ... to {}core CollectiveMember. All v.{} core members are {}", _cmId, !_iAmCore?"non-":"", _upgradeMgr.getVersion(), _pipes);

            calculatePrimary();
            // wait until all pipes are started
            while (!allPipesStarted()) Utils.sleep(20);
        }
    }

    public void calculateIAmCore(List<ClientPipe> pipes) {
        boolean iAmCore = false;
        for (ClientPipe pipe : pipes) {
            if (pipe._myPipe) {
                iAmCore = true;
                break;
            }
        }
        for (ClientPipe pipe : pipes) {
            pipe._iAmCore = iAmCore;
        }
        _iAmCore = iAmCore;
    }

    private boolean calculatePrimary() {
        List<ClientPipe> pipes = _pipes.get();
        if (_stop) {
            log.info("{}calculatePrimary already stopped => not primary", _cmId);
            _iAmPrimary = false;
            return false;
        }
        for (int i=0; i<pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            if (pipe.getStatus()==MemberStatusEnum.UP) break; // first UP and there have been no IDKs before
            if (pipe.getStatus()==MemberStatusEnum.IDK) {
                log.info("{}calculatePrimary {} =>  still not certain...", _cmId, pipes);
                // need to wait until I am certain; otherwise there could be overlap
                resetPrimary(pipes, 0);
                _iAmPrimary = false;
                return false;
            }
        }
        for (int i=0; i<pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            if (pipe.getStatus() == MemberStatusEnum.UP) {
                if (pipe.isPrimary()) { // i is already primary
                    if (pipe._myPipe) {
                        log.info("{}calculatePrimary {} ===> I am still primary!!!", _cmId, pipes);
                        return false;
                    } else {
                        log.info("{}calculatePrimary {} {} => {} is still primary", _cmId, _myInfo, pipes, pipe);
                        return false;
                    }
                }
                setPrimary(pipes, i);
                if (pipe._myPipe) {
                    log.info("{}calculatePrimary {} ===> I am primary!!!", _cmId, pipes);
                    _iAmPrimary = true;
                    return true; // just became primary
                } else {
                    log.info("{}calculatePrimary {} => {} is primary", _cmId, pipes, pipe);
                    _iAmPrimary = false;
                    return false;
                }
            } else {
                pipe.setPrimary(false);
            }
        }
        log.info("{}calculatePrimary {} => no primary is up atm...", _cmId, pipes);
        _iAmPrimary = false;
        return false;
    }

    private void setPrimary(List<ClientPipe> pipes, int atIndex) {
        ClientPipe pipe = pipes.get(atIndex);
        pipe.setPrimary(true);
        for (int i=atIndex+1; i<pipes.size(); i++) {
            pipe = pipes.get(i);
            pipe.setPrimary(false);
        }
    }
    private void resetPrimary(List<ClientPipe> pipes, int fromIndex) {
        for (int i=fromIndex; i<pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            pipe.setPrimary(false);
        }
    }

    public void addSinkToPipeLinkage(ConnInfo connInfo, ClientPipe pipe) {
        _sinkToPipeLinkage.addSinkToPipeLinkage(connInfo, pipe);
    }
    public void removeSinkToPipeLinkage(ConnInfo connInfo) {
        _sinkToPipeLinkage.removeSinkToPipeLinkage(connInfo);
    }



    @VisibleForTesting
    public boolean iAmCore(boolean expected) {
        return _iAmCore == expected;
    }

    @VisibleForTesting
    public boolean verifyStatuses(MemberStatusEnum[] statuses) throws RuntimeException {
        List<ClientPipe> pipes = _pipes.get();
        if (statuses.length != pipes.size()) {
            return false;
        }
        for (int i=0; i<pipes.size(); i++) {
            if (pipes.get(i).getStatus() != statuses[i]) return false;
        }
        return true;
    }





    public class ServerSink extends BaseServerSink {
        private Set<SelectionKey> _daemonKeys = new HashSet<>();

        public ServerSink(MsgCoder coder, ConnInfo connInfo) {
            super(coder, connInfo.getPort(), connInfo.getPort()+"");
        }

        @Override
        public void onClientConnect(SelectionKey key, RegistrationRequest reg) {
            synchronized (CollectiveMember.this) {
                // send _coreMembersListMsg only to collective members (not to clients)
                if (reg.isFromDaemon()) {
                    _daemonKeys.add(key);
                    log.info("{}serverSink.onClientConnect {} back to {}", _cmId, _upgradeMgr.getCoreMembersListMsg(), reg);
                    sendMsg(key, _upgradeMgr.getCoreMembersListMsg()); // TODO replicate my core.list back to pipe
                }

                if (_sinkToPipeLinkage.addSinkToPipeLinkage(key, reg)) calculatePrimary();
            }
        }

//		@Override
//		public void onClientDisconnect(SelectionKey key, RegistrationRequest reg) {
//			log.info("{}serverSink.onClientDisconnect {} <-> {}", _cmId, keyHash(key), reg.getAppInfo());
//			synchronized (CollectiveMember.this) {
//				_daemonKeys.remove(key);
//				if (_sinkToPipeLinkage.removeSinkToPipeLinkage(key)) calculatePrimary();
//
//				_ftManager.sinkOnPipeDisconnect(key);
//				CollectiveMember.this.onClientDisconnect(key);
//			}
//		}

        @Override
        public void onClientDisconnect(SelectionKey key) {
            log.info("{}serverSink.onClientDisconnect {}", _cmId, keyHash(key));
            synchronized (CollectiveMember.this) {
                _daemonKeys.remove(key);
                if (_sinkToPipeLinkage.removeSinkToPipeLinkage(key)) calculatePrimary();

                _ftManager.sinkOnPipeDisconnect(key);
                CollectiveMember.this.onClientDisconnect(key);
            }
        }

        public void onMsg(SelectionKey key, Msg msg) {
            if (log.isDebugEnabled()) log.info("{}ServerSink received {} from {}", _cmId, msg, keyHash(key));
            synchronized (CollectiveMember.this) { // TODO should all be synchronized?
                if (msg instanceof FtMemberMsg) {
                    _ftManager.sinkOnFtMsgFromPipe(key, new FtMemberMsg((FtMemberMsg) msg));
                    return;
                } else if (msg instanceof FtMonitorMsg) {
                    _ftManager.sinkOnFtMsgFromPipe(key, new FtMonitorMsg((FtMonitorMsg) msg));
                    return;
                } else if (msg instanceof VersionedStringMsg) {
                    handleUpgradeMessage(new VersionedStringMsg((VersionedStringMsg) msg), keyHash(key));
                    return;
                }
                CollectiveMember.this.onMsg(key, msg);
            }
        }

        public void sendMsg(SelectionKey key, Msg msg) {
            super.sendMsg(key, msg);
            if (msg instanceof FtMemberMsg || msg instanceof FtMonitorMsg) {
                if (log.isDebugEnabled()) log.info("{}ServerSink sent {} to {}", _cmId, msg, keyHash(key));
            }
        }

        public void sendMsgToAllDaemons(Msg msg) {
            for (SelectionKey key : _daemonKeys) {
                try {
                    super.sendMsg(key, msg);
                } catch (Exception x) {
                    log.error("Could not send message to "+keyHash(key), x);
                }
            }
        }
    }

    public class ClientPipe extends BaseClientPipe {
        private final AppInfo _appInfo;
        private final ConnInfo _connInfo;
        private final boolean _myPipe;
        private MemberStatus _memberStatus = new MemberStatus();
        private boolean _primary = false;
        private boolean _iAmCore = false;

        public ClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo myConnInfo, AppInfo appInfo, ConnInfo connInfo, String cmId) {
            super(coder, myInfo, connInfo, cmId, "CollectiveMember");
            setDaemonInfo(myConnInfo);
            _appInfo = appInfo;
            _connInfo = connInfo;
            if (myConnInfo.equals(connInfo) && !myInfo.equals(appInfo)) {
                log.error("\n\nMisconfiguration!!! myInfo.app='{}' != '{}'=[my entry ({}) in collective.cores.list].app\n", myInfo, appInfo, myConnInfo);
                System.exit(1);
            }
            _myPipe = _appInfo.equals(myInfo);
        }

        public ConnInfo getConnInfo() {
            return _connInfo;
        }

        @Override
        public void onRegistrationResponse() {
            super.onRegistrationResponse();
            synchronized (CollectiveMember.this) {
                setPipeConnectionStatus(MemberStatusEnum.UP);
                calculatePrimary();
                try {
                    sendMsg(_upgradeMgr.getCoreMembersListMsg()); // TODO replicate my core.list back to sink
                    CollectiveMember.this.onRegistrationResponse(ClientPipe.this);
                } catch (Exception e) {
                    log.error(_cmId, e);
                }
                _ftManager.pipeOnSinkConnect(this);
            }
        }
        @Override
        public void onDisconnect() {
            super.onDisconnect();
            synchronized (CollectiveMember.this) {
                setPipeConnectionStatus(MemberStatusEnum.DOWN);
                boolean becamePrimary = calculatePrimary();
                _ftManager.pipeOnSinkDisconnect(this, isCoreUp(), becamePrimary);
            }
            CollectiveMember.this.onClientDisconnect(this);
        }
        @Override
        public void onMsg(Msg msg) {
            super.onMsg(msg);
            if (msg instanceof VersionedStringMsg) {
                handleUpgradeMessage((VersionedStringMsg) msg, _connInfo.toString());
            } else {
                if (log.isDebugEnabled()) log.info("{}ClientPipe received {} from {}", _cmId, msg, this);
                synchronized (CollectiveMember.this) {
                    if (msg instanceof FtMemberMsg) {
                        _ftManager.pipeOnFtMsgFromSink(new FtMemberMsg((FtMemberMsg) msg));
                    } else if (msg instanceof FtMonitorMsg) {
                        _ftManager.pipeOnFtMsgFromSink(new FtMonitorMsg((FtMonitorMsg) msg));
                    } else {
                        try {
                            CollectiveMember.this.onMsg(this, msg);
                        } catch (Exception e) {
                            log.error(_cmId+"onMsg("+msg+")", e);
                        }
                    }
                }
            }
        }
        @Override
        public void sendMsg(Msg msg) throws IOException {
            if (msg instanceof FtMemberMsg) {
                if (log.isDebugEnabled()) log.info("{}ClientPipe sending {} to {}", _cmId, msg, this);
            }
            super.sendMsg(msg);
        }

        public boolean isPrimary() {
            return _primary;
        }
        public void setPrimary(boolean primary) {
            _primary = primary;
        }

        public void setStatus(MemberStatusEnum status) {
            _memberStatus.setStatus(status);
        }
        public void setSinkConnectionStatus(MemberStatusEnum status) {
            _memberStatus.setSinkConnectionStatus(status);
        }
        public MemberStatusEnum getSinkConnectionStatus() {
            return _memberStatus.getSinkConnectionStatus();
        }
        public void setPipeConnectionStatus(MemberStatusEnum status) {
            _memberStatus.setPipeConnectionStatus(status);
        }
        public MemberStatusEnum getPipeConnectionStatus() {
            return _memberStatus.getPipeConnectionStatus();
        }
        public MemberStatusEnum getStatus() {
            return _memberStatus.getStatus(_iAmCore);
        }

        public String toString() {
            return "{"+_appInfo+"@"+_connInfo.getPort()+" "+_memberStatus+"}";
        }
    }


    private class SinkToPipeLinkage {

        private final Map<SelectionKey, ClientPipe> _sinkToPipeMap = new HashMap<>();

        private void addSinkToPipeLinkage(ConnInfo connInfo, ClientPipe pipe) {
            SelectionKey key = _sink.getSelKeyForConn(connInfo);
            if (key != null) {
                pipe.setSinkConnectionStatus(MemberStatusEnum.UP);
                _sinkToPipeMap.put(key, pipe);
                log.info("{}added linkage {} => {}", _cmId, keyHash(key), pipe);
            }
        }

        private boolean addSinkToPipeLinkage(SelectionKey key, RegistrationRequest reg) {
            log.info(_cmId+keyHash(key)+" <=> "+reg.getKey());

            for (ClientPipe pipe : _pipes.get()) {
                if (pipe._connInfo.equals(reg.getMyConnInfo())) {
                    pipe.setSinkConnectionStatus(MemberStatusEnum.UP);
                    _sinkToPipeMap.put(key, pipe);
                    log.info("{}added linkage {} => {}", _cmId, keyHash(key), pipe);
                    return true;
                }
            }

            return false;
        }

        private void removeAllLinkages() {
            for (SelectionKey key : _sink.getSelectionKeys()) {
                removeSinkToPipeLinkage(key);
            }
        }

        private void removeSinkToPipeLinkage(ConnInfo connInfo) {
            SelectionKey key = _sink.getSelKeyForConn(connInfo);
            if (key != null) removeSinkToPipeLinkage(key);
        }

        private boolean removeSinkToPipeLinkage(SelectionKey key) {
            ClientPipe pipe = _sinkToPipeMap.remove(key);
            if (pipe != null) { // the pipe was disconnected
                // if I am no longer core then will rely on the pipe to update the state
                pipe.setSinkConnectionStatus(MemberStatusEnum.DOWN);
                log.info("{}removed linkage {} => {}", _cmId, keyHash(key), pipe);
                return true;
            }
            return false;
        }

        public String toString() {
            StringBuilder sb = new StringBuilder();
            sb.append("SinkToPipeLinkage { ");
            for (Map.Entry<SelectionKey, ClientPipe> entry : _sinkToPipeMap.entrySet()) {
                sb.append(keyHash(entry.getKey())).append('=').append(entry.getValue()).append(' ');
            }
            sb.append('}');
            return sb.toString();
        }
    }
}
