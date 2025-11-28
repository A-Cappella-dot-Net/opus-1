package net.a_cappella.devtools;

import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class SubscriberHandler {
    private static final Logger log = LoggerFactory.getLogger(SubscriberHandler.class);

    private final SessionHandler _sessionHandler;
    private final String _remote;

    private final Map<String, SubscriberTab> _tabs = new ConcurrentHashMap<>();

    private String _currentTab; // TODO need to update on tab switch; updates should be only for the current tab

    public SubscriberHandler(SessionHandler sessionHandler) {
        _sessionHandler = sessionHandler;
        _remote = sessionHandler._remote;
    }

    public void resetTabs() {
        _tabs.forEach((tabId, subscriberTab) -> subscriberTab.resetTab());
    }

    public void handleAuthenticatedMessage(JsonObject msg) {
        String type = msg.get("type").getAsString();
        switch (type) {
            case "init_tab":
                handleInitTab(msg);
                break;
            case "close_tab":
                handleCloseTab(msg);
                break;

            case "viewport_update":
                handleViewportUpdate(msg);
                break;
            case "scroll_update":
                handleScrollUpdate(msg);
                break;
            case "resize_column":
                handleResizeColumn(msg);
                break;
            case "reorder_columns":
                handleReorderColumns(msg);
                break;

            case "start":
                handleStartAction(msg);
                break;
            case "stop":
                handleStopAction(msg);
                break;
            case "clear":
                handleClearAction(msg);
                break;
            case "pause":
                handlePauseAction(msg);
                break;
            case "resume":
                handleResumeAction(msg);
                break;

            default:
                log.error("{} Unknown message type: {}", _remote, type);
        }
    }

    private void handleInitTab(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();
        _currentTab = tabId;

        SubscriberTab tab = new SubscriberTab(_sessionHandler, tabId, _remote, msg.get("viewportWidth").getAsInt(), msg.get("viewportHeight").getAsInt());
        _tabs.put(tabId, tab);
    }

    private void handleCloseTab(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        _tabs.remove(tabId).resetTab();
    }

    private void handleStartAction(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleStartAction(msg.get("snsSql").getAsString(), msg.get("pinByKey").getAsBoolean(), msg.get("opType").getAsString());
    }

    private void handleStopAction(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleStopAction();
    }

    private void handleClearAction(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleClearAction();
    }

    private void handlePauseAction(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handlePauseAction();
    }

    private void handleResumeAction(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleResumeAction();
    }

    private void handleViewportUpdate(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        if (tab != null) {
            tab.handleViewportUpdate(msg.get("viewportWidth").getAsInt(), msg.get("viewportHeight").getAsInt());
        }
    }

    private void handleScrollUpdate(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleScrollUpdate(msg);
    }

    private void handleResizeColumn(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        tab.handleResizeColumn(msg.get("colIndex").getAsInt(), msg.get("newWidth").getAsInt());
    }

    private void handleReorderColumns(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();

        SubscriberTab tab = _tabs.get(tabId);
        if (msg.has("columnOrder")) {
            ArrayList<Integer> columnOrder = new ArrayList<>();
            for (var elem : msg.get("columnOrder").getAsJsonArray()) {
                columnOrder.add(elem.getAsInt());
            }
            tab.handleReorderColumns(columnOrder);
        }
    }
}
