package net.a_cappella.devtools;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.madrigal.user.IUserManagerClient;
import net.a_cappella.presto.ps.AeronClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.WebSocketListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.*;

public class SessionHandler implements WebSocketListener {
    private static final Logger log = LoggerFactory.getLogger(SessionHandler.class);

    public final PrestoClient _client;
    private IUserManagerClient _userMgr;

    private Session _session;
    public String _remote = "unknown";

    private String _username;
    private String _password;
    private boolean _isAuthenticated = false;

    Gson _gsonOut = new GsonBuilder()
            .registerTypeAdapter(PTimestamp.class, new PTimestampSerializer())
            .registerTypeAdapter(PTime.class, new PTimeSerializer())
            .registerTypeAdapter(PDate.class, new PDateSerializer())
            .registerTypeAdapter(PNanos.class, new PNanosSerializer())
            .create();
    Gson _gsonIn = new GsonBuilder()
            .registerTypeAdapter(PTimestamp.class, new PTimestampSerializer())
            .registerTypeAdapter(PTime.class, new PTimeSerializer())
            .registerTypeAdapter(PDate.class, new PDateSerializer())
            .registerTypeAdapter(PNanos.class, new PNanosSerializer())
            .create();

    private final ScheduledExecutorService _scheduler;
    private final ConcurrentMap<Session, SessionHandler> _sessionHandlersBySession;
    private ScheduledFuture<?> _pingTask;

    private SubscriberHandler _subscriberHandler;
    private PublisherHandler _publisherHandler;

    public TriConsumer<Boolean, String, String> _notifyGui = (success, uid, pwd) -> {
        if (success) {
            loginSucceeded(uid, pwd);
        } else {
            loginFailed(uid, pwd);
        }
    };

    public SessionHandler(ViewServer viewServer) {
        _client = viewServer._client;
        _scheduler = viewServer._scheduler;
        _sessionHandlersBySession = viewServer._sessionHandlersBySession;
    }

    public void start() {
        if (_client instanceof AeronClient) {
            _userMgr = new MyUserManagerClient(_client, _notifyGui);
        } else {
            _userMgr = new DummyUserManagerClient(_notifyGui);
        }
        _userMgr.adjustClId(":" + ((InetSocketAddress) _session.getRemoteAddress()).getPort());
        _userMgr.start();

        long period = _session.getIdleTimeout().getSeconds() - 1;
        ByteBuffer keepalive = ByteBuffer.wrap("keepalive".getBytes());
        _pingTask = _scheduler.scheduleAtFixedRate(() -> {
            try {
                if (_session.isOpen()) {
                    log.debug("{} Sending ping", _remote);
                    _session.getRemote().sendPing(keepalive);
                }
            } catch (Exception e) {
                log.error("{} Failed to send ping: {}", _remote, e.getMessage());
            }
        }, period, period, TimeUnit.SECONDS);
    }

    public void stop() {
        _sessionHandlersBySession.remove(_session);
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
        _sessionHandlersBySession.put(session, this);
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
        try {
            JsonObject msg = _gsonIn.fromJson(message, JsonObject.class);
            String type = msg.get("type").getAsString();

            switch (type) {
                case "login":
                    log.info("{} onMessage {}", _remote, msg);
                    handleLogin(msg);
                    break;
                case "reauth":
                    log.info("{} onMessage {}", _remote, msg);
                    handleReauth(msg);
                    break;
                case "logout":
                    log.info("{} onMessage {}", _remote, msg);
                    handleLogout();
                    break;
                case "request_token":
                    log.info("{} onMessage {}", _remote, msg);
                    handleRequestToken();
                    break;
                case "auth_with_token":
                    log.info("{} onMessage {}", _remote, msg);
                    handleAuthWithToken(msg);
                    break;
                case "heartbeat":
                    JsonObject response = new JsonObject();
                    response.addProperty("type", "pong");

                    sendMessage(response, false);
                    break;
                default:
                    log.info("{} onMessage {}", _remote, msg);
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

    private void loginSucceeded(String username, String password) {
        _username = username;
        _password = password;
        _isAuthenticated = true;

        log.info("{} User authenticated: {}", _remote, username);

        JsonObject response = new JsonObject();
        response.addProperty("type", "login_response");
        response.addProperty("success", true);
        response.addProperty("username", username);

        sendMessage(response);
    }

    private void loginFailed(String username, String password) {
        log.info("{} Failed login attempt for: {}", _remote, username);

        JsonObject response = new JsonObject();
        response.addProperty("type", "login_response");
        response.addProperty("success", false);
        response.addProperty("message", "Invalid username or password");

        sendMessage(response);
    }

    private void handleLogin(JsonObject msg) {
        String username = msg.get("username").getAsString();
        String password = msg.get("password").getAsString();

        _userMgr.login(username, password, false);
    }

    private void handleReauth(JsonObject msg) { // This can be simplified or removed if you always use tokens
        String username = msg.get("username").getAsString();

        if (username.equals(_username)) {
            _isAuthenticated = true;
            log.info("{} User re-authenticated: {}", _remote, username);
        } else {
            sendError("Not authenticated", "reauth");
        }
    }

    private void handleLogout() {
        log.info("{} User logged out: {}", _remote, _username);

        _userMgr.logout(_username, _password, false);

        _username = null;
        _password = null;
        _isAuthenticated = false;

        if (_subscriberHandler != null) {
            _subscriberHandler.resetTabs();
        }
        if (_publisherHandler != null) {
            _publisherHandler.resetTabs();
        }
    }

    private static Map<String, TokenInfo> _tokenStore = new ConcurrentHashMap<>();

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
        log.info("{} sending {}", _remote, response);
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
        if (logOp) log.info("{} sending {}", _remote, message);
        try {
            if (_session != null && _session.isOpen()) {
                _session.getRemote().sendString(message);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    // TODO consider alternative to sending net.a_cappella.devtools.ColumnDef object
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
