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
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveUpgradeWithClientAndMonitorTest {

    private static final AtomicInteger _port = new AtomicInteger(21430);

    @Nested class WithVotedQuorumTests extends Tests {
        @BeforeEach void useVotedQuorum() { CollectiveMember.setUseVotedQuorum(true); }
    }

    @Nested class WithFirstAliveTests extends Tests {
        @BeforeEach void useFirstAlive() { CollectiveMember.setUseVotedQuorum(false); }
    }

    abstract static class Tests extends CollectiveTestBase {
        @Override protected AtomicInteger getPort() { return _port; }

        @Test
        public void testUpgradeCoresOrder() {
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

            d2.restart(cis, new int[] {2, 1, 0}, 1);
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            // only bit ZERO is set as mem1 is DEACTIVATEd
            notWithinReasonableTimeframe(mon2, (m, ctx) -> m.failIfBitIsSet(ctx, ONE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));
            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));

            // TODO separate unit test for this behavior
            d0.restart(cis);
            eventually(d0, (d) -> d.isStarted(true));

            eventually(mem0, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));
            eventually(mon2, (m, ctx) -> m.isActivesBitMask(ctx, ZERO));

            mem0.stop();
            eventually(mem0, (m) -> m.isStopped(true));

            eventually(mem1, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

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
        public void testUpgradeAddPrimary() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            ClientMem mem31 = new ClientMem(cis, 1, 3);
            mem31.start();
            eventually(mem31, (m) -> m.isConnected(true));

            ClientMon mon3 = new ClientMon(cis, 3, 3);
            mon3.start();
            eventually(mon3, (m) -> m.isConnected(true));

            mem31.registerFtMember(FT_GROUP, 1, 1);
            eventually(mem31, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));

            mon3.registerFtMonitor(FT_GROUP);
            eventually(mon3, (m, ctx) -> m.isActivesBitMask(ctx, ONE));

            Daemon d2 = new Daemon(cis, 2, new int[] {2, 0}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            ClientMem mem30 = new ClientMem(cis, 0, 3);
            mem30.start();
            eventually(mem30, (m) -> m.isConnected(true));

            mem30.registerFtMember(FT_GROUP, 0, 1);
            eventually(mem30, (m, ctx) -> m.isMemResult(ctx, ACTIVATE));
            eventually(mem31, (m, ctx) -> m.isMemResult(ctx, DEACTIVATE));



            mem31.stop();
            eventually(mem31, (m) -> m.isStopped(true));

            mem30.stop();
            eventually(mem30, (m) -> m.isStopped(true));

            mon3.stop();
            eventually(mon3, (m) -> m.isStopped(true));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }
    }
}
