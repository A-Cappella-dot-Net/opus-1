package net.a_cappella.presto.ft.collective;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.*;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.ft.upgrade.VersionedParamsCache;
import net.a_cappella.presto.msg.FtMemberMsg;
import net.a_cappella.presto.msg.FtMonitorMsg;
import net.a_cappella.presto.msg.VersionedStringMsg;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

//import net.a_cappella.continuo.managed.ObjectManagerTestUtils;


import java.io.File;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BooleanSupplier;

import static net.a_cappella.continuo.utils.Utils.sleep;
import static org.junit.jupiter.api.Assertions.*;

public abstract class CollectiveTestBase {
    protected static Logger log = LoggerFactory.getLogger(CollectiveTestBase.class);

    protected static final int INTER_TEST_DELAY_MILLIS = 10;
    protected static final int GIVEUP_INTERVAL_MILLIS = 2_000;
    protected static final int VERIFY_FREQUENCY_MILLIS = 10;
    protected static final String MON_CONF_INTERVAL_MILLIS = "100";
    protected static final String MEM_CONF_INTERVAL_MILLIS = "0";

    protected static final String CONNECTION_TIMEOUT_MICROS = "200";
    protected static final String RECONNECT_INTERVAL_MILLIS = "5";

    protected static final String FT_GROUP = "GRP";

    static {
        try {
            ForceDisconnect fd;
            MsgInstantiator forceDisconnectInstantiator =
                    new MsgInstantiator(ForceDisconnect.class.getName());
            MsgInstantiator registrationRequestInstantiator =
                    new MsgInstantiator(RegistrationRequest.class.getName());
            MsgInstantiator registrationResponseInstantiator =
                    new MsgInstantiator(RegistrationResponse.class.getName());
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
                    versionedStringInstantiator,
                    ftMemberInstantiator,
                    ftMonitorInstantiator);

            List<Pool<?>> pools = Arrays.asList(
                    new Pool<Msg>(forceDisconnectInstantiator, 20, 10),
                    new Pool<Msg>(registrationRequestInstantiator, 20, 10),
                    new Pool<Msg>(registrationResponseInstantiator, 20, 10),
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

    protected MsgCoder _coder = new MsgCoder();

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



    protected void eventually(CompInfoSet cis, BooleanSupplier supplier) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (supplier.getAsBoolean()) return;
        }
        assertTrue(supplier.getAsBoolean(), cis.toString());
    }

