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
import net.a_cappella.presto.ft.constants.MemberStatusEnum;
import net.a_cappella.presto.testagent.ProxyRouter;
import net.a_cappella.presto.testagent.ThreadMarker;
import org.junit.jupiter.api.*;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.concurrent.atomic.AtomicInteger;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.DOWN;
import static net.a_cappella.presto.ft.constants.MemberStatusEnum.UP;

@Tag("proxy-agent")
public class NetworkIssuesTest extends CollectiveTestBase {

    private static final AtomicInteger _port = new AtomicInteger(22430);
    @Override
    protected AtomicInteger getPort() { return _port; }

    private NioTcpProxy _proxy;
    private CompInfoSet _cis;

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        super.setUp(testInfo);
        CollectiveMember.setUseVotedQuorum(true);
        _cis = new CompInfoSet();
        startProxy();
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        super.tearDown(testInfo);
        stopProxy();
        tearDown(_cis);
        ProxyRouter.clear();
    }

    @Test
    public void testSplitBrain() {
        ProxyRouter.redirect("d0", redirect(_cis, 1, 101));
        ProxyRouter.redirect("d0", redirect(_cis, 2, 102));
        ProxyRouter.redirect("d1", redirect(_cis, 0, 100));
        ProxyRouter.redirect("d2", redirect(_cis, 0, 100));

        Daemon d2 = new Daemon(_cis, 2, new int[] {0, 1, 2}, 0);
        ThreadMarker.setMark("d2"); d2.start();
        eventually(d2, (d) -> d.iAmCore(true));
        eventually(d2, (d) -> d.isStarted(true));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, DOWN, UP}));

        Daemon d1 = new Daemon(_cis, 1, new int[] {0, 1, 2}, 0);
        ThreadMarker.setMark("d1"); d1.start();
        eventually(d1, (d) -> d.iAmCore(true));
        eventually(d1, (d) -> d.isStarted(true));
        eventually(d1, (d, ctx) -> d.iAmPrimary(ctx, true, new MemberStatusEnum[] {DOWN, UP, UP}));
        eventually(d2, (d, ctx) -> d.iAmPrimary(ctx, false, new MemberStatusEnum[] {DOWN, UP, UP}));

        Daemon d0 = new Daemon(_cis, 0, new int[] {0, 1, 2}, 0);
        ThreadMarker.setMark("d0"); d0.start();
        eventually(d0, (d) -> d.iAmCore(true));
        eventually(d0, (d) -> d.isStarted(true));
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
        _proxy = new NioTcpProxy(forward(_cis,new int[][] {{100,0}, {101,1}, {102,2}}));
        _proxy.start();
    }

    private void stopProxy() {
        if (_proxy != null) {
            _proxy.stop();
            _proxy = null;
        }
    }

    private SocketAddress address(CompInfoSet cis, int port) {
        return new InetSocketAddress(Utils._localhost, cis.getRealPort(port));
    }

    private int[][] forward(CompInfoSet cis, int[][] fromToList) {
        int[][] realFromToList = new int[fromToList.length][];
        for (int i = 0; i < fromToList.length; i++) {
            realFromToList[i] = new int[2];
            realFromToList[i][0] = cis.getRealPort(fromToList[i][0]);
            realFromToList[i][1] = cis.getRealPort(fromToList[i][1]);
        }
        return realFromToList;
    }

    private SocketAddress[] redirect(CompInfoSet cis, int fromPort, int toPort) {
        SocketAddress[] fromTo = new SocketAddress[2];
        fromTo[0] = address(cis, fromPort);
        fromTo[1] = address(cis, toPort);
        return fromTo;
    }

}
