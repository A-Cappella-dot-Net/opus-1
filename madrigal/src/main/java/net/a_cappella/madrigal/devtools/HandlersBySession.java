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
