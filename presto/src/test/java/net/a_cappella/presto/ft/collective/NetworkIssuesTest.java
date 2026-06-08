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

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ft.collective.proxy.NioProxy;
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.testagent.IdFromTo;
import net.a_cappella.presto.testagent.ProxyRouter;
import net.a_cappella.presto.testagent.ThreadMarker;
import org.junit.jupiter.api.*;

import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

@Tag("proxy-agent")
public class NetworkIssuesTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(22430);
    @Override
    protected AtomicInteger getPort() { return _port; }

    private NioProxy _proxy;
    private CompInfoSet _cis;

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        super.setUp(testInfo);
        ThreadMarker.setMark(null); // prevent stale marks from a prior test being inherited by daemon threads
        CollectiveMember.setUseVotedQuorum(true);
        _cis = new CompInfoSet();
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        super.tearDown(testInfo);
        stopProxy();
        tearDown(_cis);
        ProxyRouter.clear();
    }

    @Test
    public void testProxyStopStart() {
        ProxyRouter.redirect(Utils._localhost, new IdFromTo[] {idFromTo("d1", 0, 100)});
        startProxy();

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1}, 0);
        markSpawnedThreads("d0", () -> d0.start());
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1}, 0);
        markSpawnedThreads("d1", () -> d1.start());
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));

        stopProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));

        startProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP}));

        d0.stop();
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP}));

        d1.stop();
    }

    @Test
    public void testSplitBrain() {
        ProxyRouter.redirect(Utils._localhost,
                new IdFromTo[] {
                        idFromTo("d0", 1, 101),
                        idFromTo("d0", 2, 102),
                        idFromTo("d1", 0, 100),
                        idFromTo("d2", 0, 100)
                });
        startProxy();

        Daemon d2 = new Daemon(_cis, 2, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d2", () -> d2.start());
        eventually(d2, (d) -> d.iAmCore(true));
        eventually(d2, (d) -> d.isStarted(true));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d1", () -> d1.start());
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d0", () -> d0.start());
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        stopProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, DOWN, DOWN}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        startProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.stop();
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d2.stop();
    }

    @Test
    public void testManInTheMiddle() {
        ProxyRouter.redirect(Utils._localhost,
                new IdFromTo[] {
                        idFromTo("d0", 1, 101),
                        idFromTo("d1", 0, 100)
                });
        startProxy();

        Daemon d2 = new Daemon(_cis, 2, new int[] {0, 1, 2}, 0);
        d2.start();
        eventually(d2, (d) -> d.iAmCore(true));
        eventually(d2, (d) -> d.isStarted(true));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d1", () -> d1.start());
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d0", () -> d0.start());
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        stopProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        startProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.stop();
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d2.stop();
    }

    @Test
    public void testAsymmetricReachability1() {
        ProxyRouter.redirect(Utils._localhost, new IdFromTo[] { idFromTo("d0", 1, 101) });
        startProxy();

        Daemon d2 = new Daemon(_cis, 2, new int[] {0, 1, 2}, 0);
        d2.start();
        eventually(d2, (d) -> d.iAmCore(true));
        eventually(d2, (d) -> d.isStarted(true));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1, 2}, 0);
        d1.start();
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d0", () -> d0.start());
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        stopProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        startProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.stop();
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d2.stop();
    }

    @Test
    public void testAsymmetricReachability2() {
        ProxyRouter.redirect(Utils._localhost, new IdFromTo[] { idFromTo("d1", 0, 100) });
        startProxy();

        Daemon d2 = new Daemon(_cis, 2, new int[] {0, 1, 2}, 0);
        d2.start();
        eventually(d2, (d) -> d.iAmCore(true));
        eventually(d2, (d) -> d.isStarted(true));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1, 2}, 0);
        markSpawnedThreads("d1", () -> d1.start());
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1, 2}, 0);
        d0.start();
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        stopProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, DOWN, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        startProxy();

        eventually(d0, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {UP, UP, UP}));

        d0.stop();
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        d1.stop();
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        d2.stop();
    }

    private void startProxy() {
        if (_proxy == null) {
            _proxy = new NioProxy(ProxyRouter.forwards());
            _proxy.start();
        }
    }

    private void stopProxy() {
        if (_proxy != null) {
            _proxy.stop();
            _proxy = null;
        }
    }

    private IdFromTo idFromTo(String id, int fromPort, int toPort) {
        return new IdFromTo(id, _cis.getRealPort(fromPort), _cis.getRealPort(toPort));
    }

    private void markSpawnedThreads(String uniqueLabel, Runnable action) {
        ThreadMarker.setMark(uniqueLabel); action.run(); ThreadMarker.setMark(null);
    }

}
