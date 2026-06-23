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

package net.a_cappella.madrigal.devtools;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.eclipse.jetty.websocket.server.config.JettyWebSocketServletContainerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

public class ViewServer {
    private static final Logger log = LoggerFactory.getLogger(ViewServer.class);

    public final PrestoClient _client;
    public final ScheduledExecutorService _scheduler = Executors.newScheduledThreadPool(1);
    public final HandlersBySession _handlersBySession = new HandlersBySession();
    public final VsUserManager _userManager;
    public final Map<String, TokenInfo> _tokenStore = new ConcurrentHashMap<>();

    private final Server _server;

    public ViewServer(PrestoClient client) {
        _client = client;
        _server = new Server(8080);
        _userManager = new VsUserManager(client);

        ShutdownHook.registerShutdownAction(() -> stop());
    }

    public void init() throws Exception {
        _client.waitUntilInitialized();

        _userManager.start();

        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");

        ServletHolder staticHolder = new ServletHolder("static", DefaultServlet.class);
        staticHolder.setInitParameter("resourceBase",
                ViewServer.class.getClassLoader().getResource("static").toExternalForm());
        staticHolder.setInitParameter("dirAllowed", "false");
        context.addServlet(staticHolder, "/");

        JettyWebSocketServletContainerInitializer.configure(context, (servletContext, wsContainer) -> {
            wsContainer.addMapping("/ws",
                    (servletUpgradeRequest, servletUpgradeResponse) -> new SessionHandler(this));
        });

        _server.setHandler(context);
        _server.start();
        _server.join();
    }

    public void stop() {
        log.info("Shutting down server...");
        _scheduler.shutdown();
        _handlersBySession.stop();
        try {
            _server.stop();
            log.info("Server stopped");
        } catch (Exception e) {
            log.error("", e);
        }
    }

}