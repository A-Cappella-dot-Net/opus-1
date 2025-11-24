package net.a_cappella.devtools;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TableData {
    private static final Logger log = LoggerFactory.getLogger(TableData.class);

    private final String _tabId;
    private final String _remote;
    private List<ColumnDef> _columns;
    private List<ColumnDef> _orderedColumns;
    private List<Integer> _columnOrder;

    private final List<Map<String, Object>> _rows = new ArrayList<>(); // Sparse row data
    private final List<ObjKey> _index = new ArrayList<>();
    public boolean _paused;

    public TableData(String tabId, String remote) {
        _tabId = tabId;
        _remote = remote;
//        _columns = new ArrayList<>();
        _paused = false;
    }

    public void setColumns(List<ColumnDef> columns) {
        _columns = new ArrayList<>(columns);
        _orderedColumns = new ArrayList<>(columns);
    }

    public boolean addColumn(ColumnDef column) {
        // Check if column already exists
        for (ColumnDef col : _columns) {
            if (col.name.equals(column.name)) {
                return false; // Column already exists
            }
        }
        _columns.add(column);
        _orderedColumns.add(column);
        log.info("{} Added column {} to table {}", _remote, column.name, _tabId);
        return true;
    }

    private boolean columnExists(String columnName) {
        for (ColumnDef col : _columns) {
            if (col.name.equals(columnName)) {
                return true;
            }
        }
        return false;
    }

    public void addRow(Map<String, Object> rowData, ObjKey objKey) {
        // Automatically add any new columns found in the row
        for (String colName : rowData.keySet()) {
            if (!columnExists(colName)) {
                addColumn(ColumnDef.newAdHocCol(colName, rowData.get(colName)));
            }
        }

        if (objKey != null) {
            int newRowPos = _index.indexOf(objKey);
            if (newRowPos < 0) {
                objKey.getObj().startUsing();
                _index.add(0, objKey);
                _rows.add(0, rowData);
            } else {
                objKey.getObj().startUsing();
                _index.get(newRowPos).getObj().stopUsing();
                _index.set(newRowPos, objKey);
                _rows.set(newRowPos, rowData);
            }
        } else {
            _rows.add(0, rowData);
        }
    }

    public void updateCell(int row, String columnName, Object value) {
        if (row >= 0 && row < _rows.size()) {
            _rows.get(row).put(columnName, value);
        }
    }

    public int getColumnIndex(String columnName) {
        for (int i = 0; i < getTotalCols(); i++) {
            if (_columns.get(i).name.equals(columnName)) {
                return i;
            }
        }
        return -1;
    }

    public void handleReorderColumns(ArrayList<Integer> columnOrder) {
        _columnOrder = columnOrder;
        applyColumnOrdering();
    }

    public void applyColumnOrdering() {
        _orderedColumns = _columns;
        if (_columnOrder != null && _columnOrder.size() == getTotalCols()) {
            _orderedColumns = new ArrayList<>();
            for (int idx : _columnOrder) {
                if (idx >= 0 && idx < getTotalCols()) {
                    _orderedColumns.add(_columns.get(idx));
                }
            }
        }
    }

    public void handleResizeColumn(int colIndex, int newWidth) {
        _orderedColumns.get(colIndex).resize(newWidth);
    }

    public int colWidth(int i) {
        return _orderedColumns.get(i).width;
    }

    public void clear() {
        _rows.clear();
        _index.forEach((objKey) -> objKey.getObj().stopUsing());
        _index.clear();
        if (_columns != null) _columns.clear();
        if (_orderedColumns != null) _orderedColumns.clear();
        _paused = false;
    }

    public List<ColumnDef> getColumns() {
        return _columns;
    }

    public ColumnDef getColumn(int colIndex) {
        return _columns.get(colIndex);
    }

    public ColumnDef getOrderedColumn(int colIndex) {
        return _orderedColumns.get(colIndex);
    }

    public List<Integer> getColumnOrder() {
        return _columnOrder;
    }

    public int getTotalCols() {
        return _columns.size();
    }

    public int getTotalWidth() {
        int totalWidth = 0;
        for (int i = 0; i < getTotalCols(); i++) {
            totalWidth += colWidth(i);
            log.debug("{} === {} {}", _remote, i, getColumn(i));
        }
        return totalWidth;
    }

    public Map<String, Object> getRow(int rowIndex) {
        return _rows.get(rowIndex);
    }

    public int getTotalRows() {
        return _rows.size();
    }
}
