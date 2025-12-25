package net.a_cappella.devtools;

import com.google.gson.JsonObject;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.ps.ISnSListener;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static net.a_cappella.devtools.ColumnDef.*;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_BOOLEAN;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_DATETIME_DATE;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_DATETIME_ISO;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_DATETIME_TIME;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_DECIMAL;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_INT;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_LONG;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_SHORT;
import static net.a_cappella.devtools.ColumnDef.DEFAULT_WIDTH_STRING;

public class SubscriberTab implements ISnSListener {
    private static final Logger log = LoggerFactory.getLogger(SubscriberTab.class);

    private static final double BUFFER_CAPACITY_MULTIPLIER = 3.0;
    private static final String NO_ACTION = "Not snapped / subscribed yet...";
    private double _rowHeight = 33;

    private final SessionHandler _sessionHandler;
    private final String _tabId;
    private final String _remote;
    private final TableData _table;

    private double _viewportHeight;
    private double _viewportPositionFromTop = 0; // Pixel-based vertical scroll
    private int _topOffset;

    private int _bufferCapacity;
    private int _viewportCapacity;

    private int _bufferStartRow = 0;
    private int _bufferEndRow = -1;
    private int _visibleStartRow = 0;
    private int _visibleEndRow = -1;

    private int _viewportWidth;
    private int _viewportPositionFromLeft = 0; // Pixel-based horizontal scroll

    private int _startCol;
    private int _endCol;
    private int _leftOffset; // How many pixels of the first column are hidden

    private boolean _tailMode;
    private boolean _appendToBottom;

    private String _snsSql;
    private boolean _pinByKey;
    private String _opType;
    private long _subId = -1;

    private boolean _hasAllColumns = false;
    private List<ColumnDef> _columns = new ArrayList<>();

    private enum ScrollDirection {NONE, HORIZONTAL, VERTICAL};

    private static class ScrollMetrics {
        private double _thumbRatio;
        private double _thumbPosition;
    }

    private ScrollMetrics _verticalScrollMetrics = new ScrollMetrics();
    private ScrollMetrics _horizontalScrollMetrics = new ScrollMetrics();

    private TestViewport _testViewport = null;

    public SubscriberTab(SessionHandler sessionHandler, String tabId, String remote, int viewportWidth, double viewportHeight) {
        _sessionHandler = sessionHandler;
        _tabId = tabId;
        _remote = remote;
        _table = new TableData(tabId, remote);
        _viewportWidth = viewportWidth;
        updateCapacities(viewportHeight);
        sendStatus(NO_ACTION);
    }

    private void updateCapacities(double viewportHeight) {
        _viewportHeight = viewportHeight;
        _viewportCapacity = (int) Math.ceil(viewportHeight / _rowHeight);
        _bufferCapacity = (int) (_viewportCapacity * BUFFER_CAPACITY_MULTIPLIER);
        log.debug("=== viewportHeight={} viewportCapacity={} bufferCapacity={}", _viewportHeight, _viewportCapacity, _bufferCapacity);
    }

    public void resetTab() {
        if (_subId >= 0) {
            _sessionHandler._client.unsubscribe(_subId);
            _subId = -1;
        }
        _table.clear();
    }


    public synchronized void handleViewportUpdate(int viewportWidth, double viewportHeight) {
        _viewportWidth = viewportWidth;
        updateCapacities(viewportHeight);

        sendViewportData(false, ScrollDirection.NONE, 0, true);
    }

    public void handleActualRowHeight(double actualRowHeight) {
        _rowHeight = actualRowHeight;
        updateCapacities(_viewportHeight);
    }

    public synchronized void handleVerticalScrollUpdate(double viewportPositionFromTop) {
        _viewportPositionFromTop = viewportPositionFromTop;

        sendViewportData(true, ScrollDirection.VERTICAL, 0, false);
    }

    public synchronized void handleHorizontalScrollUpdate(int scrollLeftPixels) {
        _viewportPositionFromLeft = scrollLeftPixels;

        sendViewportData(true, ScrollDirection.HORIZONTAL, 0, true);
    }

