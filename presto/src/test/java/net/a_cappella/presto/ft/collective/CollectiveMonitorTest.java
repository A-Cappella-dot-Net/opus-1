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

import static net.a_cappella.presto.ft.collective.CollectiveClient.*;
import static net.a_cappella.presto.ft.collective.CollectiveMember.isUseVotedQuorum;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DISCONNECT;
import static net.a_cappella.presto.ft.constants.FtMsgOp.NO_PRIMARY;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveMonitorTest {

    private static final AtomicInteger _port = new AtomicInteger(19430);

    @Nested class WithVotedQuorumTests extends Tests {
        @BeforeEach void useVotedQuorum() { CollectiveMember.setUseVotedQuorum(true); }
    }

    @Nested class WithFirstAliveTests extends Tests {
        @BeforeEach void useFirstAlive() { CollectiveMember.setUseVotedQuorum(false); }
    }

    abstract static class Tests extends CollectiveTestBase {
        @Override protected AtomicInteger getPort() { return _port; }

        @Test
        public void testMonitorFromCoreMachine_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            // bit mask ONE is not turned on as mem1 is not connected to the collective, even though mem1 is up
            notWithinReasonableTimeframe(mon2, (m, ctx) -> m.failIfBitIsSet(ctx, ONE));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testMonitorFromCoreMachine_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testMonitorFromNonCoreMachine_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon3 = new ClientMon(cis, 3, 3);
            mon3.start();
            eventually(mon3, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mon3.registerFtMonitor(FT_GROUP);
            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            // only bit ZERO is set as mem1 is DEACTIVATEd
            notWithinReasonableTimeframe(mon3, (m, ctx) -> m.failIfBitIsSet(ctx, ONE));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon3.stop();
            eventually(mon3, (m) -> m.isStopped(true));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testMonitorFromNonCoreMachine_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon3 = new ClientMon(cis, 3, 3);
            mon3.start();
            eventually(mon3, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));

            mon3.registerFtMonitor(FT_GROUP);
            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));

            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon3.stop();
            eventually(mon3, (m) -> m.isStopped(true));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testStopStartAllCores_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d2a = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2a.start();
            eventually(d2a, (d) -> d.iAmCore(true));
            eventually(d2a, (d) -> d.isStarted(true));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            d1a.stop();
            eventually(d1a, (d) -> d.isStopped());
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, UP}));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            Daemon d1b = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1b.start();
            eventually(d1b, (d) -> d.iAmCore(true));
            eventually(d1b, (d) -> d.isStarted(true));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            d2a.stop();
            eventually(d2a, (d) -> d.isStopped());

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d2b = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2b.start();
            eventually(d2b, (d) -> d.iAmCore(true));
            eventually(d2b, (d) -> d.isStarted(true));
            eventually(d2b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0b.stop();
            eventually(d0a, (d) -> d.isStopped());

            d1b.stop();
            eventually(d1b, (d) -> d.isStopped());

            d2b.stop();
            eventually(d2b, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testStopStartAllCores_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            Daemon d2a = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2a.start();
            eventually(d2a, (d) -> d.iAmCore(true));
            eventually(d2a, (d) -> d.isStarted(true));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            ClientMem mem0 = new ClientMem(cis, 0, 0);
            mem0.start();
            eventually(mem0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mem0.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            ClientMem mem1 = new ClientMem(cis, 1, 1);
            mem1.start();
            eventually(mem1, (m) -> m.isConnected(true));

            mem1.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d1a.stop();
            eventually(d1a, (d) -> d.isStopped());
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, UP}));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            Daemon d1b = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1b.start();
            eventually(d1b, (d) -> d.iAmCore(true));
            eventually(d1b, (d) -> d.isStarted(true));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d2a.stop();
            eventually(d2a, (d) -> d.isStopped());

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d2b = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2b.start();
            eventually(d2b, (d) -> d.iAmCore(true));
            eventually(d2b, (d) -> d.isStarted(true));
            eventually(d2b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem1.stop();
            eventually(mem1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0b.stop();
            eventually(d0a, (d) -> d.isStopped());

            d1b.stop();
            eventually(d1b, (d) -> d.isStopped());

            d2b.stop();
            eventually(d2b, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToCore0_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d0 = new ClientMem(cis, 0, 0);
            mem0d0.start();
            eventually(mem0d0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 0, 0);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            ClientMem mem1d0 = new ClientMem(cis, 1, 0);
            mem1d0.start();
            eventually(mem1d0, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d0.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d0.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());

            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0d0.stop();
            eventually(mem0d0, (m) -> m.isStopped(true));

            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d0.stop();
            eventually(mem1d0, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0b.stop();
            eventually(d0b, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToCore0_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d0 = new ClientMem(cis, 0, 0);
            mem0d0.start();
            eventually(mem0d0, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 0, 0);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            ClientMem mem1d0 = new ClientMem(cis, 1, 0);
            mem1d0.start();
            eventually(mem1d0, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d0.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d0.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());

            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(mem0d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1d0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem0d0.stop();
            eventually(mem0d0, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            mem1d0.stop();
            eventually(mem1d0, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0b.stop();
            eventually(d0b, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToCore1_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d1 = new ClientMem(cis, 0, 1);
            mem0d1.start();
            eventually(mem0d1, (m) -> m.isConnected(true));

            ClientMem mem1d1 = new ClientMem(cis, 1, 1);
            mem1d1.start();
            eventually(mem1d1, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 1, 1);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d1.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d1.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            d1a.stop();
            eventually(d1a, (d) -> d.isStopped());

            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d1b = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1b.start();
            eventually(d1b, (d) -> d.iAmCore(true));
            eventually(d1b, (d) -> d.isStarted(true));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0d1.stop();
            eventually(mem0d1, (m) -> m.isStopped(true));

            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d1.stop();
            eventually(mem1d1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d1b.stop();
            eventually(d1b, (d) -> d.isStopped());

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToCore1_1ActiveGoal_bounce_d0() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d1 = new ClientMem(cis, 0, 1);
            mem0d1.start();
            eventually(mem0d1, (m) -> m.isConnected(true));

            ClientMem mem1d1 = new ClientMem(cis, 1, 1);
            mem1d1.start();
            eventually(mem1d1, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 1, 1);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d1.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d1.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());

//    	eventually(cis, () -> mem0.isAction(ACTIVATE));
//    	eventually(cis, () -> mem1.isAction(DEACTIVATE));
//    	eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, 1));

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

//    	eventually(cis, () -> mem0.isAction(ACTIVATE));
//    	eventually(cis, () -> mem1.isAction(DEACTIVATE));
//    	eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, 1));

            mem0d1.stop();
            eventually(mem0d1, (m) -> m.isStopped(true));

            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d1.stop();
            eventually(mem1d1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d0b.stop();
            eventually(d0b, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToCore1_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            ClientMem mem0d1 = new ClientMem(cis, 0, 1);
            mem0d1.start();
            eventually(mem0d1, (m) -> m.isConnected(true));

            ClientMem mem1d1 = new ClientMem(cis, 1, 1);
            mem1d1.start();
            eventually(mem1d1, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 1, 1);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d1.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d1.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d1a.stop();
            eventually(d1a, (d) -> d.isStopped());

            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d1b = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1b.start();
            eventually(d1b, (d) -> d.iAmCore(true));
            eventually(d1b, (d) -> d.isStarted(true));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(mem0d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1d1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem0d1.stop();
            eventually(mem0d1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            mem1d1.stop();
            eventually(mem1d1, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d1b.stop();
            eventually(d1b, (d) -> d.isStopped());

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToNonCore_1ActiveGoal() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            Daemon d2a = new Daemon(cis, 2, new int[] {0, 1}, 0);
            d2a.start();
            eventually(d2a, (d) -> d.iAmCore(false));
            eventually(d2a, (d) -> d.isStarted(true));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            ClientMem mem0d2 = new ClientMem(cis, 0, 2);
            mem0d2.start();
            eventually(mem0d2, (m) -> m.isConnected(true));

            ClientMem mem1d2 = new ClientMem(cis, 1, 2);
            mem1d2.start();
            eventually(mem1d2, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d2.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d2.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            d2a.stop();
            eventually(d2a, (d) -> d.isStopped());

            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d2b = new Daemon(cis, 2, new int[] {0, 1}, 0);
            d2b.start();
            eventually(d2b, (d) -> d.iAmCore(false));
            eventually(d2b, (d) -> d.isStarted(true));
            eventually(d2b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0d2.stop();
            eventually(mem0d2, (m) -> m.isStopped(true));

            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mem1d2.stop();
            eventually(mem1d2, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d2b.stop();
            eventually(d2b, (d) -> d.isStopped());

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testAllConnectedToNonCore_2ActiveGoals() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            Daemon d2a = new Daemon(cis, 2, new int[] {0, 1}, 0);
            d2a.start();
            eventually(d2a, (d) -> d.iAmCore(false));
            eventually(d2a, (d) -> d.isStarted(true));
            eventually(d2a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            ClientMem mem0d2 = new ClientMem(cis, 0, 2);
            mem0d2.start();
            eventually(mem0d2, (m) -> m.isConnected(true));

            ClientMem mem1d2 = new ClientMem(cis, 1, 2);
            mem1d2.start();
            eventually(mem1d2, (m) -> m.isConnected(true));

            ClientMon mon2 = new ClientMon(cis, 2, 2);
            mon2.start();
            eventually(mon2, (m) -> m.isConnected(true));

            mon2.registerFtMonitor(FT_GROUP);
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0d2.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1d2.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            d2a.stop();
            eventually(d2a, (d) -> d.isStopped());

            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            Daemon d2b = new Daemon(cis, 2, new int[] {0, 1}, 0);
            d2b.start();
            eventually(d2b, (d) -> d.iAmCore(false));
            eventually(d2b, (d) -> d.isStarted(true));
            eventually(d2b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(mem0d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1d2, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem0d2.stop();
            eventually(mem0d2, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            mem1d2.stop();
            eventually(mem1d2, (m) -> m.isStopped(true));

            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon2.stop();
            eventually(mon2, (m) -> m.isStopped(true));

            d2b.stop();
            eventually(d2b, (d) -> d.isStopped());

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }


        @Test
        public void testCoreNonCoreMonitoring() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0a = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0a.start();
            eventually(d0a, (d) -> d.iAmCore(true));
            eventually(d0a, (d) -> d.isStarted(true));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1a = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1a.start();
            eventually(d1a, (d) -> d.iAmCore(true));
            eventually(d1a, (d) -> d.isStarted(true));
            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0a, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            Daemon d3a = new Daemon(cis, 3, new int[] {0, 1}, 0);
            d3a.start();
            eventually(d3a, (d) -> d.iAmCore(false));
            eventually(d3a, (d) -> d.isStarted(true));
            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            Daemon d4 = new Daemon(cis, 4, new int[] {0, 1}, 0);
            d4.start();
            eventually(d4, (d) -> d.iAmCore(false));
            eventually(d4, (d) -> d.isStarted(true));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            ClientMem mem0a = new ClientMem(cis, 0, 0);
            mem0a.start();
            eventually(mem0a, (m) -> m.isConnected(true));

            ClientMem mem1a = new ClientMem(cis, 1, 1);
            mem1a.start();
            eventually(mem1a, (m) -> m.isConnected(true));

            ClientMem mem3a = new ClientMem(cis, 3, 3);
            mem3a.start();
            eventually(mem3a, (m) -> m.isConnected(true));

            ClientMon mon4 = new ClientMon(cis, 4, 4);
            mon4.start();
            eventually(mon4, (m) -> m.isConnected(true));

            mon4.registerFtMonitor(FT_GROUP);
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem0a.registerFtMember(FT_GROUP, 0, 2);
            eventually(mem0a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 1));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem1a.registerFtMember(FT_GROUP, 1, 2);
            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            mem3a.registerFtMember(FT_GROUP, 3, 2);
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart d0
            d0a.stop();
            eventually(d0a, (d) -> d.isStopped());

            eventually(d1a, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, UP}));
            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));

            eventually(mem0a, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            if (isUseVotedQuorum()) {
                eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY));
                eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, DK));
            } else {
                eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
                eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ONE|THREE));
            }

            Daemon d0b = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0b.start();
            eventually(d0b, (d) -> d.iAmCore(true));
            eventually(d0b, (d) -> d.isStarted(true));
            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            eventually(mem0a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart mem0
            mem0a.stop();
            eventually(mem0a, (m) -> m.isStopped(true));

            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ONE|THREE));

            ClientMem mem0b = new ClientMem(cis, 0, 0);
            mem0b.start();
            eventually(mem0b, (m) -> m.isConnected(true));

            mem0b.registerFtMember(FT_GROUP, 0, 2);

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart d1
            d1a.stop();
            eventually(d1a, (d) -> d.isStopped());

            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN}));
            eventually(d3a, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            if (isUseVotedQuorum()) {
                eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY, 0, 0));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, DK));
            } else {
                eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|THREE));
            }

            Daemon d1b = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1b.start();
            eventually(d1b, (d) -> d.iAmCore(true));
            eventually(d1b, (d) -> d.isStarted(true));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(mem1a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart mem1
            mem1a.stop();
            eventually(mem1a, (m) -> m.isStopped(true));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|THREE));

            ClientMem mem1b = new ClientMem(cis, 1, 1);
            mem1b.start();
            eventually(mem1b, (m) -> m.isConnected(true));

            mem1b.registerFtMember(FT_GROUP, 1, 2);

            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart d3
            d3a.stop();
            eventually(d3a, (d) -> d.isStopped());

            eventually(d0b, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));
            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            Daemon d3b = new Daemon(cis, 3, new int[] {0, 1}, 0);
            d3b.start();
            eventually(d3b, (d) -> d.iAmCore(false));
            eventually(d3b, (d) -> d.isStarted(true));
            eventually(d3b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3a, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // restart mem3
            mem3a.stop();
            eventually(mem3a, (m) -> m.isStopped(true));

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            ClientMem mem3b = new ClientMem(cis, 3, 3);
            mem3b.start();
            eventually(mem3b, (m) -> m.isConnected(true));

            mem3b.registerFtMember(FT_GROUP, 3, 2);

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
            eventually(mem3b, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ZERO|ONE));

            // shut down everything

            d0b.stop();
            eventually(d0b, (d) -> d.isStopped());

            eventually(d1b, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, UP}));
            eventually(d3b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));

            eventually(mem0b, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            if (isUseVotedQuorum()) {
                eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY));
                eventually(mem3b, (m, ctx) -> m.isMemResult(ctx, NO_PRIMARY));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, DK));
            } else {
                eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 0, 2));
                eventually(mem3b, (m, ctx) -> m.isMemResult(ctx, ACTIVATE, 1, 2));
                eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, ONE|THREE));
            }

            mem0b.stop();
            eventually(mem0b, (m) -> m.isStopped(true));

            d1b.stop();
            eventually(d1b, (d) -> d.isStopped());

            eventually(d3b, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            eventually(mem1b, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mem3b, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem1b.stop();
            eventually(mem1b, (m) -> m.isStopped(true));

            d3b.stop();
            eventually(d3b, (d) -> d.isStopped());

            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            eventually(mem3b, (m, ctx) -> m.isMemResult(ctx, DISCONNECT));
            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mem3b.stop();
            eventually(mem3b, (m) -> m.isStopped(true));

            d4.stop();
            eventually(d4, (d) -> d.isStopped());

            eventually(mon4, (m, ctx) -> m.isActivesBitMask(ctx, NONE));

            mon4.stop();
            eventually(mon4, (m) -> m.isStopped(true));

            tearDown(cis);
        }
    }
}
