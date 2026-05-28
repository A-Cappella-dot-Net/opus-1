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

import static net.a_cappella.presto.ft.collective.CollectiveMember.isUseVotedQuorum;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveMemberTest {

    private static final AtomicInteger _port = new AtomicInteger(17430);

    @Nested class WithVotedQuorumTests extends Tests {
        @BeforeEach void useVotedQuorum() { CollectiveMember.setUseVotedQuorum(true); }
    }

    @Nested class WithFirstAliveTests extends Tests {
        @BeforeEach void useFirstAlive() { CollectiveMember.setUseVotedQuorum(false); }
    }

    abstract static class Tests extends CollectiveTestBase {
        @Override protected AtomicInteger getPort() { return _port; }

        @Test
        public void testSingleCore() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testSingleCore0() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testSingleCore1() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, UP, DOWN}));

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testSingleCore2() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testMultipleCoresPrimaryUnchanged() {
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
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            d2.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            d1.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testMultipleCoresPrimaryChanges() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            d0.stop();
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            d1.stop();
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            d2.stop();

            tearDown(cis);
        }

        @Test
        public void testSingleNonCore() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            d3.stop();

            tearDown(cis);
        }

        @Test
        public void testMultipleNonCores() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            Daemon d4 = new Daemon(cis, 4, new int[] {0, 1, 2}, 0);
            d4.start();
            eventually(d4, (d) -> d.iAmCore(false));
            eventually(d4, (d) -> d.isStarted(true));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            d3.stop();
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            d4.stop();

            tearDown(cis);
        }

        @Test
        public void testCoreNonCore() {
            CompInfoSet cis = new CompInfoSet();

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, DOWN}));

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testMultipleMixed() {
            CompInfoSet cis = new CompInfoSet();
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseVotedQuorum(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            Daemon d3 = new Daemon(cis, 3, new int[] {0, 1, 2}, 0);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(false));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            Daemon d4 = new Daemon(cis, 4, new int[] {0, 1, 2}, 0);
            d4.start();
            eventually(d4, (d) -> d.iAmCore(false));
            eventually(d4, (d) -> d.isStarted(true));
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            d3.stop();
            eventually(d4, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            d4.stop();
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            d2.stop();
            d1.stop();

            tearDown(cis);
        }
    }
}