    public synchronized void handleResizeColumn(int colIndex, int newWidth) {
        log.info("=== resizing column {}", _table.getOrderedColumn(colIndex));
        int oldWidth = _table.getOrderedColumn(colIndex).width;

        _table.handleResizeColumn(colIndex, newWidth);

        if (oldWidth > newWidth) { // shrinking column
            if (_viewportWidth + _viewportPositionFromLeft > _table.getTotalWidth()) { // leaves space at the end
                _viewportPositionFromLeft -= oldWidth - newWidth;
                log.info("{} shrinking column would leave space to the right; adjusting viewportPositionFromLeft to {} ", _remote, _viewportPositionFromLeft);
            }
        }

        sendViewportData(false, ScrollDirection.NONE, 0, true);
    }

    public synchronized void handleReorderColumns(ArrayList<Integer> columnOrder) {
        _table.handleReorderColumns(columnOrder);

        if (_testViewport != null) {
            _testViewport.updateIdColumnIndex(_table, _startCol, _endCol);
        }

        sendViewportData(false, ScrollDirection.NONE, 0, true);
    }



    public void handleStartAction(String snsSql, boolean pinByKey, String opType, boolean appendToBottom) {
        _snsSql = snsSql;
        _pinByKey = pinByKey;
        _opType = opType;
        _appendToBottom = appendToBottom;

        _table._paused = false;

        log.info("{} Executing SnS action: sql='{}' pinByKey={} opType={} appendToBottom={}", _remote, snsSql, pinByKey, opType, appendToBottom);

        try {
            SqlParserResult sqlComps = SqlParser.parseSql(snsSql);
            List<String> selectFields = sqlComps.getSelectFields(); // TODO if selectFields is empty then get from meta info
            String subject = sqlComps.getFromTable();
            sendTabLabel(subject);

            setColumns(subject, selectFields);

            List<String> key = null;
            if (pinByKey) {
                ObjMetaInfo omi = ObjectManager.getInstance().getSubjectMetaInfo(subject);
                if (omi == null) throw new Exception("Unknows subject " + subject);
                key = omi.getKeys().stream().map(FieldMetaInfo::getName).collect(Collectors.toList());
            }

            if ("snapSubscribe".equals(opType)) {
                _subId = _sessionHandler._client.snapSubscribe(sqlComps, this);
                sendStatus("Snap & Subscribe executing..." + ((key == null) ? "" : " key=" + key));
            } else if ("snap".equals(opType)) {
                _sessionHandler._client.snap(sqlComps, this);
                sendStatus("Snap executing..." + ((key == null) ? "" : " key=" + key));
            } else if ("subscribe".equals(opType)) {
                _subId = _sessionHandler._client.subscribe(sqlComps, this);
                sendStatus("Subscribe executing..." + ((key == null) ? "" : " key=" + key));
            } else {
                sendStatus("Unknown Command " + opType);
                sendUpdateState("new");
                return;
            }
            sendUpdateState("running");

            if (_sessionHandler._client instanceof DummyPrestoClient && "ping".equals(subject)) {
                _testViewport = new TestViewport((pinByKey) ? "id" : "payload", appendToBottom);
            } else {
                _testViewport = null;
            }

        } catch (Exception x) {
            log.error("", x);
            sendUpdateState("new");
            sendStatus(x.getMessage());
        }
    }

    public void handleStopAction() {
        if (_subId >= 0) {
            _sessionHandler._client.unsubscribe(_subId);
            _subId = -1;
        }
        _hasAllColumns = false;
        _columns = new ArrayList<>();
        sendUpdateState("stopped");
        sendStatus("Operation stopped...");
    }

    public void handleClearAction() {
        _viewportPositionFromTop = 0;
        _viewportPositionFromLeft = 0;
        _tailMode = false;
        _table.clear();
        sendClearTable(); // Clear client state table info
        sendUpdateState("new");
        sendStatus(NO_ACTION);
    }

    public void handlePauseAction() {
        _table._paused = true;
        sendUpdateState("paused");
        sendStatus("Operation stopped...");
    }

    public void handleResumeAction() {
        _table._paused = false;
        sendUpdateState("running");
        sendStatus("Operation resumed...");
    }























