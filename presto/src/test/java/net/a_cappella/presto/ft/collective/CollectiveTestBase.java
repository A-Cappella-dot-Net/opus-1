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

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.*;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.ft.upgrade.VersionedParamsCache;
import net.a_cappella.presto.msg.*;
import net.a_cappella.presto.obj.ObjImpl;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BiConsumer;
import java.util.function.BiPredicate;
import java.util.function.BooleanSupplier;
import java.util.function.Predicate;

import static net.a_cappella.continuo.utils.Utils.sleep;
import static org.junit.jupiter.api.Assertions.*;

public abstract class CollectiveTestBase {
    protected static Logger log = LoggerFactory.getLogger(CollectiveTestBase.class);

    protected static final int INTER_TEST_DELAY_MILLIS = 10;
    protected static final int GIVEUP_INTERVAL_MILLIS = 2_000;
    protected static final int VERIFY_FREQUENCY_MILLIS = 10;
    protected static final String MON_CONF_INTERVAL_MILLIS = "100";
    protected static final String MEM_CONF_INTERVAL_MILLIS = "0";

    protected static final String CONNECTION_TIMEOUT_MILLIS = "200";
    protected static final String RECONNECT_INTERVAL_MILLIS = "5";
    protected static final String REGISTRATION_TIMEOUT_MILLIS = "500";

    protected static final String FT_GROUP = "GRP";

