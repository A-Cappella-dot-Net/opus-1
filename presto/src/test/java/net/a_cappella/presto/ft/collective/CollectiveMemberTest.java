package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveMemberTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(17430);
    protected AtomicInteger getPort() {
        return _port;
    }

    @Test
    public void testSingleCore0() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d.start();
        eventually(cis, () -> d.iAmCore(true));
        eventually(cis, () -> d.isStarted(true));
        eventually(cis, () -> d.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d.stop();
        eventually(cis, () -> d.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testSingleCore1() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d.start();
        eventually(cis, () -> d.iAmCore(true));
        eventually(cis, () -> d.isStarted(true));
        eventually(cis, () -> d.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, DOWN}));

        d.stop();
        eventually(cis, () -> d.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testSingleCore2() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d.start();
        eventually(cis, () -> d.iAmCore(true));
        eventually(cis, () -> d.isStarted(true));
        eventually(cis, () -> d.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d.stop();
        eventually(cis, () -> d.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testMultipleCoresPrimaryUnchanged() {
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
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, DOWN}));

        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
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

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testMultipleCoresPrimaryChanges() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.stop();
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d2.stop();

        tearDown(cis);
    }

    @Test
    public void testSingleNonCore() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d.start();
        eventually(cis, () -> d.iAmCore(false));
        eventually(cis, () -> d.isStarted(true));
        eventually(cis, () -> d.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        d.stop();

        tearDown(cis);
    }

    @Test
    public void testMultipleNonCores() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        Daemon d4 = new Daemon(cis.getDInfo(4), cis.cc012(), 0, cis.getDUpgrade(4));
        d4.start();
        eventually(cis, () -> d4.iAmCore(false));
        eventually(cis, () -> d4.isStarted(true));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        d3.stop();
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        d4.stop();

        tearDown(cis);
    }

    @Test
    public void testCoreNonCore() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        d3.stop();
        eventually(cis, () -> d3.isStopped(true));

        tearDown(cis);
    }

    @Test
    public void testMultipleMixed() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc012(), 0, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d4 = new Daemon(cis.getDInfo(4), cis.cc012(), 0, cis.getDUpgrade(4));
        d4.start();
        eventually(cis, () -> d4.iAmCore(false));
        eventually(cis, () -> d4.isStarted(true));
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d3.stop();
        eventually(cis, () -> d4.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d4.stop();
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(cis, () -> d2.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d2.stop();
        d1.stop();

        tearDown(cis);
    }
}
