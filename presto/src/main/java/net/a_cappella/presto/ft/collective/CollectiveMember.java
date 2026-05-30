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
import net.a_cappella.presto.ft.collective.events.*;
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.ft.upgrade.UpgradeManager;
import net.a_cappella.presto.ft.upgrade.VersionedParamsCache;
import net.a_cappella.presto.msg.FtMemberMsg;
import net.a_cappella.presto.msg.FtMonitorMsg;
import net.a_cappella.presto.msg.VersionedStringMsg;
import net.a_cappella.presto.msg.VoteMsg;
import org.agrona.concurrent.BackoffIdleStrategy;
import org.agrona.concurrent.IdleStrategy;
import org.jctools.queues.MpscLinkedQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.channels.NotYetConnectedException;
import java.nio.channels.SelectionKey;
import java.util.*;

import static net.a_cappella.continuo.utils.Utils.keyHash;
import static net.a_cappella.presto.ft.collective.CollectiveMember.PrimaryCalculationResult.DONT_CARE;
import static net.a_cappella.presto.ft.collective.CollectiveMember.PrimaryCalculationResult.I_BECAME_PRIMARY;
import static net.a_cappella.presto.ft.collective.CollectiveMember.PrimaryCalculationResult.NO_PRIMARY;

public class CollectiveMember {
    private static final Logger log = LoggerFactory.getLogger(CollectiveMember.class);

    public static final String VSM_NAME = "collective.cores.list";

    public enum PrimaryCalculationResult {NO_PRIMARY, I_BECAME_PRIMARY, DONT_CARE}

    // the CollectiveMember can be configured to use either First Alive or Voted Quorum leader election rules
    private static volatile boolean _useVotedQuorum = false;
    public static void setUseVotedQuorum(boolean useVotedQuorum) {
        _useVotedQuorum = useVotedQuorum;
        log.info("Using the {} leader election rule", _useVotedQuorum ? "Voted Quorum" : "First Alive");
    }
    public static boolean isUseVotedQuorum() {
        return _useVotedQuorum;
    }
    public void setUseVotedQuorumStr(String useVotedQuorum) {
        setUseVotedQuorum(net.a_cappella.continuo.utils.Utils.parseAsBoolean("useVotedQuorum", useVotedQuorum, _useVotedQuorum));
    }

    // logging
    private String _cmId;

    // message encoding / decoding
    private final MsgCoder _coder;

    // socket parameters
    private int _reconnectIntervalMillis = 200;
    private int _connectionTimeoutMillis = 200;
    private int _registrationTimeoutMillis = 500;

    // component info
    protected AppInfo _myInfo;
    protected ConnInfo _myConnInfo;

    // self aware
    private volatile boolean _iAmCore;
    private ClientPipe _myPipe = null;
    private volatile boolean _iAmPrimary = false;
    private int _quorum;
    private ClientPipe _primary = null;
    private ClientPipe _myVote = null;

    // graceful shutdown
    private volatile boolean _stop = false;

    // sink and pipes
    private ServerSink _sink;
    private List<ClientPipe> _pipes;

    // upgrade logic
    private final UpgradeManager _upgradeMgr;

    // FT logic
    private FtManager _ftManager;

    private final SinkToPipeLinkage _sinkToPipeLinkage = new SinkToPipeLinkage();

    private final Queue<FtEvent> _eventQueue = new MpscLinkedQueue();

    public CollectiveMember(MsgCoder coder, int version, String coreList) {
        _coder = coder;

        _upgradeMgr = new UpgradeManager(this, version, coreList);
    }

    public void start() {
        _stop = false;

        _eventQueue.add(new MemberStartEvent(this));

        Thread eventThread = new Thread(() -> {
            IdleStrategy idleStrategy = new BackoffIdleStrategy();
            while (!_stop) {
                FtEvent e;
                int workCount = 0;
                while ((e = _eventQueue.poll()) != null) {
                    e.apply();
                    workCount++;
                }
                idleStrategy.idle(workCount);
            }
        });
        eventThread.setName(_cmId + "EventThread");
        eventThread.start();
    }