    private ColumnDef getColumnDef(FieldMetaInfo fmi) {
        String name = fmi.getName();
        FieldType fieldType = fmi.getType();

        switch(fieldType) {
            case CHAR:
                return  new ColumnDef(name, "string", "center", DEFAULT_WIDTH_CHAR);
            case STRING:
                return  new ColumnDef(name, "string", DEFAULT_WIDTH_STRING);
            case ENUM:
                return  new ColumnDef(name, "string", DEFAULT_WIDTH_ENUM);
            case SHORT:
                return  new ColumnDef(name, "integer", DEFAULT_WIDTH_SHORT);
            case INT:
                return  new ColumnDef(name, "integer", DEFAULT_WIDTH_INT);
            case LONG:
                return  new ColumnDef(name, "integer", DEFAULT_WIDTH_LONG);
            case FLOAT:
            case DOUBLE:
                return  new ColumnDef(name, "decimal", DEFAULT_WIDTH_DECIMAL, 2);
            case TIMESTAMP:
                return  new ColumnDef(name, "datetime", DEFAULT_WIDTH_DATETIME_ISO, "ISO");
            case NANOS:
                return  new ColumnDef(name, "datetime", DEFAULT_WIDTH_DATETIME_ISO_NANOS, "ISO");
            case TIME:
                return  new ColumnDef(name, "datetime", DEFAULT_WIDTH_DATETIME_TIME, "time");
            case DATE:
                return  new ColumnDef(name, "datetime", DEFAULT_WIDTH_DATETIME_DATE, "date");
            case BOOLEAN:
                return  new ColumnDef(name, "boolean", DEFAULT_WIDTH_BOOLEAN);
            default:
                return  new ColumnDef(name, "tbd", DEFAULT_WIDTH_STRING);
        }
    }

    private ColumnDef remove(List<ColumnDef> allColumns, String colName) {
        for (int i = 0; i < allColumns.size(); i++) {
            if (colName.equals(allColumns.get(i).name)) {
                return allColumns.remove(i);
            }
        }
        return null;
    }

    private void setColumns(String subject, List<String> fixedColumnNames) {
        ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
        if (metaInfo == null) {
            sendStatus("Unknown subject '"+subject+"'");
        } else {
            List<ColumnDef> headerColumns = new ArrayList<>();
            for (FieldMetaInfo fmi : ObjMetaInfo._headerFieldsMap.values()) {
                headerColumns.add(getColumnDef(fmi));
            }
            List<ColumnDef> allColumns = new ArrayList<>();
            for (FieldMetaInfo fmi : metaInfo.getKeys()) {
                allColumns.add(getColumnDef(fmi));
            }
            for (FieldMetaInfo fmi : metaInfo.getNonKeys()) {
                allColumns.add(getColumnDef(fmi));
            }

            for (String colName : fixedColumnNames) {
                if ("*".equals(colName)) {
                    _hasAllColumns = true;
                } else {
                    ColumnDef columnDef = remove(allColumns, colName);
                    if (columnDef == null) {
                        // header columns need to be explicitly added to the select statement
                        columnDef = remove(headerColumns, colName);
                        if (columnDef == null) {
                            _columns.add(new ColumnDef(colName, "tbd", 250));
                        } else {
                            _columns.add(columnDef);
                        }
                    } else {
                        _columns.add(columnDef);
                    }
                }
            }
            if (_hasAllColumns) {
                // add remaining columns to the end
                _columns.addAll(allColumns);
            }

            _table.setColumns(_columns);
            sendColumnUpdate();

        }
    }

    @Override
    public void onSnapComplete(long subId) {
        if ("snap".equals(_opType) || _subId == -1) { // Snap request
            _hasAllColumns = false;
            _columns = new ArrayList<>();
            sendUpdateState("stopped");
            sendStatus("Snap completed...");
        }
    }

    @Override
    public void onSubscriptionMessage(Obj obj, long subId) {
        log.debug("{} onSubscriptionMessage {} {}", _tabId, obj, subId);
        Map<String, Object> row = new HashMap<>();

        if (_hasAllColumns) {
            int numFields = obj.getNumFields();
            for (int i=0; i<numFields; i++) {
                FieldMetaInfo fieldMetaInfo = obj.getFieldMetaInfo(i);
                Object fieldValue = obj.get(i);
                String fieldName = fieldMetaInfo.getName();
                row.put(fieldName, fieldValue);
                // all the defined columns have already been added
            }
            if (obj.hasAdHocs()) {
                boolean added = false;
                for (String fieldName : obj.getAdHocFields()) {
                    Object fieldValue = obj.get(fieldName);
                    row.put(fieldName, fieldValue);
                    // TODO this adds one column at a time; can this be batched?
                    added |= _table.addColumn(ColumnDef.newAdHocCol(fieldName, fieldValue));
                }
                if (added) {
                    sendColumnUpdate();
                }
            }
        } else {
            boolean added = false;
            for (int i = 0; i < _columns.size(); i++) {
                ColumnDef columnDef = _columns.get(i);
                String fieldName = columnDef.name;
                Object fieldValue = obj.get(fieldName);
                row.put(fieldName, fieldValue);
                if ("tbd".equals(columnDef.type)) {
                    ColumnDef adHocCol = ColumnDef.newAdHocCol(fieldName, fieldValue);
                    // TODO make sure GUI accepts columnDef updates
                    added |= _table.addColumn(adHocCol);
                    columnDef.type = adHocCol.type; // update column type
                }
            }
            if (added) {
                sendColumnUpdate();
            }
        }

        addRow(row, (_pinByKey) ? obj.getObjKey() : null);
    }

