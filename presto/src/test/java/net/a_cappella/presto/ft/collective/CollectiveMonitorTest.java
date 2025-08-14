package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.collective.CollectiveClient.*;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DISCONNECT;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveMonitorTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(19430);
    protected AtomicInteger getPort() {
        return _port;
    }

    @Test
    public void testMonitorFromCoreMachine_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));

        notWithinReasonableTimeframe(cis, () -> mon2.isActivesBitMask(ONE));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testMonitorFromCoreMachine_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 1));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 1, 2));

        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon2.isActivesBitMask(ONE));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testMonitorFromNonCoreMachine_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon3 = new ClientMon(_coder, cis.getMonInfo(3));
        mon3.start();
        eventually(cis, () -> mon3.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));

        mon3.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon3.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));

        notWithinReasonableTimeframe(cis, () -> mon3.isActivesBitMask(ONE));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon3.isActivesBitMask(NONE));

        mon3.stop();
        eventually(cis, () -> mon3.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testMonitorFromNonCoreMachine_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon3 = new ClientMon(_coder, cis.getMonInfo(3));
        mon3.start();
        eventually(cis, () -> mon3.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 1));

        mon3.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon3.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 1, 2));

        eventually(cis, () -> mon3.isActivesBitMask(ZERO|ONE));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        eventually(cis, () -> mon3.isActivesBitMask(ONE));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon3.isActivesBitMask(NONE));

        mon3.stop();
        eventually(cis, () -> mon3.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testStopStartAllCores_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1a = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1a.start();
        eventually(cis, () -> d1a.iAmCore(true));
        eventually(cis, () -> d1a.isStarted(true));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2a = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2a.start();
        eventually(cis, () -> d2a.iAmCore(true));
        eventually(cis, () -> d2a.isStarted(true));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));

        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));
        eventually(cis, () -> d1a.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        eventually(cis, () -> mem0.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1.isMemResult(ACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mem0.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        d1a.stop();
        eventually(cis, () -> d1a.isStopped(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN, UP}));

        eventually(cis, () -> mem1.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        Daemon d1b = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1b.start();
        eventually(cis, () -> d1b.iAmCore(true));
        eventually(cis, () -> d1b.isStarted(true));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        d2a.stop();
        eventually(cis, () -> d2a.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d2b = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2b.start();
        eventually(cis, () -> d2b.iAmCore(true));
        eventually(cis, () -> d2b.isStarted(true));
        eventually(cis, () -> d2b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        eventually(cis, () -> mem1.isMemResult(ACTIVATE));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0b.stop();
        eventually(cis, () -> d0a.isStopped(true));

        d1b.stop();
        eventually(cis, () -> d1b.isStopped(true));

        d2b.stop();
        eventually(cis, () -> d2b.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testStopStartAllCores_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1a = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1a.start();
        eventually(cis, () -> d1a.iAmCore(true));
        eventually(cis, () -> d1a.isStarted(true));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2a = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2a.start();
        eventually(cis, () -> d2a.iAmCore(true));
        eventually(cis, () -> d2a.isStarted(true));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 1));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        ClientMem mem1 = new ClientMem(_coder, cis.getMemInfo(1));
        mem1.start();
        eventually(cis, () -> mem1.isConnected(true));

        mem1.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));
        eventually(cis, () -> d1a.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        eventually(cis, () -> mem0.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon2.isActivesBitMask(ONE));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d1a.stop();
        eventually(cis, () -> d1a.isStopped(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN, UP}));

        eventually(cis, () -> mem1.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        Daemon d1b = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1b.start();
        eventually(cis, () -> d1b.iAmCore(true));
        eventually(cis, () -> d1b.isStarted(true));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mem0.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d2a.stop();
        eventually(cis, () -> d2a.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d2b = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2b.start();
        eventually(cis, () -> d2b.iAmCore(true));
        eventually(cis, () -> d2b.isStarted(true));
        eventually(cis, () -> d2b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem1.stop();
        eventually(cis, () -> mem1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0b.stop();
        eventually(cis, () -> d0a.isStopped(true));

        d1b.stop();
        eventually(cis, () -> d1b.isStopped(true));

        d2b.stop();
        eventually(cis, () -> d2b.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToCore0_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        ClientMem mem0d0 = new ClientMem(_coder, cis.getMemInfo(0, 0));
        mem0d0.start();
        eventually(cis, () -> mem0d0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(0));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        ClientMem mem1d0 = new ClientMem(_coder, cis.getMemInfo(1, 0));
        mem1d0.start();
        eventually(cis, () -> mem1d0.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d0.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d0.isMemResult(DEACTIVATE));

        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));

        eventually(cis, () -> mem0d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1d0.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem0d0.stop();
        eventually(cis, () -> mem0d0.isStopped(true));

        eventually(cis, () -> mem1d0.isMemResult(ACTIVATE));

        mem1d0.stop();
        eventually(cis, () -> mem1d0.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0b.stop();
        eventually(cis, () -> d0b.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToCore0_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        ClientMem mem0d0 = new ClientMem(_coder, cis.getMemInfo(0, 0));
        mem0d0.start();
        eventually(cis, () -> mem0d0.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(0));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        ClientMem mem1d0 = new ClientMem(_coder, cis.getMemInfo(1, 0));
        mem1d0.start();
        eventually(cis, () -> mem1d0.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d0.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d0.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1d0.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));

        eventually(cis, () -> mem0d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1d0.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        mem0d0.stop();
        eventually(cis, () -> mem0d0.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(ONE));

        mem1d0.stop();
        eventually(cis, () -> mem1d0.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0b.stop();
        eventually(cis, () -> d0b.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToCore1_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1a = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1a.start();
        eventually(cis, () -> d1a.iAmCore(true));
        eventually(cis, () -> d1a.isStarted(true));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        ClientMem mem0d1 = new ClientMem(_coder, cis.getMemInfo(0, 1));
        mem0d1.start();
        eventually(cis, () -> mem0d1.isConnected(true));

        ClientMem mem1d1 = new ClientMem(_coder, cis.getMemInfo(1, 1));
        mem1d1.start();
        eventually(cis, () -> mem1d1.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(1));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d1.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d1.isMemResult(ACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d1.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d1.isMemResult(DEACTIVATE));

        d1a.stop();
        eventually(cis, () -> d1a.isStopped(true));

        eventually(cis, () -> mem0d1.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d1.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d1b = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1b.start();
        eventually(cis, () -> d1b.iAmCore(true));
        eventually(cis, () -> d1b.isStarted(true));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        eventually(cis, () -> mem0d1.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1d1.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem0d1.stop();
        eventually(cis, () -> mem0d1.isStopped(true));

        eventually(cis, () -> mem1d1.isMemResult(ACTIVATE));

        mem1d1.stop();
        eventually(cis, () -> mem1d1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d1b.stop();
        eventually(cis, () -> d1b.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToCore1_1ActiveGoal_bounce_d0() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        ClientMem mem0d1 = new ClientMem(_coder, cis.getMemInfo(0, 1));
        mem0d1.start();
        eventually(cis, () -> mem0d1.isConnected(true));

        ClientMem mem1d1 = new ClientMem(_coder, cis.getMemInfo(1, 1));
        mem1d1.start();
        eventually(cis, () -> mem1d1.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(1));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d1.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d1.isMemResult(ACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d1.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d1.isMemResult(DEACTIVATE));

        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));

//    	eventually(cis, () -> mem0.isAction(ACTIVATE));
//    	eventually(cis, () -> mem1.isAction(DEACTIVATE));
//    	eventually(cis, () -> mon2.isActivesBitMask(1));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

//    	eventually(cis, () -> mem0.isAction(ACTIVATE));
//    	eventually(cis, () -> mem1.isAction(DEACTIVATE));
//    	eventually(cis, () -> mon2.isActivesBitMask(1));

        mem0d1.stop();
        eventually(cis, () -> mem0d1.isStopped(true));

        eventually(cis, () -> mem1d1.isMemResult(ACTIVATE));

        mem1d1.stop();
        eventually(cis, () -> mem1d1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d0b.stop();
        eventually(cis, () -> d0b.isStopped(true));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToCore1_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d1a = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1a.start();
        eventually(cis, () -> d1a.iAmCore(true));
        eventually(cis, () -> d1a.isStarted(true));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        ClientMem mem0d1 = new ClientMem(_coder, cis.getMemInfo(0, 1));
        mem0d1.start();
        eventually(cis, () -> mem0d1.isConnected(true));

        ClientMem mem1d1 = new ClientMem(_coder, cis.getMemInfo(1, 1));
        mem1d1.start();
        eventually(cis, () -> mem1d1.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(1));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d1.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0d1.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d1.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1d1.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d1a.stop();
        eventually(cis, () -> d1a.isStopped(true));

        eventually(cis, () -> mem0d1.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d1.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d1b = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1b.start();
        eventually(cis, () -> d1b.iAmCore(true));
        eventually(cis, () -> d1b.isStarted(true));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        eventually(cis, () -> mem0d1.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1d1.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        mem0d1.stop();
        eventually(cis, () -> mem0d1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(ONE));

        mem1d1.stop();
        eventually(cis, () -> mem1d1.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d1b.stop();
        eventually(cis, () -> d1b.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToNonCore_1ActiveGoal() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d2a = new Daemon(cis.getDInfo(2), cis.cc01(), 0, cis.getDUpgrade(2));
        d2a.start();
        eventually(cis, () -> d2a.iAmCore(false));
        eventually(cis, () -> d2a.isStarted(true));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        ClientMem mem0d2 = new ClientMem(_coder, cis.getMemInfo(0, 2));
        mem0d2.start();
        eventually(cis, () -> mem0d2.isConnected(true));

        ClientMem mem1d2 = new ClientMem(_coder, cis.getMemInfo(1, 2));
        mem1d2.start();
        eventually(cis, () -> mem1d2.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d2.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d2.isMemResult(ACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d2.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d2.isMemResult(DEACTIVATE));

        d2a.stop();
        eventually(cis, () -> d2a.isStopped(true));

        eventually(cis, () -> mem0d2.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d2.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d2b = new Daemon(cis.getDInfo(2), cis.cc01(), 0, cis.getDUpgrade(2));
        d2b.start();
        eventually(cis, () -> d2b.iAmCore(false));
        eventually(cis, () -> d2b.isStarted(true));
        eventually(cis, () -> d2b.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        eventually(cis, () -> mem0d2.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1d2.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem0d2.stop();
        eventually(cis, () -> mem0d2.isStopped(true));

        eventually(cis, () -> mem1d2.isMemResult(ACTIVATE));

        mem1d2.stop();
        eventually(cis, () -> mem1d2.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d2b.stop();
        eventually(cis, () -> d2b.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testAllConnectedToNonCore_2ActiveGoals() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d2a = new Daemon(cis.getDInfo(2), cis.cc01(), 0, cis.getDUpgrade(2));
        d2a.start();
        eventually(cis, () -> d2a.iAmCore(false));
        eventually(cis, () -> d2a.isStarted(true));
        eventually(cis, () -> d2a.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        ClientMem mem0d2 = new ClientMem(_coder, cis.getMemInfo(0, 2));
        mem0d2.start();
        eventually(cis, () -> mem0d2.isConnected(true));

        ClientMem mem1d2 = new ClientMem(_coder, cis.getMemInfo(1, 2));
        mem1d2.start();
        eventually(cis, () -> mem1d2.isConnected(true));

        ClientMon mon2 = new ClientMon(_coder, cis.getMonInfo(2));
        mon2.start();
        eventually(cis, () -> mon2.isConnected(true));

        mon2.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mem0d2.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0d2.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem1d2.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1d2.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        d2a.stop();
        eventually(cis, () -> d2a.isStopped(true));

        eventually(cis, () -> mem0d2.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d2.isMemResult(DISCONNECT));
        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        Daemon d2b = new Daemon(cis.getDInfo(2), cis.cc01(), 0, cis.getDUpgrade(2));
        d2b.start();
        eventually(cis, () -> d2b.iAmCore(false));
        eventually(cis, () -> d2b.isStarted(true));
        eventually(cis, () -> d2b.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        eventually(cis, () -> mem0d2.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1d2.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO|ONE));

        mem0d2.stop();
        eventually(cis, () -> mem0d2.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(ONE));

        mem1d2.stop();
        eventually(cis, () -> mem1d2.isStopped(true));

        eventually(cis, () -> mon2.isActivesBitMask(NONE));

        mon2.stop();
        eventually(cis, () -> mon2.isStopped(true));

        d2b.stop();
        eventually(cis, () -> d2b.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        tearDown(cis);
    }


    @Test
    public void testCoreNonCoreMonitoring() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0a = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0a.start();
        eventually(cis, () -> d0a.iAmCore(true));
        eventually(cis, () -> d0a.isStarted(true));
        eventually(cis, () -> d0a.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d1a = new Daemon(cis.getDInfo(1), cis.cc01(), 0, cis.getDUpgrade(1));
        d1a.start();
        eventually(cis, () -> d1a.iAmCore(true));
        eventually(cis, () -> d1a.isStarted(true));
        eventually(cis, () -> d1a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        Daemon d3a = new Daemon(cis.getDInfo(3), cis.cc01(), 0, cis.getDUpgrade(3));
        d3a.start();
        eventually(cis, () -> d3a.iAmCore(false));
        eventually(cis, () -> d3a.isStarted(true));
        eventually(cis, () -> d3a.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        Daemon d4 = new Daemon(cis.getDInfo(4), cis.cc01(), 0, cis.getDUpgrade(4));
        d4.start();
        eventually(cis, () -> d4.iAmCore(false));
        eventually(cis, () -> d4.isStarted(true));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        ClientMem mem0a = new ClientMem(_coder, cis.getMemInfo(0));
        mem0a.start();
        eventually(cis, () -> mem0a.isConnected(true));

        ClientMem mem1a = new ClientMem(_coder, cis.getMemInfo(1));
        mem1a.start();
        eventually(cis, () -> mem1a.isConnected(true));

        ClientMem mem3a = new ClientMem(_coder, cis.getMemInfo(3));
        mem3a.start();
        eventually(cis, () -> mem3a.isConnected(true));

        ClientMon mon4 = new ClientMon(_coder, cis.getMonInfo(4));
        mon4.start();
        eventually(cis, () -> mon4.isConnected(true));

        mon4.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon4.isActivesBitMask(NONE));

        mem0a.registerFtMember(FT_GROUP, 0, 2);
        eventually(cis, () -> mem0a.isMemResult(ACTIVATE, 0, 1));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO));

        mem1a.registerFtMember(FT_GROUP, 1, 2);
        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        mem3a.registerFtMember(FT_GROUP, 3, 2);
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart d0
        d0a.stop();
        eventually(cis, () -> d0a.isStopped(true));

        eventually(cis, () -> d1a.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP}));
        eventually(cis, () -> d3a.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP}));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP}));

        eventually(cis, () -> mem0a.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem3a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        Daemon d0b = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0b.start();
        eventually(cis, () -> d0b.iAmCore(true));
        eventually(cis, () -> d0b.isStarted(true));
        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> mem0a.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart mem0
        mem0a.stop();
        eventually(cis, () -> mem0a.isStopped(true));

        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem3a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        ClientMem mem0b = new ClientMem(_coder, cis.getMemInfo(0));
        mem0b.start();
        eventually(cis, () -> mem0b.isConnected(true));

        mem0b.registerFtMember(FT_GROUP, 0, 2);

        eventually(cis, () -> mem0b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart d1
        d1a.stop();
        eventually(cis, () -> d1a.isStopped(true));

        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d3a.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        eventually(cis, () -> mem1a.isMemResult(DISCONNECT));
        eventually(cis, () -> mem3a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|THREE));

        Daemon d1b = new Daemon(cis.getDInfo(1), cis.cc01(), 0, cis.getDUpgrade(1));
        d1b.start();
        eventually(cis, () -> d1b.iAmCore(true));
        eventually(cis, () -> d1b.isStarted(true));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> mem1a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart mem1
        mem1a.stop();
        eventually(cis, () -> mem1a.isStopped(true));
        eventually(cis, () -> mem3a.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|THREE));

        ClientMem mem1b = new ClientMem(_coder, cis.getMemInfo(1));
        mem1b.start();
        eventually(cis, () -> mem1b.isConnected(true));

        mem1b.registerFtMember(FT_GROUP, 1, 2);

        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart d3
        d3a.stop();
        eventually(cis, () -> d3a.isStopped(true));

        eventually(cis, () -> d0b.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> mem0b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DISCONNECT));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        Daemon d3b = new Daemon(cis.getDInfo(3), cis.cc01(), 0, cis.getDUpgrade(3));
        d3b.start();
        eventually(cis, () -> d3b.iAmCore(false));
        eventually(cis, () -> d3b.isStarted(true));
        eventually(cis, () -> d3b.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> mem0b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3a.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // restart mem3
        mem3a.stop();
        eventually(cis, () -> mem3a.isStopped(true));

        eventually(cis, () -> mem0b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        ClientMem mem3b = new ClientMem(_coder, cis.getMemInfo(3));
        mem3b.start();
        eventually(cis, () -> mem3b.isConnected(true));

        mem3b.registerFtMember(FT_GROUP, 3, 2);

        eventually(cis, () -> mem0b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mem3b.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon4.isActivesBitMask(ZERO|ONE));

        // shut down everything

        d0b.stop();
        eventually(cis, () -> d0b.isStopped(true));

        eventually(cis, () -> d1b.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP}));
        eventually(cis, () -> d3b.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP}));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP}));

        eventually(cis, () -> mem0b.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1b.isMemResult(ACTIVATE, 0, 2));
        eventually(cis, () -> mem3b.isMemResult(ACTIVATE, 1, 2));
        eventually(cis, () -> mon4.isActivesBitMask(ONE|THREE));

        mem0b.stop();
        eventually(cis, () -> mem0b.isStopped(true));

        d1b.stop();
        eventually(cis, () -> d1b.isStopped(true));

        eventually(cis, () -> d3b.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        eventually(cis, () -> mem1b.isMemResult(DISCONNECT));
        eventually(cis, () -> mem3b.isMemResult(DISCONNECT));
        eventually(cis, () -> mon4.isActivesBitMask(NONE));

        mem1b.stop();
        eventually(cis, () -> mem1b.isStopped(true));

        d3b.stop();
        eventually(cis, () -> d3b.isStopped(true));

        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        eventually(cis, () -> mem3b.isMemResult(DISCONNECT));
        eventually(cis, () -> mon4.isActivesBitMask(NONE));

        mem3b.stop();
        eventually(cis, () -> mem3b.isStopped(true));

        d4.stop();
        eventually(cis, () -> d4.isStopped(true));

        eventually(cis, () -> mon4.isActivesBitMask(NONE));

        mon4.stop();
        eventually(cis, () -> mon4.isStopped(true));

        tearDown(cis);
    }
}
