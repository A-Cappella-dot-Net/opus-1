package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveUpgradeTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(20430);
    protected AtomicInteger getPort() {
        return _port;
    }

    @Test
    public void testUpgradeChangesOrderOfCoreSet() {
        CompInfoSet cis = new CompInfoSet();

        // initial order: d0, d1, d2
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

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        // order changes to: d2, d1, d0
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc210(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        d2.stop();
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        // the latest upgraded configuration is remembered after a restart
        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d0.stop(); // clean up 'upgraded' files

        tearDown(cis);
    }

    @Test
    public void testUpgradeReducesCoreSet1() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1, d2
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

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        // new set: d0, d1
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc01(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(false));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        d2.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testUpgradeReducesCoreSet2() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1, d2
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

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        // new set: d0, d2
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc02(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d1.iAmCore(false));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        d2.stop();
        eventually(cis, () -> d2.isStopped(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testUpgradeReducesCoreSet3() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1, d2
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

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        // new set: d1, d2
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc12(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.iAmCore(false));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        d2.stop();
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testUpgradeEnhancesCoreSet1() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc01(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        // new set: d0, d1, d2
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        d2.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testUpgradeEnhancesCoreSet2() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1
        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc01(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP}));

        // new set: d1, d2
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isUpgraded(1));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isUpgraded(1));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        d1.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN, UP}));

        d2.stop();
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testUpgradeShiftsCoreSet1() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1, d2
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

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        // new set: d2, d3
        // Notice that there _must_ be a common 'core' member between two upgradable versions
        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc23(), 1, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(true));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.iAmCore(false));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.iAmCore(false));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        d3.stop();
        eventually(cis, () -> d3.isStopped(true));

        d2.restart(cis);
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        d2.stop();
        eventually(cis, () -> d2.isStopped(true));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.restart(cis);
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testUpgradeShiftsCoreSet2() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1, d2
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        // new set: d2, d3
        // Notice that both d0 and d3 claim to be primary (since d3 and d0 do not communicate directly)
        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc23(), 1, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(true));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, DOWN}));

        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        // as soon as the common daemon is brought up it will upgrade itself and will upgrade any other daemons connected to it
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.isUpgraded(1));
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.isUpgraded(1));
        eventually(cis, () -> d0.iAmCore(false));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.isUpgraded(1));
        eventually(cis, () -> d1.iAmCore(false));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        d3.stop();
        eventually(cis, () -> d3.isStopped(true));

        d2.restart(cis);
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        d2.stop();
        eventually(cis, () -> d2.isStopped(true));

        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.restart(cis);
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testUpgradeShiftsCoreSet3() {
        CompInfoSet cis = new CompInfoSet();

        // initial set: d0, d1
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc01(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        // intermediate set: d0, d1, d2
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d0.isUpgraded(1));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.isUpgraded(1));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        // final set: d2, d3
        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc23(), 2, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(true));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d2.isUpgraded(2));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));

        eventually(cis, () -> d0.isUpgraded(2));
        eventually(cis, () -> d0.iAmCore(false));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d1.isUpgraded(2));
        eventually(cis, () -> d1.iAmCore(false));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        d3.stop();
        eventually(cis, () -> d3.isStopped(true));

        d2.restart(cis);
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        d2.stop();
        eventually(cis, () -> d2.isStopped(true));

        d0.restart(cis);
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d1.restart(cis);
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN}));

        d1.stop();
        eventually(cis, () -> d1.isStopped(true));

        tearDown(cis);
    }
}