    public void handleStartEvent() {
        _upgradeMgr.init();
        _ftManager = new FtManager(this);

        _sink = new ServerSink(_coder, _myConnInfo);
        _sink.startSink();

        _pipes = new ArrayList<>();
        for (String infoStr : _upgradeMgr.getCoreList().split(",")) {
            ClientPipe pipe = createAndStartPipe(infoStr.trim());
            _pipes.add(pipe);
        }
        calculateIAmCore(_pipes);

        log.info("{}Starting {}core CollectiveMember. All core members are {}", _cmId, _iAmCore?"":"non-", _pipes);

        // wait until all pipes are started
        while (!allPipesStarted()) Utils.sleep(20);

        evalLeader();
    }

    public ClientPipe createAndStartPipe(String infoStr) {
        AppInfo appInfo = new AppInfo(infoStr);
        ConnInfo connInfo = new ConnInfo(infoStr);
        ClientPipe pipe = new ClientPipe(_coder, _myInfo, _myConnInfo, appInfo, connInfo, _cmId);
        pipe.setConnectionTimeoutMillis(_connectionTimeoutMillis);
        pipe.setReconnectInterval(_reconnectIntervalMillis);
        pipe.setRegistrationTimeoutMillis(_registrationTimeoutMillis);
        if (!pipe._myPipe) {
            pipe.startPipe();
        } else { // that's me and I am up
            pipe.setStatus(MemberStatusEnum.UP);
        }
        return pipe;
    }