    private synchronized void addRow(Map<String, Object> rowData, ObjKey objKey) {
        if (!_table._paused) {
            int columnsBefore = _table.getTotalCols();
            _table.addNewColumns(rowData);
            if (_table.getTotalCols() > columnsBefore) { // If columns were added, send the update
                sendColumnUpdate();
            }

            int position = _table.addRow(rowData, objKey, _appendToBottom);

            sendViewportData(false, ScrollDirection.NONE, position, false);
        }
    }
















    private void sendClearTable() {
        JsonObject update = new JsonObject();
        update.addProperty("type", "clear_table");
        update.addProperty("tabId", _tabId);
        _sessionHandler.sendMessage(update);
    }

    private void sendUpdateState(String state) {
        JsonObject update = new JsonObject();
        update.addProperty("type", "update_state");
        update.addProperty("tabId", _tabId);
        update.addProperty("mode", "subscriber");
        update.addProperty("state", state);
        _sessionHandler.sendMessage(update);
    }

    private void sendColumnUpdate() {
        Map<String, Object> update = new HashMap<>();
        update.put("type", "column_update");
        update.put("tabId", _tabId);
        update.put("columns", _table.getColumns());
        _sessionHandler.send(update);

        if (_testViewport != null) {
            _testViewport.updateIdColumnIndex(_table, _startCol, _endCol);
        }
    }

    private void sendStatus(String status) {
        JsonObject update = new JsonObject();
        update.addProperty("type", "update_status");
        update.addProperty("tabId", _tabId);
        update.addProperty("status", status);
        _sessionHandler.sendMessage(update);
    }

    private void sendTabLabel(String label) {
        JsonObject update = new JsonObject();
        update.addProperty("type", "update_tab_label");
        update.addProperty("tabId", _tabId);
        update.addProperty("label", label);
        _sessionHandler.sendMessage(update);
    }

    private Map<String, Object> prepareFullUpdate(List<List<Object>> rows) {
        if (_testViewport != null) {
            _testViewport.handleFullUpdate(rows, _visibleStartRow);
        }

        Map<String, Object> msg = new HashMap<>();
        msg.put("type", "full_update");
        msg.put("tabId", _tabId);
        msg.put("data", rows);
        msg.put("startRow", _visibleStartRow);
        msg.put("startCol", _startCol);
        msg.put("topOffset", _topOffset);
        msg.put("leftOffset", _leftOffset);
        return msg;
    }

    private Map<String, Object> prepareRowUpdate(List<Object> row, int rowIndex) {
        if (_testViewport != null) {
            _testViewport.handleRowUpdate(row, rowIndex);
        }

        Map<String, Object> msg = new HashMap<>();
        msg.put("type", "row_update");
        msg.put("tabId", _tabId);
        msg.put("data", row);
        msg.put("rowIndex", rowIndex);
        return msg;
    }

    private Map<String, Object> prepareDeltaUpdate(List<List<Object>> rows, int position) {
        if (_testViewport != null) {
            _testViewport.handleDeltaUpdate(rows, position, _bufferStartRow, _bufferEndRow, _visibleStartRow, _visibleEndRow);
        }

        Map<String, Object> msg = new HashMap<>();
        msg.put("type", "delta_update");
        msg.put("tabId", _tabId);
        msg.put("data", rows);
        msg.put("position", position);
        msg.put("startRow", _bufferStartRow);
        msg.put("endRow", _bufferEndRow);
        msg.put("visibleStartRow", _visibleStartRow);
        msg.put("visibleEndRow", _visibleEndRow);
        msg.put("topOffset", _topOffset);
        return msg;
    }

