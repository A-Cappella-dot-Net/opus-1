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

    private static final String NO_ACTION = "Not snapped / subscribed yet...";
    private static final int ROW_HEIGHT = 33;

    private final SessionHandler _sessionHandler;
    private final String _tabId;
    private final String _remote;
    private final TableData _table;

    private int _viewportHeight;
    private int _viewportPositionFromTop = 0; // Pixel-based vertical scroll

    private int _viewportWidth;
    private int _startCol = 0; // TODO not used
    private int _viewportPositionFromLeft = 0; // Pixel-based horizontal scroll

    private String _snsSql;
    private boolean _pinByKey;
    private String _opType;
    private long _subId = -1;

    private boolean _hasAllColumns = false;
    private List<ColumnDef> _columns = new ArrayList<>();



    public SubscriberTab(SessionHandler sessionHandler, String tabId, String remote, int viewportWidth, int viewportHeight) {
        _sessionHandler = sessionHandler;
        _tabId = tabId;
        _remote = remote;
        _table = new TableData(tabId, remote);
        _viewportWidth = viewportWidth;
        _viewportHeight = viewportHeight;
        sendStatus(NO_ACTION);
    }

    public void onWebSocketClose() {

    }

    public void closeTab() {
        if (_subId >= 0) {
            _sessionHandler._client.unsubscribe(_subId);
            _subId = -1;
        }
    }


    public void handleViewportUpdate(int viewportWidth, int viewportHeight) {
        _viewportWidth = viewportWidth;
        _viewportHeight = viewportHeight;

        sendViewportData();
    }

    public void handleScrollUpdate(JsonObject msg) {
        _viewportPositionFromTop = msg.has("viewportPositionFromTop") ? msg.get("viewportPositionFromTop").getAsInt() : _viewportPositionFromTop;
        _startCol = msg.has("startCol") ? msg.get("startCol").getAsInt() : _startCol;
        _viewportPositionFromLeft = msg.has("scrollLeftPixels") ? msg.get("scrollLeftPixels").getAsInt() : _viewportPositionFromLeft;

        sendViewportData();
    }

    public void handleResizeColumn(int colIndex, int newWidth) {
        log.info("=== resizing column {}", _table.getOrderedColumn(colIndex));
        int oldWidth = _table.getOrderedColumn(colIndex).width;

        _table.handleResizeColumn(colIndex, newWidth);

        if (oldWidth > newWidth) { // shrinking column
            if (_viewportWidth + _viewportPositionFromLeft > _table.getTotalWidth()) { // leaves space at the end
                _viewportPositionFromLeft -= oldWidth - newWidth;
                log.info("=== shrinking column would leave space to the right; adjusting viewportPositionFromLeft to {} ", _viewportPositionFromLeft);
            }
        }

        sendViewportData();
    }

    public void handleReorderColumns(ArrayList<Integer> columnOrder) {
        _table.handleReorderColumns(columnOrder);
        sendViewportData();
    }



    public void handleStartAction(String snsSql, boolean pinByKey, String opType) {
        _snsSql = snsSql;
        _pinByKey = pinByKey;
        _opType = opType;

        _table._paused = false;

        log.info("{} Executing SnS action: sql='{}' pinByKey={} opType={}", _remote, snsSql, pinByKey, opType);

        try {
            SqlParserResult sqlComps = SqlParser.parseSql(snsSql);
            List<String> selectFields = sqlComps.getSelectFields(); // TODO if selectFields is empty then get from meta info
            String subject = sqlComps.getFromTable();
            sendTabLabel(subject);

            setColumns(subject, selectFields);
            // TODO handle pinByKey
//            List<String> keyFields = SqlParser.parseListOfKeys(keys);
//            model.setKeyFields(keyFields);
            if ("snapSubscribe".equals(opType)) {
                _subId = _sessionHandler._client.snapSubscribe(sqlComps, this);
                sendStatus("Snap & Subscribe executing...");
            } else if ("snap".equals(opType)) {
                _sessionHandler._client.snap(sqlComps, this);
                sendStatus("Snap executing...");
            } else if ("subscribe".equals(opType)) {
                _subId = _sessionHandler._client.subscribe(sqlComps, this);
                sendStatus("Subscribe executing...");
            } else {
                sendStatus("Unknown Command " + opType);
                sendUpdateState("new");
                return;
            }
            sendUpdateState("running");

            sendMetaData();
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

            setColumns(_columns);
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
        log.info("{} onSubscriptionMessage {} {}", _tabId, obj, subId);
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
                for (String fieldName : obj.getAdHocFields()) {
                    Object fieldValue = obj.get(fieldName);
                    row.put(fieldName, fieldValue);
                    // TODO this adds one column at a time; can this be batched?
                    addColumn(ColumnDef.newAdHocCol(fieldName, fieldValue));
                }
            }
        } else {
            for (int i = 0; i < _columns.size(); i++) {
                ColumnDef columnDef = _columns.get(i);
                String fieldName = columnDef.name;
                Object fieldValue = obj.get(fieldName);
                row.put(fieldName, fieldValue);
                if ("tbd".equals(columnDef.type)) {
                    ColumnDef adHocCol = ColumnDef.newAdHocCol(fieldName, fieldValue);
                    // TODO make sure GUI accepts columnDef updates
                    addColumn(adHocCol);
                    columnDef.type = adHocCol.type; // update column type
                }
            }
        }

        addRow(row, (_pinByKey) ? obj.getObjKey() : null);
    }

    private void setColumns(List<ColumnDef> columns) {
        _table.setColumns(columns);
        sendColumnUpdate();
    }

    private void addColumn(ColumnDef column) {
        if (_table.addColumn(column)) {
            sendColumnUpdate();
        }
    }

    private void addRow(Map<String, Object> rowData, ObjKey objKey) {
        if (!_table._paused) {
            int columnsBefore = _table.getTotalCols();
            _table.addRow(rowData, objKey);
            // If columns were added, send the update
            if (_table.getTotalCols() > columnsBefore) {
                sendColumnUpdate();
            }
            sendUpdate();
        }
    }

    private void updateCell(int row, String columnName, Object value) {
        if (!_table._paused) {
            _table.updateCell(row, columnName, value);
            int colIndex = _table.getColumnIndex(columnName);
            if (colIndex >= 0) {
                sendCellUpdate(row, colIndex, value);
            }
        }
    }















    private void sendMetaData() {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "meta_data");
        response.put("tabId", _tabId);
        response.put("columns", _table.getColumns());
        response.put("totalRows", _table.getTotalRows());
        response.put("totalCols", _table.getTotalCols());
        _sessionHandler.send(response);

        sendViewportData();
    }

    private void sendUpdate() {
        sendViewportData();
    }

    private void sendCellUpdate(int row, int col, Object value) {
        Map<String, Object> update = new HashMap<>();
        update.put("type", "cell_update");
        update.put("tabId", _tabId);
        update.put("row", row);
        update.put("col", col);
        update.put("value", value);
        _sessionHandler.send(update);
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

    private void sendViewportData() {
        int totalRows = _table.getTotalRows();
        int totalCols = _table.getTotalCols();

        // Calculate scroll thumb metrics
        int totalHeight = totalRows * ROW_HEIGHT;
        double verticalThumbRatio = totalHeight > 0 ? (double) _viewportHeight / totalHeight : 1.0;
        int scrollableHeight = Math.max(0, totalHeight - _viewportHeight);
        double verticalThumbPosition = scrollableHeight > 0 ? (double) _viewportPositionFromTop / scrollableHeight : 0.0;

        verticalThumbRatio = Math.max(0.05, Math.min(1.0, verticalThumbRatio));
        verticalThumbPosition = Math.max(0.0, Math.min(1.0, verticalThumbPosition));

        // Calculate visible rows based on pixel offset
        int maxTopOffset = (_viewportHeight % ROW_HEIGHT == 0) ? 0 : ROW_HEIGHT - _viewportHeight % ROW_HEIGHT;
        int topOffset = (int) Math.rint(verticalThumbPosition * maxTopOffset); // How many pixels of first row are hidden
        int visibleRowCount = Math.min((int) Math.ceil((double) _viewportHeight /ROW_HEIGHT), totalRows); // Round up to show partial rows
        int startRow = _viewportPositionFromTop / ROW_HEIGHT;

        if (startRow + visibleRowCount > totalRows) {
//            visibleRowCount = totalRows - startRow;
            startRow = totalRows - visibleRowCount;
        }

//        log.info("{} Vertical scroll: viewportHeight={}, _viewportPositionFromTop={}, startRow={}, maxTopOffset={}, topOffset={}, visibleRowCount={}, verticalThumbPosition={}, verticalThumbRatio={}",
//                remote, viewportHeight, _viewportPositionFromTop, startRow, maxTopOffset, topOffset, visibleRowCount, verticalThumbPosition, verticalThumbRatio);

        // Calculate visible columns based on pixel offset
        int startCol;
        int endCol;
        int leftOffset; // How many pixels of the first column are hidden

        int totalWidth = _table.getTotalWidth();

        if (totalWidth <= _viewportWidth) {
            startCol = 0;
            endCol = totalCols;
            leftOffset = 0;
        } else {
            log.debug("=== A. viewportWidth={} viewportPositionFromLeft={} totalCols={} columnOrder={}", _viewportWidth, _viewportPositionFromLeft, totalCols, _table.getColumnOrder());

            // calculate startCol
            startCol = 0;
            int cumWidth = _table.colWidth(startCol);
            while (cumWidth < _viewportPositionFromLeft) {
                startCol++;
                cumWidth += _table.colWidth(startCol);
            }
            log.debug("=== B. startCol={}", startCol);

            // calculate endCol
            endCol = startCol + 1;
            cumWidth -= _viewportPositionFromLeft;
            while (endCol < totalCols && cumWidth <= _viewportWidth) {
                cumWidth += _table.colWidth(endCol);
                endCol++;
            }
            log.debug("=== C. endCol={} visibleColumnsWidth={}", endCol, cumWidth);

            // adjust startCol if there is space at the end
            while (cumWidth < _viewportWidth) {
                startCol--;
                cumWidth += _table.colWidth(startCol);
            }

            // calculate leftOffset
            cumWidth = 0;
            for (int i = 0; i < startCol; i++) {
                cumWidth += _table.colWidth(i);
            }
            leftOffset = _viewportPositionFromLeft - cumWidth;
            log.debug("=== D. startCol={} additionalVisibleColumnsWidth={} leftOffset={}", startCol, cumWidth, leftOffset);
        }

        // Extract visible data with column ordering
        List<List<Object>> visibleData = new ArrayList<>();
        for (int i = startRow; i < startRow + visibleRowCount; i++) {
            List<Object> row = new ArrayList<>();
            Map<String, Object> rowData = _table.getRow(i);
            for (int j = startCol; j < endCol; j++) {
                String colName = _table.getOrderedColumn(j).name;
                row.add(rowData.getOrDefault(colName, ""));
            }
            visibleData.add(row);
        }

        // For horizontal, calculate based on actual widths to handle partial columns
        double horizontalThumbRatio = 1.0;
        double horizontalThumbPosition = 0.0;

        if (_viewportWidth > 0 && totalCols > 0) {
            // Calculate total width of all columns

            if (totalWidth > _viewportWidth) {
                horizontalThumbRatio = Math.max(0.05, Math.min(1.0, (double) _viewportWidth / totalWidth));
                int scrollableWidth = totalWidth - _viewportWidth;
                horizontalThumbPosition = Math.max(0.0, Math.min(1.0, (double) _viewportPositionFromLeft / scrollableWidth));
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("type", "viewport_data");
        response.put("tabId", _tabId);
        response.put("data", visibleData);
        response.put("startRow", startRow);
        response.put("startCol", startCol);
        response.put("topOffset", topOffset);
        response.put("leftOffset", leftOffset);
        response.put("totalRows", totalRows);
        response.put("totalCols", totalCols);
        response.put("verticalThumbRatio", verticalThumbRatio);
        response.put("verticalThumbPosition", verticalThumbPosition);
        response.put("horizontalThumbRatio", horizontalThumbRatio);
        response.put("horizontalThumbPosition", horizontalThumbPosition);

        _sessionHandler.send(response);
    }

}