    public void stop() {
        _eventQueue.add(new MemberStopEvent(this));
    }
    public void handleStopEvent() {
        log.info("{}Stopping CollectiveMember", _cmId);
        _stop = true;
        _sink.stopSink();
        _sinkToPipeLinkage.removeAllLinkages();
        for (ClientPipe pipe : _pipes) {
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

    public List<ClientPipe> getPipes() {
        return _pipes;
    }

    public void setPipes(List<ClientPipe> pipes) {
        _pipes = pipes;
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
    public void setConnectionTimeoutMillis(String connectionTimeoutMillis) {
        try {
            _connectionTimeoutMillis = Integer.parseInt(connectionTimeoutMillis);
        } catch (NumberFormatException x) {
            log.warn("Invalid connectionTimeoutMillis value {}. Defaulting to {}", connectionTimeoutMillis, _connectionTimeoutMillis);
        }
    }
    public void setRegistrationTimeoutMillis(String registrationTimeoutMillis) {
        try {
            _registrationTimeoutMillis = Integer.parseInt(registrationTimeoutMillis);
        } catch (NumberFormatException x) {
            log.warn("Invalid registrationTimeoutMillis value {}. Defaulting to {}", registrationTimeoutMillis, _registrationTimeoutMillis);
        }
    }

    public void setVersionedParamsCache(VersionedParamsCache versionedParamsCache) {
        _upgradeMgr.setVersionedParamsCache(versionedParamsCache);
    }

    public boolean isCoreUp() {
        for (int i = 0; i < _pipes.size(); i++) {
            ClientPipe pipe = _pipes.get(i);
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
        _sink.sendMsgToAllMembers(msg);
    }

    public boolean sendMsgToOtherCores(Msg msg) {
        boolean sent = false;
        for (ClientPipe pipe : _pipes) {
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
        for (ClientPipe pipe : _pipes) {
            if (!pipe._myPipe) {
                result &= (pipe.isStarted() || pipe.isConnected() || pipe.isDisconnected());
            }
        }
        return result;
    }

    private boolean allPipesStopped() {
        boolean result = true;
        for (ClientPipe pipe : _pipes) {
            if (!pipe._myPipe) {
                result &= pipe.isStopped();
            }
        }
        return result;
    }

    private void handleUpgradeMessage(VersionedStringMsg vsm, String source) {
        if (VSM_NAME.equals(vsm._name) && vsm._version>_upgradeMgr.getVersion()) {
            log.info("{}Got UPGRADE message {} from {}", _cmId, vsm, source);
            sendMsgToAllMembers(vsm); // send the upgrade message to all connected members (core or non core)

            _upgradeMgr.upgrade(vsm);

            evalLeader();
            // wait until all pipes are started
            while (!allPipesStarted()) Utils.sleep(20);
        }
    }

    public void calculateIAmCore(List<ClientPipe> pipes) {
        boolean iAmCore = false;
        ClientPipe myPipe = null;
        for (ClientPipe pipe : pipes) {
            if (pipe._myPipe) {
                iAmCore = true;
                myPipe = pipe;
                break;
            }
        }
        _iAmCore = iAmCore;
        _myPipe = myPipe;
        _quorum = (int) Math.floor(pipes.size() / 2) + 1;
        log.info("{} quorum={}", _cmId, _quorum);
    }

    private PrimaryCalculationResult evalLeader() {
        if (_useVotedQuorum) {
            return calculateVotes();
        } else {
            return calculatePrimary();
        }
    }

    private PrimaryCalculationResult calculatePrimary() {
        if (_stop) {
            log.info("{}calculatePrimary already stopped => not primary", _cmId);
            _iAmPrimary = false;
            return DONT_CARE;
        }
        List<ClientPipe> pipes = _pipes;
        // checking that all pipes are up
        for (int i = 0; i < pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            if (pipe.getStatus()==MemberStatusEnum.UP) break; // first UP and there have been no IDKs before
            if (pipe.getStatus()==MemberStatusEnum.IDK) {
                log.info("{}calculatePrimary {} =>  still not certain...", _cmId, _pipes);
                // need to wait until I am certain; otherwise there could be overlap
                resetPrimary(pipes, 0);
                _iAmPrimary = false;
                return DONT_CARE;
            }
        }
        // calculate primary
        for (int i = 0; i < pipes.size(); i++) {
            ClientPipe pipe = pipes.get(i);
            if (pipe.getStatus() == MemberStatusEnum.UP) {
                if (pipe.isPrimary()) { // i is already primary
                    if (pipe._myPipe) {
                        log.info("{}calculatePrimary {} ===> I am still primary!!!", _cmId, pipes);
                    } else {
                        log.info("{}calculatePrimary {} {} => {} is still primary", _cmId, _myInfo, pipes, pipe);
                    }
                    return DONT_CARE;
                }
                setPrimary(pipes, i);
                if (pipe._myPipe) {
                    log.info("{}calculatePrimary {} ===> I am primary!!!", _cmId, pipes);
                    _iAmPrimary = true;
                    return I_BECAME_PRIMARY;
                } else {
                    log.info("{}calculatePrimary {} => {} is primary", _cmId, pipes, pipe);
                    _iAmPrimary = false;
                    return DONT_CARE;
                }
            } else {
                pipe.setPrimary(false);
            }
        }
        log.info("{}calculatePrimary {} => no primary is up atm...", _cmId, pipes);
        _iAmPrimary = false;
        return NO_PRIMARY;
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

    private PrimaryCalculationResult calculateVotes() {
        if (_stop) {
            log.info("{}calculateVotes already stopped => not primary", _cmId);
            _iAmPrimary = false;
            return DONT_CARE;
        }
        if (_iAmCore) {
            boolean first = true;
            for (int i = 0; i < _pipes.size(); i++) {
                ClientPipe pipe = _pipes.get(i);
                if (pipe.getStatus() == MemberStatusEnum.UP) {
                    // I am voting for the first member that is UP
                    if (first) {
                        first = false;
                        if (_myVote != pipe) {
                            _myVote = pipe;
                            _myPipe._myVote = pipe;
                            sendMsgToAllMembers(new VoteMsg(_myPipe._appInfo, pipe._appInfo));
                        }
                    }
                } else {
                    pipe._myVote = null;
                }
            }
        }
        PrimaryCalculationResult result = calculateQuorumPrimary("calculateVotes");
        if (result == NO_PRIMARY) {
            _iAmPrimary = false;
        }
        _ftManager.onPrimaryCalculationResult(result);
        return result;
    }

    private void handleVoteMessage(VoteMsg vote) {
        // cast vote
        ClientPipe voterPipe = findPipe(vote.ofMember());
        voterPipe._myVote = findPipe(vote.forMember());
        // tally votes
        PrimaryCalculationResult result = calculateQuorumPrimary("handleVoteMessage");
        if (result == NO_PRIMARY) {
            _iAmPrimary = false;
        }
        _ftManager.onPrimaryCalculationResult(result);
    }

    private PrimaryCalculationResult calculateQuorumPrimary(String method) {
        // start with blank slate
        for (ClientPipe pipe : _pipes) {
            pipe._myVoteCnt = 0;
        }
        // count votes
        for (ClientPipe pipe : _pipes) {
            ClientPipe myVote = pipe._myVote;
            if (myVote != null) { // can be null if not connected
                myVote._myVoteCnt++;
            }
        }
        if (_myVote == null || !_iAmCore) {
            log.info("{}{} => {}", _cmId, method, _pipes);
        } else {
            log.info("{}{} => I'm voting {} {}", _cmId, method, _myVote._appInfo, _pipes);
        }
        if (quorumPrimaryHasChanged()) {
            if (_primary == null) {
                log.info("{}{} ===> no primary...", _cmId, method);
                return NO_PRIMARY;
            } else if (_primary == _myPipe) {
                log.info("{}{} ===> I became primary...", _cmId, method);
                return I_BECAME_PRIMARY;
            } else {
                log.info("{}{} ===> {} became primary...", _cmId, method, _primary._appInfo);
            }
        }
        return DONT_CARE;
    }

    private boolean quorumPrimaryHasChanged() {
        // identify winner
        ClientPipe newPrimary = null;
        for (ClientPipe pipe : _pipes) {
            if (pipe._myVoteCnt >= _quorum) {
                newPrimary = pipe;
                pipe._primary = true;
                _iAmPrimary = pipe._myPipe;
            } else {
                pipe._primary = false;
            }
        }
        boolean change = _primary != newPrimary;
        _primary = newPrimary;
        return change;
    }

    private ClientPipe findPipe(AppInfo appInfo) {
        for (ClientPipe pipe : _pipes) {
            if (pipe._appInfo.equals(appInfo)) {
                return pipe;
            }
        }
        return null; // should not get here though
    }

    public void addSinkToPipeLinkage(ConnInfo connInfo, ClientPipe pipe) {
        _sinkToPipeLinkage.addSinkToPipeLinkage(connInfo, pipe);
    }
    public void removeSinkToPipeLinkage(ConnInfo connInfo) {
        _sinkToPipeLinkage.removeSinkToPipeLinkage(connInfo);
    }



    @VisibleForTesting
    public boolean verifyStatuses(MemberStatusEnum[] statuses) throws RuntimeException {
        if (statuses.length != _pipes.size()) {
            return false;
        }
        for (int i = 0; i < _pipes.size(); i++) {
            if (_pipes.get(i).getStatus() != statuses[i]) return false;
        }
        return true;
    }

    public MemberStatusEnum[] getStatuses() {
        MemberStatusEnum[] statuses = new MemberStatusEnum[_pipes.size()];
        for (int i = 0; i < _pipes.size(); i++) {
            statuses[i] = _pipes.get(i).getStatus();
        }
        return statuses;
    }




    public class ServerSink extends BaseServerSink {
        private Set<SelectionKey> _memberKeys = new HashSet<>();

        public ServerSink(MsgCoder coder, ConnInfo connInfo) {
            super(coder, connInfo.getPort(), connInfo.getPort()+"");
        }

        @Override
        public void onClientConnect(SelectionKey key, RegistrationRequest reg) {
            _eventQueue.add(new SinkConnectEvent(this, key, reg.clone()));
        }
        public void handlePipeConnect(SelectionKey key, RegistrationRequest reg) {
            // send _coreMembersListMsg only to collective members (not to clients)
            if (reg.isFromDaemon()) {
                _memberKeys.add(key);
                log.info("{}serverSink.onClientConnect {}({}) {} => {}", _cmId, keyHash(key), _memberKeys.size(), reg, _upgradeMgr.getCoreMembersListMsg());
                sendMsg(key, _upgradeMgr.getCoreMembersListMsg()); // TODO replicate my core.list back to pipe
                if (_myVote != null) {
                    sendMsg(key, new VoteMsg(_myPipe._appInfo, _myVote._appInfo));
                }
            }

            if (_sinkToPipeLinkage.addSinkToPipeLinkage(key, reg)) {
                evalLeader();
            }
        }

        @Override
        public void onClientDisconnect(SelectionKey key) {
            _eventQueue.add(new SinkDisconnectEvent(this, key));
        }
        public void handlePipeDisconnect(SelectionKey key) {
            log.info("{}serverSink.onClientDisconnect {}", _cmId, keyHash(key));
            _memberKeys.remove(key);

            if (_sinkToPipeLinkage.removeSinkToPipeLinkage(key)) {
                evalLeader();
            }

            _ftManager.sinkOnPipeDisconnect(key);
            CollectiveMember.this.onClientDisconnect(key);
        }

        @Override
        public void onMsg(SelectionKey key, Msg msg) {
            _eventQueue.add(new SinkMsgEvent(this, key, msg.clone()));
        }
        public void handlePipeMsg(SelectionKey key, Msg msg) {
            if (log.isDebugEnabled()) log.info("{}ServerSink received {} from {}", _cmId, msg, keyHash(key));
            if (msg instanceof FtMemberMsg) { // REQUESTS
                _ftManager.sinkOnFtMsgFromPipe(key, (FtMemberMsg) msg);
            } else if (msg instanceof FtMonitorMsg) { // REQUESTS
                _ftManager.sinkOnFtMsgFromPipe(key, (FtMonitorMsg) msg);
            } else if (msg instanceof VersionedStringMsg) {
                handleUpgradeMessage((VersionedStringMsg) msg, keyHash(key));
            } else {
                CollectiveMember.this.onMsg(key, msg);
            }
        }

        @Override
        public void sendMsg(SelectionKey key, Msg msg) {
            super.sendMsg(key, msg);
            if (msg instanceof FtMemberMsg || msg instanceof FtMonitorMsg) {
                if (log.isDebugEnabled()) log.info("{}ServerSink sent {} to {}", _cmId, msg, keyHash(key));
            }
        }

        public void sendMsgToAllMembers(Msg msg) {
            for (SelectionKey key : _memberKeys) {
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
        private ClientPipe _myVote = null;
        private int _myVoteCnt;

        public ClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo myConnInfo, AppInfo appInfo, ConnInfo connInfo, String cmId) {
            super(coder, myInfo, connInfo, cmId, connInfo.getPort()+"");
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
            _eventQueue.add(new PipeConnectEvent(this));
        }
        public void handleSinkConnect() {
            setPipeConnectionStatus(MemberStatusEnum.UP);
            evalLeader();
            try {
                sendMsg(_upgradeMgr.getCoreMembersListMsg()); // TODO replicate my core.list back to sink
                CollectiveMember.this.onRegistrationResponse(ClientPipe.this);
            } catch (Exception e) {
                log.error(_cmId, e);
            }
            _ftManager.pipeOnSinkConnect(this);
        }

        @Override
        public void onDisconnect() {
            super.onDisconnect();
            _eventQueue.add(new PipeDisconnectEvent(this));
        }
        public void handleSinkDisconnect() {
            setPipeConnectionStatus(MemberStatusEnum.DOWN);
            _myVote = null;
            PrimaryCalculationResult result = evalLeader();
            _ftManager.pipeOnSinkDisconnect(this, isCoreUp(), result);
            CollectiveMember.this.onClientDisconnect(this);
        }

        @Override
        public void onMsg(Msg msg) {
            super.onMsg(msg);
            _eventQueue.add(new PipeMsgEvent(this, msg.clone()));
        }
        public void handleSinkMsg(Msg msg) {
            if (msg instanceof VersionedStringMsg) {
                handleUpgradeMessage((VersionedStringMsg) msg, _connInfo.toString());
            } else {
                if (log.isDebugEnabled()) log.info("{}ClientPipe received {} from {}@{}", _cmId, msg, _appInfo, _connInfo.getPort());
                if (msg instanceof FtMemberMsg) {
                    _ftManager.pipeOnFtMsgFromSink((FtMemberMsg) msg);
                } else if (msg instanceof FtMonitorMsg) {
                    _ftManager.pipeOnFtMsgFromSink((FtMonitorMsg) msg);
                } else if (msg instanceof VoteMsg) {
                    handleVoteMessage((VoteMsg) msg);
                } else {
                    try {
                        CollectiveMember.this.onMsg(this, msg);
                    } catch (Exception e) {
                        log.error(_cmId+"onMsg("+msg+")", e);
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
            return _memberStatus.getStatus(CollectiveMember.this._iAmCore);
        }

        public String toString() {
            return "{"+((_myPipe) ? "* " : "")+_appInfo+"@"+_connInfo.getPort()+" "+_memberStatus+" "+((_myVote==null) ? null : _myVote._appInfo)+" "+_myVoteCnt+"}";
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

            for (ClientPipe pipe : _pipes) {
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