    protected void notWithinReasonableTimeframe(CompInfoSet cis, BooleanSupplier supplier) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            assertFalse(supplier.getAsBoolean(), cis.toString());
        }
    }

    protected class Daemon {
        private final String _myInfoStr;
        private String _collectiveCores;
        private int _collectiveCoresVersion;
        private final String _upgradedFilePathName;

        private VersionedParamsCache _versionedParamsCache;
        private CollectiveMember _collectiveMember;

        public Daemon(String myInfoStr, String collectiveCores, int collectiveCoresVersion, String upgradedFilePathName) {
            _myInfoStr = myInfoStr;
            _collectiveCores = collectiveCores;
            _collectiveCoresVersion = collectiveCoresVersion;
            _upgradedFilePathName = upgradedFilePathName;

            init(collectiveCoresVersion, collectiveCores);
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
            _collectiveMember.setConnectionTimeoutMicros(CONNECTION_TIMEOUT_MICROS);
            _collectiveMember.setReconnectIntervalMillis(RECONNECT_INTERVAL_MILLIS);
        }

        public Daemon(String myInfo, String collectiveCores, int collectiveCoresVersion, String upgradedFilePathName,
                      String connectionTimeoutMicros, String reconnectIntervalMillis) {
            this(myInfo, collectiveCores, collectiveCoresVersion, upgradedFilePathName);
            _collectiveMember.setConnectionTimeoutMicros(connectionTimeoutMicros);
            _collectiveMember.setReconnectIntervalMillis(reconnectIntervalMillis);

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

        public void restart(CompInfoSet cis, BooleanSupplier... suppliers) {
            _collectiveMember.stop();

            eventually(cis, () -> isStopped(true));
            for (BooleanSupplier supplier : suppliers) {
                eventually(cis, supplier);
            }

            init(_collectiveCoresVersion, _collectiveCores);
            _collectiveMember.start();
        }

        public void restart(CompInfoSet cis, String collectiveCores, int collectiveCoresVersion) {
            _collectiveMember.stop();

            eventually(cis, () -> isStopped(true));
            _collectiveCores = collectiveCores;
            _collectiveCoresVersion = collectiveCoresVersion;

            init(_collectiveCoresVersion, _collectiveCores);
            _collectiveMember.start();
        }

        public boolean iAmCore(boolean expected) {
            return _collectiveMember.iAmCore(expected);
        }

        public boolean iAmPrimary(boolean expected, MemberStatusEnum[] statuses) {
            return _collectiveMember.iAmPrimary() == expected && _collectiveMember.verifyStatuses(statuses);
        }

        public boolean isStarted(boolean expected) {
            return _collectiveMember.isStarted() == expected;
        }

        public boolean isUpgraded(int version) {
            return _collectiveMember.isUpgraded(version);
        }

        public boolean isStopped(boolean expected) {
            return _collectiveMember.isStopped() == expected;
        }
    }

    protected static class ClientMem implements IFtMemberListener {
        private final CollectiveClient _client;
        private FtMsgOp _op = FtMsgOp.NONE;
        private int _sliceNo;
        private int _ofSlices;

        public ClientMem(MsgCoder coder, String clInfo) {
            _client = new CollectiveClient(coder, clInfo, MON_CONF_INTERVAL_MILLIS, MEM_CONF_INTERVAL_MILLIS);
            _client.registerFtMemberListener(this);
            _client.setConnectionTimeoutMicros(CONNECTION_TIMEOUT_MICROS);
            _client.setReconnectIntervalMillis(RECONNECT_INTERVAL_MILLIS);
        }

        public ClientMem(MsgCoder coder, String clInfo, String connectionTimeoutMicros, String reconnectIntervalMillis) {
            this(coder, clInfo);
            _client.setConnectionTimeoutMicros(connectionTimeoutMicros);
            _client.setReconnectIntervalMillis(reconnectIntervalMillis);
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

        public boolean isMemResult(FtMsgOp op) {
            return isMemResult(op, 0, (op==FtMsgOp.ACTIVATE)?1:0);
        }

        public boolean isMemResult(FtMsgOp op, int sliceNo, int ofSlices) {
            return _op == op && _sliceNo == sliceNo && _ofSlices == ofSlices;
        }

        @Override
        public void onFtAction(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices) {
            _op = op;
            _sliceNo = sliceNo;
            _ofSlices = ofSlices;
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
        private int _actives = -1;

        public ClientMon(MsgCoder coder, String mInfo) {
            _monitor = new CollectiveClient(coder, mInfo, MON_CONF_INTERVAL_MILLIS, MEM_CONF_INTERVAL_MILLIS);
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

        public boolean isActivesBitMask(int expected) {
            return _actives == expected;
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
        public String cc01() {
            return getDInfo(0)+","+getDInfo(1);
        }
        public String cc02() {
            return getDInfo(0)+","+getDInfo(2);
        }
        public String cc20() {
            return getDInfo(2)+","+getDInfo(0);
        }
        public String cc12() {
            return getDInfo(1)+","+getDInfo(2);
        }
        public String cc23() {
            return getDInfo(2)+","+getDInfo(3);
        }
        public String cc012() {
            return getDInfo(0)+","+getDInfo(1)+","+getDInfo(2);
        }
        public String cc210() {
            return getDInfo(2)+","+getDInfo(1)+","+getDInfo(0);
        }
        public String cc123() {
            return getDInfo(1)+","+getDInfo(2)+","+getDInfo(3);
        }
        public String cc321() {
            return getDInfo(3)+","+getDInfo(2)+","+getDInfo(1);
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
        public String toString() {
            return _basePort+"";
        }
    }
}