    private Map<String, Object> prepareDeltaUpdate(List<List<Object>> rows, int position, int removeCount, String removeFrom) {
        if (_testViewport != null) {
            _testViewport.handleDeltaUpdate(rows, position, _bufferStartRow, _bufferEndRow, _visibleStartRow, _visibleEndRow, removeCount, removeFrom);
        }

        Map<String, Object> msg = new HashMap<>();
        msg.put("type", "delta_update");
        msg.put("tabId", _tabId);
        msg.put("data", rows);
        msg.put("position", position);
        msg.put("startRow", _bufferStartRow);
        msg.put("endRow", _bufferEndRow);
        msg.put("visibleStartRow", _visibleStartRow);
        msg.put("visibleEndRow", _visibleEndRow);
        msg.put("topOffset", _topOffset);
        msg.put("removeCount", removeCount);
        msg.put("removeFrom", removeFrom);
        return msg;
    }

    private void send(Map<String, Object> msg) {
        _sessionHandler.send(msg);
    }

    private Map<String, Object> prepareScrollMetricsVerticalMessage(int totalRows, ScrollMetrics scrollMetrics) {
        Map<String, Object> msg = new HashMap<>();
        msg.put("type", "scroll_metrics_vertical");
        msg.put("tabId", _tabId);
        msg.put("totalRows", totalRows);
        msg.put("verticalThumbRatio", scrollMetrics._thumbRatio);
        msg.put("verticalThumbPosition", scrollMetrics._thumbPosition);
        return msg;
    }

    private void adjustScrollMetricsVertical(Map<String, Object> msg) {
        msg.put("visibleStartRow", _visibleStartRow);
        msg.put("visibleEndRow", _visibleEndRow);
        msg.put("startRow", _bufferStartRow);
        msg.put("endRow", _bufferEndRow);
        msg.put("topOffset", _topOffset);

        if (_testViewport != null) {
            _testViewport.handleScrollMetricsVertical(_bufferStartRow, _bufferEndRow, _visibleStartRow, _visibleEndRow);
        }
    }

    private void sendScrollMetricsHorizontal(double horizontalThumbRatio, double horizontalThumbPosition, int startCol, int endCol) {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "scroll_metrics_horizontal");
        response.put("tabId", _tabId);

        response.put("horizontalThumbRatio", horizontalThumbRatio);
        response.put("horizontalThumbPosition", horizontalThumbPosition);

        if (_testViewport != null) {
            _testViewport.updateIdColumnIndex(_table, _startCol, _endCol);
        }

