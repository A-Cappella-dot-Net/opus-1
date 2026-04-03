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

import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.collective.CollectiveClient.*;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveUpgradeWithClientAndMonitorTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(20430);
    protected AtomicInteger getPort() {
        return _port;
    }

    @Test
    public void testUpgradeCoresOrder() {
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

        d2.restart(cis, cis.cc210(), 1);
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP, UP}));

        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(cis, () -> d1.iAmPrimary(false, new MemberStatusEnum[] {UP, UP, UP}));

        notWithinReasonableTimeframe(cis, () -> mon2.isActivesBitMask(ONE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));

        // TODO separate unit test for this behavior
        d0.restart(cis);
        eventually(cis, () -> d0.isStarted(true));

        eventually(cis, () -> mem0.isMemResult(ACTIVATE));
        eventually(cis, () -> mem1.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon2.isActivesBitMask(ZERO));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        eventually(cis, () -> mem1.isMemResult(ACTIVATE));

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
    public void testUpgradeAddPrimary() {
        CompInfoSet cis = new CompInfoSet();

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc01(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc01(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN}));

        ClientMem mem31 = new ClientMem(_coder, cis.getMemInfo(1, 3));
        mem31.start();
        eventually(cis, () -> mem31.isConnected(true));

        ClientMon mon3 = new ClientMon(_coder, cis.getMonInfo(3));
        mon3.start();
        eventually(cis, () -> mon3.isConnected(true));

        mem31.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem31.isMemResult(ACTIVATE));

        mon3.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon3.isActivesBitMask(ONE));

        Daemon d2 = new Daemon(cis.getDInfo(2), cis.cc20(), 1, cis.getDUpgrade(2));
        d2.start();
        eventually(cis, () -> d2.iAmCore(true));
        eventually(cis, () -> d2.isStarted(true));
        eventually(cis, () -> d2.iAmPrimary(true, new MemberStatusEnum[] {UP, UP}));
        eventually(cis, () -> d0.iAmPrimary(false, new MemberStatusEnum[] {UP, UP}));

        ClientMem mem30 = new ClientMem(_coder, cis.getMemInfo(0, 3));
        mem30.start();
        eventually(cis, () -> mem30.isConnected(true));

        mem30.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem30.isMemResult(ACTIVATE));
        eventually(cis, () -> mem31.isMemResult(DEACTIVATE));



        mem31.stop();
        eventually(cis, () -> mem31.isStopped(true));

        mem30.stop();
        eventually(cis, () -> mem30.isStopped(true));

        mon3.stop();
        eventually(cis, () -> mon3.isStopped(true));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        d3.stop();
        eventually(cis, () -> d3.isStopped(true));

        d2.stop();
        eventually(cis, () -> d2.isStopped(true));

        tearDown(cis);
    }

}
