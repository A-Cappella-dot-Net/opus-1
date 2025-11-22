package net.a_cappella.devtools;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.DefaultServlet;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.eclipse.jetty.websocket.server.config.JettyWebSocketServletContainerInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

public class ViewServer {
    private static final Logger log = LoggerFactory.getLogger(ViewServer.class);

    private final PrestoClient _client;
    private final Server _server;
    private final SessionHandler _sessionHandler;

    public ViewServer(PrestoClient client) {
        _client = client;
        _server = new Server(8080);
        _sessionHandler = new SessionHandler(_client);
        _sessionHandler.start();

        ShutdownHook.registerShutdownAction(() -> stop());
    }

    public static void main(String[] args) throws Exception {
        new ViewServer(new DummyPrestoClient()).init();
    }

    public void init() throws Exception {
        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");

        ServletHolder staticHolder = new ServletHolder("static", DefaultServlet.class);
        staticHolder.setInitParameter("resourceBase",
                ViewServer.class.getClassLoader().getResource("static").toExternalForm());
        staticHolder.setInitParameter("dirAllowed", "false");
        context.addServlet(staticHolder, "/");

        JettyWebSocketServletContainerInitializer.configure(context, (servletContext, wsContainer) -> {
            wsContainer.addMapping("/ws",
                    (servletUpgradeRequest, servletUpgradeResponse) -> _sessionHandler);
        });

        _server.setHandler(context);
        _server.start();
        _server.join();
    }

    public void stop() {
        log.info("Shutting down server...");
        try {
            _sessionHandler.stop();
            log.info("SessionHandler stopped");
        } catch (Exception e) {
            log.error("", e);
        }
        try {
            _server.stop();
            log.info("Server stopped");
        } catch (Exception e) {
            log.error("", e);
        }
    }

}