    static {
        ObjImpl.setRtgCtor(RtgImpl.class.getName());

        try {
            ForceDisconnect fd;
            MsgInstantiator forceDisconnectInstantiator =
                    new MsgInstantiator(ForceDisconnect.class.getName());
            MsgInstantiator registrationRequestInstantiator =
                    new MsgInstantiator(RegistrationRequest.class.getName());
            MsgInstantiator registrationResponseInstantiator =
                    new MsgInstantiator(RegistrationResponse.class.getName());
            MsgInstantiator voteInstantiator =
                    new MsgInstantiator(VoteMsg.class.getName());
            MsgInstantiator versionedStringInstantiator =
                    new MsgInstantiator(VersionedStringMsg.class.getName());
            MsgInstantiator ftMemberInstantiator =
                    new MsgInstantiator(FtMemberMsg.class.getName());
            MsgInstantiator ftMonitorInstantiator =
                    new MsgInstantiator(FtMonitorMsg.class.getName());

            List<MsgInstantiator> msgInstantiators = Arrays.asList(
                    forceDisconnectInstantiator,
                    registrationRequestInstantiator,
                    registrationResponseInstantiator,
                    voteInstantiator,
                    versionedStringInstantiator,
                    ftMemberInstantiator,
                    ftMonitorInstantiator);

            List<Pool<?>> pools = Arrays.asList(
                    new Pool<Msg>(forceDisconnectInstantiator, 20, 10),
                    new Pool<Msg>(registrationRequestInstantiator, 20, 10),
                    new Pool<Msg>(registrationResponseInstantiator, 20, 10),
                    new Pool<Msg>(voteInstantiator, 20, 10),
                    new Pool<Msg>(versionedStringInstantiator, 20, 10),
                    new Pool<Msg>(ftMemberInstantiator, 20, 10),
                    new Pool<Msg>(ftMonitorInstantiator, 20, 10));

            ObjectManager objectManager = ObjectManager.getInstance();
            objectManager.setMsgInstantiators(msgInstantiators);
            objectManager.setMsgPools(pools);

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    protected abstract AtomicInteger getPort();

    protected static MsgCoder _coder = new MsgCoder();

    private TestInfo _testInfo;

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        _testInfo = testInfo;
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        _testInfo = testInfo;
        sleep(INTER_TEST_DELAY_MILLIS);
    }

    protected void tearDown(CompInfoSet cis) {
        log.info("================================= "+cis+" "+_testInfo.getDisplayName());
//        ObjectManagerTestUtils.checkPools(); // TODO how can I get this back?
    }



    private void eventually(CompInfoSet cis, BooleanSupplier supplier) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (supplier.getAsBoolean()) return;
        }
        assertTrue(supplier.getAsBoolean(), cis.toString());
    }

    protected void eventually(ClientMem m, Predicate<ClientMem> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(m)) return;
        }
        assertTrue(predicate.test(m), m._client._myInfo.getId());
    }

    protected void eventually(ClientMem m, BiPredicate<ClientMem, String> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(m, null)) return;
        }
        predicate.test(m,  m._client._myInfo.getId());
    }

    protected void eventually(ClientMon m, Predicate<ClientMon> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(m)) return;
        }
        assertTrue(predicate.test(m), m._monitor._myInfo.getId());
    }

    protected void eventually(ClientMon m, BiPredicate<ClientMon, String> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(m, null)) return;
        }
        predicate.test(m, m._monitor._myInfo.getId());
    }

    protected void eventually(Daemon d, Predicate<Daemon> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(d)) return;
        }
        assertTrue(predicate.test(d), d._myInfoStr);
    }

    protected void eventually(Daemon d, BiPredicate<Daemon, String> predicate) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (predicate.test(d, null)) return;
        }
        predicate.test(d, d._myInfoStr);
    }

    protected void notWithinReasonableTimeframe(ClientMon m, BiConsumer<ClientMon, String> consumer) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            consumer.accept(m, m._monitor._myInfo.getId());
        }
    }

    protected class Daemon {
        private final String _myInfoStr;
        private String _collectiveCores;
        private int _collectiveCoresVersion;
        private final String _upgradedFilePathName;

        private VersionedParamsCache _versionedParamsCache;
        private CollectiveMember _collectiveMember;

        public Daemon(CompInfoSet cis, int instance, int[] cores, int version) {
            _myInfoStr = cis.getDInfo(instance);
            _collectiveCores = cis.getDCores(cores);
            _collectiveCoresVersion = version;
            _upgradedFilePathName = cis.getDUpgrade(instance);

            init(_collectiveCoresVersion, _collectiveCores);
        }

        private void init(int collectiveCoresVersion, String collectiveCores) {
            _versionedParamsCache = new VersionedParamsCache(_upgradedFilePathName);
            _versionedParamsCache.start();
            VersionedStringMsg vsm = _versionedParamsCache._map.get(CollectiveMember.VSM_NAME);
            if (vsm!=null) {
                collectiveCoresVersion = vsm._version;
                collectiveCores = vsm._string;
            }
            _collectiveMember = new CollectiveMember(_coder, collectiveCoresVersion, collectiveCores);
            _collectiveMember.setMyInfo(_myInfoStr);
            _collectiveMember.setVersionedParamsCache(_versionedParamsCache);
            _collectiveMember.setConnectionTimeoutMillis(CONNECTION_TIMEOUT_MILLIS);
            _collectiveMember.setReconnectIntervalMillis(RECONNECT_INTERVAL_MILLIS);
            _collectiveMember.setRegistrationTimeoutMillis(REGISTRATION_TIMEOUT_MILLIS);
        }

        public void start() {
            _collectiveMember.start();
        }

        public void stop() {
            _collectiveMember.stop();
            File fin = new File(_upgradedFilePathName);
            if (fin.exists() && !fin.isDirectory()) {
                fin.delete();
            }
        }

        public void restart(CompInfoSet cis) {
            _collectiveMember.stop();
            eventually(cis, () -> isStopped());

            init(_collectiveCoresVersion, _collectiveCores);
            _collectiveMember.start();
        }

        public void restart(CompInfoSet cis, int[] cores, int version) {
            _collectiveMember.stop();
            eventually(cis, () -> isStopped());

            _collectiveCores = cis.getDCores(cores);
            _collectiveCoresVersion = version;

            init(_collectiveCoresVersion, _collectiveCores);
            _collectiveMember.start();
        }

        public boolean iAmCore(boolean expected) {
            return _collectiveMember.iAmCore() == expected;
        }

        public boolean iAmPrimary(String ctx, boolean expected, MemberStatusEnum[] statuses) {
            if (ctx == null) {
                return _collectiveMember.iAmPrimary() == expected && _collectiveMember.verifyStatuses(statuses);
            } else {
                assertEquals(Arrays.asList(statuses), Arrays.asList(_collectiveMember.getStatuses()), ctx + " statuses");
                assertEquals(expected, _collectiveMember.iAmPrimary(), ctx + " is primary");
                return true;
            }
        }

        public boolean isStarted(boolean expected) {
            return _collectiveMember.isStarted() == expected;
        }

        public boolean isUpgraded(int version) {
            return _collectiveMember.isUpgraded(version);
        }

        public boolean isStopped() {
            return _collectiveMember.isStopped() == true;
        }
    }

    protected static class ClientMem implements IFtMemberListener {
        private final CollectiveClient _client;
        private FtMsgOp _op = FtMsgOp.NONE;
        private int _stripeNo;
        private int _ofStripes;

        public ClientMem(CompInfoSet cis, int instance, int port) {
            _client = new CollectiveClient(_coder, cis.getMemInfo(instance, port), MON_CONF_INTERVAL_MILLIS, MEM_CONF_INTERVAL_MILLIS);
            _client.registerFtMemberListener(this);
            _client.setConnectionTimeoutMillis(CONNECTION_TIMEOUT_MILLIS);
            _client.setReconnectIntervalMillis(RECONNECT_INTERVAL_MILLIS);
            _client.setRegistrationTimeoutMillis(REGISTRATION_TIMEOUT_MILLIS);
        }

        public void start() {
            _client.start();
        }

        public void stop() {
            _client.stop();
        }

        public void registerFtMember(String groupName, int instance, int activeGoal) {
            _client.registerFtMember(groupName, instance, activeGoal);
        }

        public void unregisterFtMember(String groupName, int instance) {
            _client.unregisterFtMember(groupName, instance);
        }

        public boolean isMemResult(String ctx, FtMsgOp op) {
            if (ctx == null) {
                return _op == op && _stripeNo == 0 && _ofStripes == ((op == FtMsgOp.ACTIVATE) ? 1 : 0);
            }
            assertEquals(String.format("(%s, %d, %d)", op, 0, 0), String.format("(%s, %d, %d)", _op, _stripeNo, _ofStripes), ctx);
            return true;
        }

        public boolean isMemResult(String ctx, FtMsgOp op, int stripeNo, int ofStripes) {
            if (ctx == null) {
                return _op == op && _stripeNo == stripeNo && _ofStripes == ofStripes;
            }
            assertEquals(String.format("(%s, %d, %d)", op, stripeNo, ofStripes), String.format("(%s, %d, %d)", _op, _stripeNo, _ofStripes), ctx);
            return true;
        }

        @Override
        public void onFtAction(String groupName, int instance, FtMsgOp op, int stripeNo, int ofStripes) {
            _op = op;
            _stripeNo = stripeNo;
            _ofStripes = ofStripes;
        }

        public boolean isConnected(boolean expected) {
            return _client.isConnected() == expected;
        }

        public boolean isStopped(boolean expected) {
            return _client.isStopped() == expected;
        }
    }

    protected static class ClientMon implements IFtMonitorListener {
        private final CollectiveClient _monitor;
        public int _actives = -1;

        public ClientMon(CompInfoSet cis, int instance, int port) {
            _monitor = new CollectiveClient(_coder, cis.getMonInfo(instance, port), MON_CONF_INTERVAL_MILLIS, MEM_CONF_INTERVAL_MILLIS);
            _monitor.registerFtMonitorListener(this);
        }

        public void start() {
            _monitor.start();
        }

        public void stop() {
            _monitor.stop();
        }

        public void registerFtMonitor(String groupName) {
            _monitor.registerFtMonitor(groupName);
        }

        public void unregisterFtMonitor(String groupName) {
            _monitor.unregisterFtMonitor(groupName);
        }

        public void failIfBitIsSet(String ctx, int bitMask) {
            if ((_actives & bitMask) != 0) {
                fail(String.format("%s bit=0x%08X not expected to be set in actives=0x%08X", ctx, bitMask, _actives));
            }
        }

        public boolean isActivesBitMask(String ctx, int expected) {
            if (ctx == null) {
                return _actives == expected;
            }
            assertEquals(expected, _actives, ctx + " actives bit mask");
            return true;
        }

        @Override
        public void onActivesChanged(String groupName, int actives) {
            _actives = actives;
        }

        public boolean isConnected(boolean expected) {
            return _monitor.isConnected() == expected;
        }

        public boolean isStopped(boolean expected) {
            return _monitor.isStopped() == expected;
        }
    }

    protected class CompInfoSet {
        private final int _basePort;
        public CompInfoSet() {
            _basePort = getPort().getAndAdd(10);
            log.info("--------------------------------- "+_basePort+" "+_testInfo.getDisplayName());

            // remove any leftover 'upgrade' files from failed tests
            for (int i=0; i<4; i++) {
                String upgradedFilePathName = getDUpgrade(i);
                File fin = new File(upgradedFilePathName);
                if (fin.exists() && !fin.isDirectory()) {
                    fin.delete();
                }
            }

        }
        public String getDCores(int[] coreIndices) {
            String result = getDInfo(coreIndices[0]);
            for (int i = 1; i < coreIndices.length; i++) {
                result += "," + getDInfo(coreIndices[i]);
            }
            return result;
        }
        public String getDInfo(int instance) {
            return getDInfo(instance, instance);
        }
        public String getDInfo(int instance, int port) {
            return "d_"+instance+"@localhost:"+(_basePort+port);
        }
        public String getDUpgrade(int port) {
            return "./config/config-daemon-"+(_basePort+port)+".upgraded.properties";
        }
        public String getMemInfo(int instance) {
            return getMemInfo(instance, instance);
        }
        public String getMemInfo(int instance, int port) {
            return"mem_"+instance+"@:"+(_basePort+port);
        }
        public String getMonInfo(int instance) {
            return getMonInfo(instance, instance);
        }
        public String getMonInfo(int instance, int port) {
            return"mon_"+instance+"@:"+(_basePort+port);
        }
        public int getRealPort(int portOffset) {
            return portOffset + _basePort;
        }
        public String toString() {
            return _basePort+"";
        }
    }
}
