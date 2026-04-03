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

import static net.a_cappella.presto.ft.collective.CollectiveClient.NONE;
import static net.a_cappella.presto.ft.collective.CollectiveClient.ZERO;
import static net.a_cappella.presto.ft.constants.FtMsgOp.*;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveClientTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(18430);
    protected AtomicInteger getPort() {
        return _port;
    }

    @Test
    public void testOneClientConnectingToCoreMember1() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));

        mem0.unregisterFtMember(FT_GROUP, 0);
        eventually(cis, () -> mem0.isMemResult(DISCONNECT));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testOneClientConnectingToCoreMember2() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        ClientMem mem0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0.start();
        eventually(cis, () -> mem0.isConnected(true));

        mem0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0.isMemResult(ACTIVATE));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));
        eventually(cis, () -> mem0.isMemResult(DISCONNECT));

        mem0.stop();
        eventually(cis, () -> mem0.isStopped(true));

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testTwoClientsConnectingToCoreMember1() {
        CompInfoSet cis = new CompInfoSet();
        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        ClientMon mon0 = new ClientMon(_coder, cis.getMonInfo(0));
        mon0.start();
        eventually(cis, () -> mon0.isConnected(true));

        ClientMem mem0d0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0d0.start();
        eventually(cis, () -> mem0d0.isConnected(true));

        mon0.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon0.isActivesBitMask(NONE));

        mem0d0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE));
        eventually(cis, () -> mon0.isActivesBitMask(ZERO));

        ClientMem mem1d0 = new ClientMem(_coder, cis.getMemInfo(1, 0));
        mem1d0.start();
        eventually(cis, () -> mem1d0.isConnected(true));

        mem1d0.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d0.isMemResult(DEACTIVATE));
        eventually(cis, () -> mon0.isActivesBitMask(ZERO));

        mem0d0.unregisterFtMember(FT_GROUP, 0);
        eventually(cis, () -> mem0d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d0.isMemResult(ACTIVATE));
        eventually(cis, () -> mon0.isActivesBitMask(ZERO));

        mem1d0.unregisterFtMember(FT_GROUP, 1);
        eventually(cis, () -> mem1d0.isMemResult(DISCONNECT));
        eventually(cis, () -> mon0.isActivesBitMask(NONE));

        mem0d0.stop();
        mon0.stop();
        eventually(cis, () -> mon0.isStopped(true));
        mem1d0.stop();

        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testTwoClientsConnectingToCoreMember2() {
        CompInfoSet cis = new CompInfoSet();

        ClientMon mon0d0 = new ClientMon(_coder, cis.getMonInfo(0));
        mon0d0.start();
        mon0d0.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon0d0.isActivesBitMask(NONE));

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        eventually(cis, () -> mon0d0.isConnected(true));
        eventually(cis, () -> mon0d0.isActivesBitMask(NONE));

        ClientMem mem0d0 = new ClientMem(_coder, cis.getMemInfo(0));
        mem0d0.start();
        eventually(cis, () -> mem0d0.isConnected(true));

        mem0d0.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d0.isMemResult(ACTIVATE));
        eventually(cis, () -> mon0d0.isActivesBitMask(ZERO));

        ClientMem mem1d0 = new ClientMem(_coder, cis.getMemInfo(1, 0));
        mem1d0.start();
        eventually(cis, () -> mem1d0.isConnected(true));

        ClientMon mon1d0 = new ClientMon(_coder, cis.getMonInfo(1, 0));
        mon1d0.start();
        mon1d0.registerFtMonitor(FT_GROUP);
        eventually(cis, () -> mon1d0.isActivesBitMask(ZERO));

        mem1d0.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d0.isMemResult(DEACTIVATE));

        mon0d0.stop();

        mem0d0.stop();
        eventually(cis, () -> mem0d0.isStopped(true));
        eventually(cis, () -> mem1d0.isMemResult(ACTIVATE));

        eventually(cis, () -> mon1d0.isActivesBitMask(ZERO));

        mem1d0.stop();

        eventually(cis, () -> mon1d0.isActivesBitMask(NONE));

        d0.stop();

        eventually(cis, () -> mon1d0.isActivesBitMask(NONE));

        mon1d0.stop();

        tearDown(cis);
    }

    @Test
    public void testTwoClientsConnectingToNonCoreMember1() {
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

        ClientMem mem0d3 = new ClientMem(_coder, cis.getMemInfo(0, 3));
        mem0d3.start();
        eventually(cis, () -> mem0d3.isConnected(true));

        mem0d3.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d3.isMemResult(ACTIVATE));

        ClientMem mem1d3 = new ClientMem(_coder, cis.getMemInfo(1, 3));
        mem1d3.start();
        eventually(cis, () -> mem1d3.isConnected(true));

        mem1d3.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d3.isMemResult(DEACTIVATE));

        mem0d3.unregisterFtMember(FT_GROUP, 0);
        eventually(cis, () -> mem0d3.isMemResult(DISCONNECT));
        eventually(cis, () -> mem1d3.isMemResult(ACTIVATE));

        mem1d3.unregisterFtMember(FT_GROUP, 1);
        eventually(cis, () -> mem1d3.isMemResult(DISCONNECT));

        mem0d3.stop();
        mem1d3.stop();

        d3.stop();
        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testTwoClientsConnectingToNonCoreMember2() {
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

        ClientMem mem0d3 = new ClientMem(_coder, cis.getMemInfo(0, 3));
        mem0d3.start();
        eventually(cis, () -> mem0d3.isConnected(true));

        mem0d3.registerFtMember(FT_GROUP, 0, 1);
        eventually(cis, () -> mem0d3.isMemResult(ACTIVATE));

        ClientMem mem1d3 = new ClientMem(_coder, cis.getMemInfo(1, 3));
        mem1d3.start();
        eventually(cis, () -> mem1d3.isConnected(true));

        mem1d3.registerFtMember(FT_GROUP, 1, 1);
        eventually(cis, () -> mem1d3.isMemResult(DEACTIVATE));

        mem0d3.stop();
        eventually(cis, () -> mem1d3.isMemResult(ACTIVATE));

        mem1d3.unregisterFtMember(FT_GROUP, 1);
        eventually(cis, () -> mem1d3.isMemResult(DISCONNECT));

        mem1d3.stop();

        d3.stop();
        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testOneClientConnectingToSingularNonCoreMember() {
        CompInfoSet cis = new CompInfoSet();
        // d3 is not connected to any core members
        Daemon d3 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d3.start();
        eventually(cis, () -> d3.iAmCore(false));
        eventually(cis, () -> d3.isStarted(true));
        eventually(cis, () -> d3.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        // client connects to d3
        ClientMem mem3 = new ClientMem(_coder, cis.getMemInfo(3));
        mem3.start();
        eventually(cis, () -> mem3.isConnected(true));

        mem3.registerFtMember(FT_GROUP, 3, 1);
        // there are no active core members so the client receives a DISCONNECT message
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        mem3.unregisterFtMember(FT_GROUP, 3);

        mem3.stop();

        d3.stop();

        tearDown(cis);
    }

    @Test
    public void testOneClientConnectingToNonCoreMember1() {
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

        // client connects to d3
        ClientMem mem3 = new ClientMem(_coder, cis.getMemInfo(3));
        mem3.start();
        eventually(cis, () -> mem3.isConnected(true));

        mem3.registerFtMember(FT_GROUP, 3, 1);
        eventually(cis, () -> mem3.isMemResult(ACTIVATE));

        mem3.unregisterFtMember(FT_GROUP, 3);
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        mem3.stop();

        d3.stop();
        d0.stop();

        tearDown(cis);
    }

    @Test
    public void testOneClientConnectingToNonCoreMember2() {
        CompInfoSet cis = new CompInfoSet();

        // client connects to d3
        ClientMem mem3 = new ClientMem(_coder, cis.getMemInfo(3));
        mem3.start();
        eventually(cis, () -> mem3.isConnected(false));

        mem3.registerFtMember(FT_GROUP, 3, 1);
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        Daemon d31 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d31.start();
        eventually(cis, () -> d31.iAmCore(false));
        eventually(cis, () -> d31.isStarted(true));
        eventually(cis, () -> d31.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

        eventually(cis, () -> mem3.isConnected(true));
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        Daemon d0 = new Daemon(cis.getDInfo(0), cis.cc012(), 0, cis.getDUpgrade(0));
        d0.start();
        eventually(cis, () -> d0.iAmCore(true));
        eventually(cis, () -> d0.isStarted(true));
        eventually(cis, () -> d0.iAmPrimary(true, new MemberStatusEnum[] {UP, DOWN, DOWN}));

        eventually(cis, () -> d31.iAmPrimary(false, new MemberStatusEnum[] {UP, DOWN, DOWN}));
        eventually(cis, () -> mem3.isMemResult(ACTIVATE));

        d0.stop();
        eventually(cis, () -> d0.isStopped(true));

        eventually(cis, () -> d31.iAmPrimary(false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        Daemon d1 = new Daemon(cis.getDInfo(1), cis.cc012(), 0, cis.getDUpgrade(1));
        d1.start();
        eventually(cis, () -> d1.iAmCore(true));
        eventually(cis, () -> d1.isStarted(true));
        eventually(cis, () -> d1.iAmPrimary(true, new MemberStatusEnum[] {DOWN, UP, DOWN}));

        eventually(cis, () -> d31.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, DOWN}));
        eventually(cis, () -> mem3.isMemResult(ACTIVATE));

        d31.stop();
        eventually(cis, () -> d31.isStopped(true));
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));
        eventually(cis, () -> mem3.isConnected(false));

        Daemon d32 = new Daemon(cis.getDInfo(3), cis.cc012(), 0, cis.getDUpgrade(3));
        d32.start();
        eventually(cis, () -> d32.iAmCore(false));
        eventually(cis, () -> d32.isStarted(true));
        eventually(cis, () -> d32.iAmPrimary(false, new MemberStatusEnum[] {DOWN, UP, DOWN}));

        eventually(cis, () -> mem3.isConnected(true));
        eventually(cis, () -> mem3.isMemResult(ACTIVATE));

        mem3.unregisterFtMember(FT_GROUP, 3);
        eventually(cis, () -> mem3.isMemResult(DISCONNECT));

        mem3.registerFtMember(FT_GROUP, 3, 1);
        eventually(cis, () -> mem3.isMemResult(ACTIVATE));

        mem3.stop();
        d32.stop();
        d0.stop();

        tearDown(cis);
    }
}
