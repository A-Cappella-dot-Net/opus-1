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

import static net.a_cappella.presto.ft.collective.CollectiveMember.isUseConsensus;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

public class CollectiveUpgradeTest {

    private static final AtomicInteger _port = new AtomicInteger(20430);

    @Nested class WithConsensusTrueTests extends Tests {
        @BeforeEach void useConsensus() { CollectiveMember.setUseConsensus(true); }
    }

    @Nested class WithConsensusFalseTests extends Tests {
        @BeforeEach void useConsensus() { CollectiveMember.setUseConsensus(false); }
    }

    abstract static class Tests extends CollectiveTestBase {
        @Override protected AtomicInteger getPort() { return _port; }

        @Test
        public void testUpgradeChangesOrderOfCoreSet() {
            CompInfoSet cis = new CompInfoSet();

            // initial order: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            // order changes to: d2, d1, d0
            Daemon d2 = new Daemon(cis, 2, new int[] {2, 1, 0}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            d2.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));

            d1.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            // the latest upgraded configuration is remembered after a restart
            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {DOWN, DOWN, UP}));

            d0.stop(); // clean up 'upgraded' files

            tearDown(cis);
        }

        @Test
        public void testUpgradeReducesCoreSet1() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            // new set: d0, d1
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(false));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            d2.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            d1.stop();
            if (!CollectiveMember.isUseConsensus()) {
                eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN}));
            } else {
                eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
            }

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testUpgradeReducesCoreSet2() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            // new set: d0, d2
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 2}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d1, (d) -> d.iAmCore(false));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            d2.stop();
            eventually(d2, (d) -> d.isStopped());
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

            d1.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testUpgradeReducesCoreSet3() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            // new set: d1, d2
            Daemon d2 = new Daemon(cis, 2, new int[] {1, 2}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d) -> d.iAmCore(false));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            d2.stop();
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, !isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            d1.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testUpgradeEnhancesCoreSet1() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            // new set: d0, d1, d2
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 1);
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
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testUpgradeEnhancesCoreSet2() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1
            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {DOWN, UP}));

            // new set: d1, d2
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isUpgraded(1));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));

            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isUpgraded(1));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            d1.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, UP}));

            d2.stop();
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            d0.stop();

            tearDown(cis);
        }

        @Test
        public void testUpgradeShiftsCoreSet1() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

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

            // new set: d2, d3
            // Notice that there _must_ be a common 'core' member between two upgradable versions
            Daemon d3 = new Daemon(cis, 3, new int[] {2, 3}, 1);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(true));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d) -> d.iAmCore(false));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d) -> d.iAmCore(false));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            d2.restart(cis);
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.restart(cis);
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testUpgradeShiftsCoreSet2() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1, d2
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1, 2}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN, DOWN}));

            // new set: d2, d3
            // Notice that both d0 and d3 claim to be primary (since d3 and d0 do not communicate directly)
            Daemon d3 = new Daemon(cis, 3, new int[] {2, 3}, 1);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(true));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {DOWN, UP}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1, 2}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, DOWN}));

            // as soon as the common daemon is brought up it will upgrade itself and will upgrade any other daemons connected to it
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 0);
            d2.start();
            eventually(d2, (d) -> d.isUpgraded(1));
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d) -> d.isUpgraded(1));
            eventually(d0, (d) -> d.iAmCore(false));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d) -> d.isUpgraded(1));
            eventually(d1, (d) -> d.iAmCore(false));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            d2.restart(cis);
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.restart(cis);
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }

        @Test
        public void testUpgradeShiftsCoreSet3() {
            CompInfoSet cis = new CompInfoSet();

            // initial set: d0, d1
            Daemon d0 = new Daemon(cis, 0, new int[] {0, 1}, 0);
            d0.start();
            eventually(d0, (d) -> d.iAmCore(true));
            eventually(d0, (d) -> d.isStarted(true));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));

            Daemon d1 = new Daemon(cis, 1, new int[] {0, 1}, 0);
            d1.start();
            eventually(d1, (d) -> d.iAmCore(true));
            eventually(d1, (d) -> d.isStarted(true));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            // intermediate set: d0, d1, d2
            Daemon d2 = new Daemon(cis, 2, new int[] {0, 1, 2}, 1);
            d2.start();
            eventually(d2, (d) -> d.iAmCore(true));
            eventually(d2, (d) -> d.isStarted(true));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            eventually(d0, (d) -> d.isUpgraded(1));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
            eventually(d1, (d) -> d.isUpgraded(1));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

            // final set: d2, d3
            Daemon d3 = new Daemon(cis, 3, new int[] {2, 3}, 2);
            d3.start();
            eventually(d3, (d) -> d.iAmCore(true));
            eventually(d3, (d) -> d.isStarted(true));
            eventually(d3, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            eventually(d2, (d) -> d.isUpgraded(2));
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

            eventually(d0, (d) -> d.isUpgraded(2));
            eventually(d0, (d) -> d.iAmCore(false));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
            eventually(d1, (d) -> d.isUpgraded(2));
            eventually(d1, (d) -> d.iAmCore(false));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

            d3.stop();
            eventually(d3, (d) -> d.isStopped());

            d2.restart(cis);
            eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, !CollectiveMember.isUseConsensus(), new MemberStatusEnum[] {UP, DOWN}));
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

            d2.stop();
            eventually(d2, (d) -> d.isStopped());

            d0.restart(cis);
            eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d0.stop();
            eventually(d0, (d) -> d.isStopped());

            d1.restart(cis);
            eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN}));

            d1.stop();
            eventually(d1, (d) -> d.isStopped());

            tearDown(cis);
        }
    }
}