        _sessionHandler.send(response);
    }

    private List<List<Object>> extractRows(int startCol, int endCol, int startRow, int endRow) {
        List<List<Object>> rows = new ArrayList<>();
        for (int i = startRow; i <= endRow; i++) {
            List<Object> row = new ArrayList<>();
            Map<String, Object> rowData = _table.getRow(i);
            for (int j = startCol; j < endCol; j++) {
                String colName = _table.getOrderedColumn(j).name;
                row.add(rowData.getOrDefault(colName, ""));
            }
            rows.add(row);
        }
        return rows;
    }

    private void sendViewportData(boolean updateTailMode, ScrollDirection scrollDirection, int position, boolean fullUpdate) {
        boolean addingRow = position != 0;

        int totalRows = _table.getTotalRows();
        double totalHeight = totalRows * _rowHeight;
        double scrollableHeight = Math.max(0, totalHeight - _viewportHeight);

        if (updateTailMode) { // tailMode is only updated by scroll_update messages
            _tailMode = _viewportPositionFromTop == scrollableHeight;
        }

        calculateScrollMetricsVertical(_verticalScrollMetrics); // calculates metrics
        Map<String, Object> smvMsg = prepareScrollMetricsVerticalMessage(totalRows, _verticalScrollMetrics); // uses metrics
        calculateTopOffset(_verticalScrollMetrics); // uses metrics

        calculateVisibleColumns();

        if (scrollDirection == ScrollDirection.HORIZONTAL || fullUpdate) {
            sendScrollMetricsHorizontal();
        }

        int visibleRowCount = Math.min(_viewportCapacity, totalRows); // Round up to show partial rows

        Map<String, Object> msg = null;
        List<List<Object>> rows;
        int overflow;
        if (addingRow) { // position != 0
            boolean replace = position < 0;
            position = ((replace) ? - position : position) - 1;
            rows = extractRows(_startCol, _endCol, position, position);
            if (replace) {
                smvMsg = null;
                log.trace("=== REPLACE mode position={}", position);
                log.trace("====== REPLACE before bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                if (_bufferStartRow <= position && position <= _bufferEndRow) {
                    log.trace("=== REPLACE inside");
                    msg = prepareRowUpdate(rows.get(0), position - _bufferStartRow);
                } else {
                    log.trace("=== REPLACE outside");
                    // position is outside buffer, msg == null
                    if (smvMsg != null) adjustScrollMetricsVertical(smvMsg);
                }
            } else { // pinToKey addition OR non pinToKey addition
                log.trace("=== ADDING appendToBottom={} viewportPositionFromTop={} scrollableHeight={}", _appendToBottom, _viewportPositionFromTop, scrollableHeight);
                if (!_appendToBottom && _viewportPositionFromTop == 0) { // head mode
                    log.trace("=== HEAD mode position={}", position);
                    log.trace("====== HEAD before bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                    _visibleStartRow = 0;
                    _visibleEndRow = visibleRowCount - 1;
                    _bufferStartRow = 0;
                    if (position < _bufferCapacity) {
                        _bufferEndRow++;

                        overflow = _bufferEndRow - _bufferStartRow - _bufferCapacity;
                        if (overflow <= 0) {
                            log.trace("====== HEAD  after 1. bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                            msg = prepareDeltaUpdate(rows, position);
                        } else {
                            _bufferEndRow -= overflow;
                            log.trace("====== HEAD  after 2. bSR={} vSR={} vER={} bER={} overflow={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow, overflow);
                            msg = prepareDeltaUpdate(rows, position, overflow, "bottom");
                        }
                    } else {
                        // insertion outside the buffer, bER unchanged
                        adjustScrollMetricsVertical(smvMsg);
                        log.trace("====== HEAD  after 3. bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                    }

                } else if ((_appendToBottom && _viewportPositionFromTop == scrollableHeight) || _tailMode) { // tail mode
                    log.trace("=== TAIL mode position={}", position);
                    log.trace("====== TAIL before bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                    _visibleStartRow = totalRows - visibleRowCount;
                    _visibleEndRow = totalRows - 1;
                    _bufferEndRow = totalRows - 1;
                    // _bufferStartRow does not change unless bER - bSR - bufferCapacity > 0
                    if (position >= totalRows - _bufferCapacity) {
                        overflow = _bufferEndRow - _bufferStartRow - _bufferCapacity;
                        if (overflow <= 0) {
                            log.trace("====== TAIL  after 1. bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                            msg = prepareDeltaUpdate(rows, position);
                        } else {
                            _bufferStartRow += overflow;
                            log.trace("====== TAIL  after 2. bSR={} vSR={} vER={} bER={} overflow={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow, overflow);
                            msg = prepareDeltaUpdate(rows, position + overflow, overflow, "top");
                        }
                    } else {
                        // insertion outside the buffer
                        _bufferStartRow++;
                        log.trace("====== TAIL  after 3. bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                        adjustScrollMetricsVertical(smvMsg);
                    }

                } else { // pinned mode
                    log.trace("=== PINNED mode position={}", position);
                    log.trace("====== PINNED before bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                    boolean withinBuffer;
                    if (position <= _bufferStartRow) {
                        _bufferStartRow++;
                        _visibleStartRow++;
                        _visibleEndRow++;
                        _bufferEndRow++;
                        withinBuffer = false;
                    } else if (position <= _visibleStartRow) {
                        _visibleStartRow++;
                        _visibleEndRow++;
                        _bufferEndRow++;
                        withinBuffer = true;
                    } else if (position <= _visibleEndRow) {
                        _visibleEndRow++;
                        _bufferEndRow++;
                        withinBuffer = true;
                    } else if (position <= _bufferEndRow) {
                        _bufferEndRow++;
                        withinBuffer = true;
                    } else { // position > _bER
                        withinBuffer = false;
                    }
                    log.trace("====== PINNED  after bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
                    if (withinBuffer) {
                        overflow = _bufferEndRow - _bufferStartRow - _bufferCapacity;
                        if (overflow <= 0) {
                            msg = prepareDeltaUpdate(rows, position);
                        } else {
                            if ((_bufferEndRow - _visibleEndRow) > (_visibleStartRow - _bufferStartRow)) { // more hidden rows below the visible rows than above
                                _bufferEndRow -= overflow;
                                msg = prepareDeltaUpdate(rows, position, overflow, "bottom");
                            } else {
                                _bufferStartRow += overflow;
                                msg = prepareDeltaUpdate(rows, position + overflow, overflow, "top");
                            }
                        }
                    } else {
                        // outside buffer, ignore
                        adjustScrollMetricsVertical(smvMsg);
                    }
                }
            }
        } else if (scrollDirection == ScrollDirection.VERTICAL) {
            log.trace("====== SCROLL before bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
            _visibleStartRow = (int) (_viewportPositionFromTop / _rowHeight);
            _visibleEndRow = _visibleStartRow + visibleRowCount - 1;
            log.trace("====== SCROLL  after vSR={} vER={}", _visibleStartRow, _visibleEndRow);

            if (_bufferStartRow <= _visibleStartRow && _visibleEndRow <= _bufferEndRow) {
                // all new visible rows are in the buffer, do nothing
                adjustScrollMetricsVertical(smvMsg);
            } else if (_bufferEndRow < _visibleStartRow || _visibleEndRow < _bufferStartRow) {
                fullUpdate = true;
                log.trace("====== SCROLL need full update");
            } else if (_visibleEndRow > _bufferEndRow) {
                rows = extractRows(_startCol, _endCol, _bufferEndRow + 1, _visibleEndRow);

                position = _bufferEndRow + 1;
                log.trace("=== 1. inserting {} row(s) at position {}", rows.size(), position);

                _bufferEndRow = _visibleEndRow;
                overflow = _bufferEndRow - _bufferStartRow - _bufferCapacity;
                if (overflow > 0) {
                    _bufferStartRow += overflow;
                    msg = prepareDeltaUpdate(rows, position + overflow, overflow, "top");
                } else {
                    msg = prepareDeltaUpdate(rows, position);
                }
                adjustScrollMetricsVertical(smvMsg);
            } else if (_visibleStartRow < _bufferStartRow) {
                rows = extractRows(_startCol, _endCol, _visibleStartRow, _bufferStartRow - 1);

                position = _visibleStartRow;
                log.trace("=== 2. inserting {} row(s) at position {}", rows.size(), position);

                _bufferStartRow = _visibleStartRow;

                overflow = _bufferEndRow - _bufferStartRow - _bufferCapacity;
                if (overflow > 0) {
                    _bufferEndRow -= overflow;
                    msg = prepareDeltaUpdate(rows, position, overflow, "bottom");
                } else {
                    msg = prepareDeltaUpdate(rows, position);
                }
                adjustScrollMetricsVertical(smvMsg);
            }
            if (!fullUpdate) log.trace("====== SCROLL  after bSR={} vSR={} vER={} bER={}", _bufferStartRow, _visibleStartRow, _visibleEndRow, _bufferEndRow);
        }
        if (fullUpdate) {
            _visibleStartRow = (int) (_viewportPositionFromTop / _rowHeight);
            if (_visibleStartRow + visibleRowCount > totalRows) {
                // viewport size has increased and I want to show no blank lines at the end
                _visibleStartRow = totalRows - visibleRowCount;
            }
            if (_tailMode) {
                _visibleStartRow = totalRows - visibleRowCount;
            }
            _visibleEndRow = _visibleStartRow + visibleRowCount - 1;

            _bufferStartRow = _visibleStartRow;
            _bufferEndRow = _visibleEndRow;
            log.trace("=== FULL bSR=vSR={} vER=bER={}", _bufferStartRow, _bufferEndRow);
            rows = extractRows(_startCol, _endCol, _visibleStartRow, _visibleEndRow);
            msg = prepareFullUpdate(rows);
        }

        if (smvMsg != null) {
            send(smvMsg);
        }

        if (msg != null) {
            send(msg);
        }
    }

    private void calculateTopOffset(ScrollMetrics scrollMetrics) {
        // calculate topOffset
        int totalRows = _table.getTotalRows();
        double totalHeight = totalRows * _rowHeight;
        double partialRowHeight = (_viewportHeight > totalHeight) ? 0.0 : _viewportHeight % _rowHeight;
        double maxTopOffset = (partialRowHeight == 0) ? 0 : _rowHeight - partialRowHeight;
        _topOffset = (int) Math.rint(scrollMetrics._thumbPosition * maxTopOffset); // How many pixels of first row are hidden
    }

    private void calculateScrollMetricsVertical(ScrollMetrics verticalScrollMetrics) {
        int totalRows = _table.getTotalRows();
        double totalHeight = totalRows * _rowHeight;
        double scrollableHeight = Math.max(0, totalHeight - _viewportHeight);

        // calculate verticalThumbRatio
        double verticalThumbRatio = totalHeight > 0 ? _viewportHeight / totalHeight : 1.0;
        verticalThumbRatio = Math.max(0.05, Math.min(1.0, verticalThumbRatio));

        // calculate verticalThumbPosition
        double verticalThumbPosition = scrollableHeight > 0 ? _viewportPositionFromTop / scrollableHeight : 0.0;
        verticalThumbPosition = Math.max(0.0, Math.min(1.0, verticalThumbPosition));
        if (_tailMode) {
            verticalThumbPosition = 1.0;
        }

        verticalScrollMetrics._thumbPosition = verticalThumbPosition;
        verticalScrollMetrics._thumbRatio = verticalThumbRatio;
    }

    private void calculateVisibleColumns() {
        // Calculate visible columns based on pixel offset

        int totalCols = _table.getTotalCols();
        int totalWidth = _table.getTotalWidth(); // TODO compute when columns change and store rather than compute each time

        if (totalWidth <= _viewportWidth) {
            _startCol = 0;
            _endCol = totalCols;
            _leftOffset = 0;
        } else {
            log.trace("=== A. viewportWidth={} viewportPositionFromLeft={} totalCols={} columnOrder={}", _viewportWidth, _viewportPositionFromLeft, totalCols, _table.getColumnOrder());

            // calculate startCol
            _startCol = 0;
            int cumWidth1 = _table.colWidth(_startCol);
            while (cumWidth1 < _viewportPositionFromLeft) {
                _startCol++;
                cumWidth1 += _table.colWidth(_startCol);
            }
            log.trace("=== B. startCol={} cumWidth1={}", _startCol, cumWidth1);

            // calculate endCol
            _endCol = _startCol + 1;
            int cumWidth2 = cumWidth1 - _viewportPositionFromLeft;
            int cumWidth3 = _table.colWidth(_startCol);
            while (_endCol < totalCols && cumWidth2 <= _viewportWidth) {
                cumWidth2 += _table.colWidth(_endCol);
                cumWidth3 += _table.colWidth(_endCol);
                _endCol++;
            }
            log.trace("=== C. endCol={} cumWidth2={} cumWidth3={}", _endCol, cumWidth2, cumWidth3);

            if (cumWidth2 < _viewportWidth) {
                while (cumWidth3 < totalWidth) {
                    _startCol--;
                    cumWidth3 += _table.colWidth(_startCol);
                }
                _leftOffset = cumWidth3 - _viewportWidth;
                log.trace("=== D.1 startCol={} cumWidth3={} leftOffset={}", _startCol, cumWidth3, _leftOffset);
            } else {
                _leftOffset = cumWidth3 - cumWidth2;
                log.trace("=== D.2 cumWidth1={} leftOffset={}", cumWidth1, _leftOffset);
            }
        }
    }

    private void sendScrollMetricsHorizontal() {
        int totalCols = _table.getTotalCols();
        int totalWidth = _table.getTotalWidth();

        double horizontalThumbRatio = 1.0;
        double horizontalThumbPosition = 0.0;
        if (_viewportWidth > 0 && totalCols > 0) {
            // Calculate total width of all columns

            if (totalWidth > _viewportWidth) {
                horizontalThumbRatio = Math.max(0.05, Math.min(1.0, (double) _viewportWidth / totalWidth));
                int scrollableWidth = totalWidth - _viewportWidth;
                log.trace("=== calculate horizontalThumbPosition: totalWidth={} _viewportWidth={} => scrollableWidth={}", totalWidth, _viewportWidth, scrollableWidth);

                int cumWidth = 0;
                for (int i = 0; i < _startCol; i++) {
                    cumWidth += _table.colWidth(i);
                }
                log.trace("=== calculate horizontalThumbPosition: cumWidth={} _leftOffset={} => cumWidth={}", cumWidth, _leftOffset, cumWidth + _leftOffset);
                cumWidth += _leftOffset;

                horizontalThumbPosition = Math.max(0.0, Math.min(1.0, (double) cumWidth / scrollableWidth));
                log.trace("=== calculate horizontalThumbPosition => {}", horizontalThumbPosition);

            }
        }
        sendScrollMetricsHorizontal(horizontalThumbRatio, horizontalThumbPosition, _startCol, _endCol);
    }

}
