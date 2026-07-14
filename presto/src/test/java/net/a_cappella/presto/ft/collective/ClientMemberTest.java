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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.collective.CollectiveClient.NONE;
import static net.a_cappella.presto.ft.collective.CollectiveClient.ZERO;
import static net.a_cappella.presto.ft.constants.FtMsgOp.*;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class ClientMemberTest {

    private static final AtomicInteger _port = new AtomicInteger(18430);

    @Nested class WithVotedQuorumTests extends Tests {
        @BeforeEach void useVotedQuorum() { CollectiveMember.setUseVotedQuorum(true); }
    }

    @Nested class WithFirstAliveTests extends Tests {
        @BeforeEach void useFirstAlive() { CollectiveMember.setUseVotedQuorum(false); }
    }

    abstract static class Tests extends CollectiveTestBase {
        @Override protected AtomicInteger getPort() { return _port; }

        @Test
        public void testOneClientConnectingToCoreMember1() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem0.unregisterFtMember(FT_GROUP, 0);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            d0.stop();
            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testOneClientConnectingToCoreMember2() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testTwoClientsConnectingToCoreMember1() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMon mon0 = new ClientMon(cis, 0, 0);
            mon0.start();
            eventually(mon0, (m) -> m.isConnected(true));

            ClientMem mem0d0 = new ClientMem(cis, 0, 0);
            mem0d0.start();
            eventually(mem0d0, (m) -> m.isConnected(true));

            mon0.registerFtMonitor(FT_GROUP);
            eventually(mon0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1d0 = new ClientMem(cis, 1, 0);
            mem1d0.start();
            eventually(mem1d0, (m) -> m.isConnected(true));

            mem1d0.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0d0.unregisterFtMember(FT_GROUP, 0);
            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d0.unregisterFtMember(FT_GROUP, 1);
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d0.stop();
            mon0.stop();
            eventually(mon0, (m) -> m.isStopped(true));
            mem1d0.stop();

            d0.stop();
            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testTwoClientsConnectingToCoreMember2() {
            CompInfoSet cis = new CompInfoSet();

            ClientMon mon0d0 = new ClientMon(cis, 0, 0);
            mon0d0.start();
            mon0d0.registerFtMonitor(FT_GROUP);
            eventually(mon0d0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(mon0d0, (m) -> m.isConnected(true));
            eventually(mon0d0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            ClientMem mem0d0 = new ClientMem(cis, 0, 0);
            mem0d0.start();
            eventually(mem0d0, (m) -> m.isConnected(true));

            mem0d0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon0d0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1d0 = new ClientMem(cis, 1, 0);
            mem1d0.start();
            eventually(mem1d0, (m) -> m.isConnected(true));

            ClientMon mon1d0 = new ClientMon(cis, 1, 0);
            mon1d0.start();
            mon1d0.registerFtMonitor(FT_GROUP);
            eventually(mon1d0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d0.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            mon0d0.stop();

            mem0d0.stop();
            eventually(mem0d0, (m) -> m.isStopped(true));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            eventually(mon1d0, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d0.stop();

            eventually(mon1d0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            d0.stop();

            eventually(mon1d0, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon1d0.stop();

            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testTwoClientsConnectingToNonCoreMember1() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d3 = new ClientMem(cis, 0, 3);
            mem0d3.start();
            eventually(mem0d3, (m) -> m.isConnected(true));

            mem0d3.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            ClientMem mem1d3 = new ClientMem(cis, 1, 3);
            mem1d3.start();
            eventually(mem1d3, (m) -> m.isConnected(true));

            mem1d3.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            mem0d3.unregisterFtMember(FT_GROUP, 0);
            eventually(mem0d3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d3.unregisterFtMember(FT_GROUP, 1);
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem0d3.stop();
            mem1d3.stop();

            d3.stop();
            d0.stop();
            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testTwoClientsConnectingToNonCoreMember2() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d3 = new ClientMem(cis, 0, 3);
            mem0d3.start();
            eventually(mem0d3, (m) -> m.isConnected(true));

            mem0d3.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            ClientMem mem1d3 = new ClientMem(cis, 1, 3);
            mem1d3.start();
            eventually(mem1d3, (m) -> m.isConnected(true));

            mem1d3.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            mem0d3.stop();
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d3.unregisterFtMember(FT_GROUP, 1);
            eventually(mem1d3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem1d3.stop();

            d3.stop();
            d0.stop();
            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testOneClientConnectingToSingularNonCoreMember() {
            CompInfoSet cis = new CompInfoSet();
            // d3 is not connected to any core members
            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            // client connects to d3
            ClientMem mem3 = new ClientMem(cis, 3, 3);
            mem3.start();
            eventually(mem3, (m) -> m.isConnected(true));

            mem3.registerFtMember(FT_GROUP, 3, 1);
            // there are no active core members so the client receives a DISCONNECT message
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem3.unregisterFtMember(FT_GROUP, 3);

            mem3.stop();

            d3.stop();

            tearDown(cis);
        }

        @Test
        public void testOneClientConnectingToNonCoreMember1() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            // client connects to d3
            ClientMem mem3 = new ClientMem(cis, 3, 3);
            mem3.start();
            eventually(mem3, (m) -> m.isConnected(true));

            mem3.registerFtMember(FT_GROUP, 3, 1);
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem3.unregisterFtMember(FT_GROUP, 3);
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem3.stop();

            d3.stop();
            d0.stop();
            d1.stop();

            tearDown(cis);
        }

        @Test
        public void testOneClientConnectingToNonCoreMember2() {
            CompInfoSet cis = new CompInfoSet();

            // client connects to d3
            ClientMem mem3 = new ClientMem(cis, 3, 3);
            mem3.start();
            eventually(mem3, (m) -> m.isConnected(false));

            mem3.registerFtMember(FT_GROUP, 3, 1);
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            Daemon d3a = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3a.start();
            eventually(d3a, (d) -> d.iAmCore(false));
            eventually(d3a, (d) -> d.isStarted(true));
            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            eventually(mem3, (m) -> m.isConnected(true));
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, UP}));

            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, UP}));
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));
            if (CollectiveMember.isUseVotedQuorum()) {
                eventually(mem3, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY));
            } else {
                eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            }

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));

            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            d3a.stop();
            eventually(d3a, (d) -> d.isStopped());
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem3, (m) -> m.isConnected(false));

            Daemon d3b = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3b.start();
            eventually(d3b, (d) -> d.iAmCore(false));
            eventually(d3b, (d) -> d.isStarted(true));
            eventually(d3b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            eventually(mem3, (m) -> m.isConnected(true));
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem3.unregisterFtMember(FT_GROUP, 3);
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));

            mem3.registerFtMember(FT_GROUP, 3, 1);
            eventually(mem3, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem3.stop();
            d3b.stop();
            d1.stop();
            d2.stop();

            tearDown(cis);
        }
    }
}
