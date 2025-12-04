package net.a_cappella.devtools;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.server.config.JettyWebSocketServletContainerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

public class ViewServer {
    private static final Logger log = LoggerFactory.getLogger(ViewServer.class);

    public final PrestoClient _client;
    public final ScheduledExecutorService _scheduler = Executors.newScheduledThreadPool(1);

    private final Server _server;
    public final HandlersBySession _handlersBySession = new HandlersBySession();

    public final VsUserManager _userManager;

    public ViewServer(PrestoClient client) {
        _client = client;
        _server = new Server(8080);
        _userManager = new VsUserManager(client);

        ShutdownHook.registerShutdownAction(() -> stop());
    }

    public static void main(String[] args) throws Exception {
        new ViewServer(new DummyPrestoClient()).init();
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