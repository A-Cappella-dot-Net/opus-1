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

import com.google.gson.*;
import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.madrigal.devtools.obj.DevToolsConstants;
import net.a_cappella.madrigal.devtools.obj.WebSocketMsgCoder;
import net.a_cappella.madrigal.devtools.obj.WebSocketMsgObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.WebSocketListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

public class SessionHandler implements WebSocketListener {
    private static final Logger log = LoggerFactory.getLogger(SessionHandler.class);

    private static final ObjectManager _objectManager = ObjectManager.getInstance();
    static {
        try {
            MsgInstantiator webSocketMsgInstantiator = new MsgInstantiator(WebSocketMsgObj.class.getName(), WebSocketMsgCoder.class.getName());

            _objectManager.setMsgInstantiators(Arrays.asList(
                    webSocketMsgInstantiator
            ));
            _objectManager.setMsgPools(Arrays.asList(
                    new Pool<Msg>(webSocketMsgInstantiator, 10, 10)
            ));
        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    private static final ThreadLocal<WebSocketMsgObj> _webSocketMsgThreadLocal = new ThreadLocal<>() {
        public WebSocketMsgObj initialValue() {
            return new WebSocketMsgObj();
        }
        public WebSocketMsgObj get() {
            WebSocketMsgObj obj = super.get();
            obj.reset();
            return obj;
        }
    };

    public final PrestoClient _client;
    private final ScheduledExecutorService _scheduler;
    private final HandlersBySession _handlersBySession;
    private final VsUserManager _userManager;
    private final Map<String, TokenInfo> _tokenStore;

    public String _remote = "unknown";
    private Gson _gsonOut = new GsonBuilder()
            .registerTypeAdapter(Double.class, (JsonSerializer<Double>) (src, typeOfSrc, context) -> {
                if (src.isNaN()) return new JsonPrimitive("");
                if (src.isInfinite()) return new JsonPrimitive(src > 0 ? "Inf" : "-Inf");
                return new JsonPrimitive(src);
            })
            .registerTypeAdapter(Float.class, (JsonSerializer<Float>) (src, typeOfSrc, context) -> {
                if (src.isNaN()) return new JsonPrimitive("");
                if (src.isInfinite()) return new JsonPrimitive(src > 0 ? "Inf" : "-Inf");
                return new JsonPrimitive(src);
            })
            .registerTypeHierarchyAdapter(Enum.class, (JsonSerializer<Enum>) (src, typeOfSrc, context) -> {
                String enumName = src.name();
                if ("NULL_VAL".equals(enumName)) return new JsonPrimitive("");
                return new JsonPrimitive(src.name());
            })
            .registerTypeAdapter(PTimestamp.class, new PTimestampSerializer())
            .registerTypeAdapter(PTime.class, new PTimeSerializer())
            .registerTypeAdapter(PDate.class, new PDateSerializer())
            .registerTypeAdapter(PNanos.class, new PNanosSerializer())
            .create();
    private Gson _gsonIn = new GsonBuilder()
            .registerTypeAdapter(PTimestamp.class, new PTimestampSerializer())
            .registerTypeAdapter(PTime.class, new PTimeSerializer())
            .registerTypeAdapter(PDate.class, new PDateSerializer())
            .registerTypeAdapter(PNanos.class, new PNanosSerializer())
            .create();

    public Session _session;
    public String _host;
    private ScheduledFuture<?> _pingTask;

    public String _username;
    public String _password;
    public boolean _isAuthenticated = false;

    private SubscriberHandler _subscriberHandler;
    private PublisherHandler _publisherHandler;

    private final String _webSocketMsgSubSql = "select * from " + DevToolsConstants.SUBJ_WEBSOCKET_MSG + " where remote='%s'";

    public SessionHandler(ViewServer viewServer) {
        _client = viewServer._client;
        _scheduler = viewServer._scheduler;
        _handlersBySession = viewServer._handlersBySession;
        _userManager = viewServer._userManager;
        _tokenStore = viewServer._tokenStore;
    }

    public void start() {
        long period = _session.getIdleTimeout().getSeconds() - 1;
        ByteBuffer keepalive = ByteBuffer.wrap("keepalive".getBytes());
        _pingTask = _scheduler.scheduleAtFixedRate(() -> {
            try {
                if (_session.isOpen()) {
                    log.trace("{} Sending ping", _remote);
                    _session.getRemote().sendPing(keepalive);
                }
            } catch (Exception e) {
                log.error("{} Failed to send ping: {}", _remote, e.getMessage());
            }
        }, period, period, TimeUnit.SECONDS);

        try {
            _client.subscribe(String.format(_webSocketMsgSubSql, _remote), (obj, subsId) -> {
                onWebSocketMessage((WebSocketMsgObj) obj);
            });
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

    }

    public void stop() {
        _handlersBySession.remove(_session);
        _userManager.onSessionEnd(this);

        // Cancel the ping task
        if (_pingTask != null) {
            _pingTask.cancel(false);
        }

        _isAuthenticated = false;

        if (_subscriberHandler != null) {
            _subscriberHandler.resetTabs();
        }
        if (_publisherHandler != null) {
            _publisherHandler.resetTabs();
        }
    }

    @Override
    public void onWebSocketConnect(Session session) {
        _session = session;
        _host = ((InetSocketAddress) session.getRemoteAddress()).getHostName();
        _handlersBySession.put(session, this);
        _remote = session.getRemoteAddress().toString();

        log.info("{} New connection", _remote);
        start();
    }

    @Override
    public void onWebSocketClose(int statusCode, String reason) {
        log.info("{} Connection closed. User: {}, Status Code: {}, Reason: {}", _remote, _username, statusCode, reason);
        stop();
    }

    @Override
    public void onWebSocketError(Throwable error) {
        log.error("{} WebSocket error {}", _remote, error.getMessage());
    }

    @Override
    public void onWebSocketText(String message) {
        WebSocketMsgObj obj = _webSocketMsgThreadLocal.get();
        obj.set(_remote, message);
        try {
            _client.loopback(obj);
        } catch (Exception e) {
            log.error("{}", _remote, e);
        }
    }

    public void onWebSocketMessage(WebSocketMsgObj obj) {
        // it is guaranteed to be my message because of the where clause
        String message = obj.getMsg();

        try {
            JsonObject msg = _gsonIn.fromJson(message, JsonObject.class);
            String type = msg.get("type").getAsString();

            switch (type) {
                case "login":
                    log.debug("{} received {}", _remote, msg);
                    handleLogin(msg);
                    break;
                case "reauth":
                    log.debug("{} received {}", _remote, msg);
                    handleReauth(msg);
                    break;
                case "logout":
                    log.debug("{} received {}", _remote, msg);
                    handleLogout();
                    break;
                case "request_token":
                    log.debug("{} received {}", _remote, msg);
                    handleRequestToken();
                    break;
                case "auth_with_token":
                    log.debug("{} received {}", _remote, msg);
                    handleAuthWithToken(msg);
                    break;
                case "heartbeat":
                    JsonObject response = new JsonObject();
                    response.addProperty("type", "pong");

                    sendMessage(response, false);
                    break;
                default:
                    log.debug("{} received {}", _remote, msg);
                    if (_isAuthenticated) {
                        String mode = msg.has("mode") ? msg.get("mode").getAsString() : "null";
                        if ("subscriber".equals(mode)) {
                            if (_subscriberHandler == null) {
                                _subscriberHandler = new SubscriberHandler(this);
                            }
                            _subscriberHandler.handleAuthenticatedMessage(msg);
                        } else if ("publisher".equals(mode)) {
                            if (_publisherHandler == null) {
                                _publisherHandler = new PublisherHandler(this, _client);
                            }
                            _publisherHandler.handleAuthenticatedMessage(msg);
                        } else if (_subscriberHandler != null) {
                            _subscriberHandler.handleAuthenticatedMessage(msg);
                        } else if (_publisherHandler != null) {
                            _publisherHandler.handleAuthenticatedMessage(msg);
                        } else {
                            log.error("{} Unknown mode: {}", _remote, mode);
                        }
                    } else {
                        sendError("Not authenticated", null);
                    }
                    break;
            }
        } catch (Exception e) {
            log.error("{}", _remote, e);
            sendError(e.getMessage(), null);
        }
    }

    public void authenticated(String uid, String pwd) {
        _username = uid;
        _password = pwd;
        _isAuthenticated = true;
    }

    public void notAuthenticated(String uid, String pwd) {
        _username = uid;
        _password = pwd;
        _isAuthenticated = false;
    }

    public void forceLogout() {
        _isAuthenticated = false;
        resetTabs();
        sendError("Not authenticated", null);
    }

    private void handleLogin(JsonObject msg) {
        String username = msg.get("username").getAsString();
        String password = msg.get("password").getAsString();

        _userManager.login(this, username, password);
    }

    private void handleReauth(JsonObject msg) {
        String username = msg.get("username").getAsString();

        if (_userManager.reauth(this, username)) {
            _isAuthenticated = true;
            log.info("{} User re-authenticated: {}", _remote, username);
        } else {
            sendError("Not authenticated", "reauth");
        }
    }

    private void handleLogout() {
        log.info("{} User logged out: {}", _remote, _username);

        _userManager.logout(this, _username, _password);

        _username = null;
        _password = null;
        _isAuthenticated = false;

        resetTabs();
    }

    public void resetTabs() {
        if (_subscriberHandler != null) {
            _subscriberHandler.resetTabs();
        }
        if (_publisherHandler != null) {
            _publisherHandler.resetTabs();
        }
    }

    private void handleRequestToken() {
        if (!_isAuthenticated) {
            sendError("Not authenticated", "token_request");
            return;
        }

        String token = UUID.randomUUID().toString();
        long expiryTime = System.currentTimeMillis() + 30000;

        _tokenStore.put(token, new TokenInfo(_username, expiryTime));

        // Send token back to client
        JsonObject response = new JsonObject();
        response.addProperty("type", "token_response");
        response.addProperty("token", token);

        sendMessage(response);
    }

    private void handleAuthWithToken(JsonObject msg) {
        String token = msg.get("token").getAsString();
        TokenInfo tokenInfo = _tokenStore.get(token);

        if (tokenInfo == null || tokenInfo.isExpired()) {
            sendError("Invalid or expired token", "token_auth");
            return;
        }

        _tokenStore.remove(token);

        // Authenticate this session
        _username = tokenInfo.getUsername();
        _isAuthenticated = true;

        JsonObject response = new JsonObject();
        response.addProperty("type", "auth_success");
        response.addProperty("username", _username);

        sendMessage(response);
    }

    private void sendError(String errorMessage, String context) {
        JsonObject error = new JsonObject();
        error.addProperty("type", "error");
        error.addProperty("message", errorMessage);
        if (context != null) error.addProperty("context", context);
        sendMessage(error);
    }

    public void send(Map<String, Object> response) {
        log.debug("{} sending {}", _remote, response);
        try {
            if (_session != null && _session.isOpen()) {
                _session.getRemote().sendString(_gsonOut.toJson(response));
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public void sendMessage(JsonObject jsonObject) {
        sendMessage(jsonObject, true);
    }
    public void sendMessage(JsonObject jsonObject, boolean logOp) {
        String message = jsonObject.toString();
        if (logOp) log.debug("{} sending {}", _remote, message);
        try {
            if (_session != null && _session.isOpen()) {
                _session.getRemote().sendString(message);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    // TODO consider alternative to sending net.a_cappella.madrigal.devtools.ColumnDef object
    private void sendMetaData(String tabId) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "meta_data");
        response.addProperty("tabId", tabId);
        response.addProperty("mode", "subscriber");
        response.addProperty("totalRows", 1000);
        response.addProperty("totalCols", 5);

        // Build columns array with type information
        JsonArray columnsArray = new JsonArray();

        // Column 1: Integer ID
        JsonObject col1 = new JsonObject();
        col1.addProperty("name", "ID");
        col1.addProperty("width", 100);
        col1.addProperty("type", "integer");
        col1.addProperty("align", "right");
        columnsArray.add(col1);

        // Column 2: Decimal Price
        JsonObject col2 = new JsonObject();
        col2.addProperty("name", "Price");
        col2.addProperty("width", 120);
        col2.addProperty("type", "decimal");
        col2.addProperty("decimals", 2);
        col2.addProperty("align", "right");
        columnsArray.add(col2);

        // Column 3: DateTime Timestamp
        JsonObject col3 = new JsonObject();
        col3.addProperty("name", "Timestamp");
        col3.addProperty("width", 180);
        col3.addProperty("type", "datetime");
        col3.addProperty("format", "short"); // or "ISO", "locale", "date", "time"
        columnsArray.add(col3);

        // Column 4: Boolean Active
        JsonObject col4 = new JsonObject();
        col4.addProperty("name", "Active");
        col4.addProperty("width", 80);
        col4.addProperty("type", "boolean");
        col4.addProperty("align", "center");
        columnsArray.add(col4);

        // Column 5: String Name
        JsonObject col5 = new JsonObject();
        col5.addProperty("name", "Name");
        col5.addProperty("width", 200);
        col5.addProperty("type", "string");
        col5.addProperty("align", "left");
        columnsArray.add(col5);

        response.add("columns", columnsArray);

        sendMessage(response);
    }
}
