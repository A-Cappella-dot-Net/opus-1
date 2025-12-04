package net.a_cappella.devtools;

import org.eclipse.jetty.websocket.api.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class HandlersBySession {
    private static final Logger log = LoggerFactory.getLogger(HandlersBySession.class);

    private final ConcurrentMap<Session, SessionHandler> _sessionHandlersBySession = new ConcurrentHashMap<>();

    public void put(Session session, SessionHandler sessionHandler) {
        _sessionHandlersBySession.put(session, sessionHandler);
    }

    public void remove(Session session) {
        _sessionHandlersBySession.remove(session);
    }

    public void stop() {
        _sessionHandlersBySession.forEach((session, sessionHandler) -> sessionHandler.stop());
        log.info("SessionHandlers stopped");
    }
}
