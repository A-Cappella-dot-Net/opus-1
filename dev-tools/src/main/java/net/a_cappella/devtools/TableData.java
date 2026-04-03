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

package net.a_cappella.devtools;

import net.a_cappella.continuo.obj.ObjKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
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
                if ("tbd".equals(col.type)) {
                    col.type = column.type;
                    col.width = column.width;
                    col.align = column.align;
                    col.decimals = column.decimals;
                    col.format = column.format;
                    log.info("{} Updated 'tbd' column {} to table {}", _remote, column.name, _tabId);
                    return true;
                } else {
                    return false; // Column already exists
                }
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

    public void addNewColumns(Map<String, Object> rowData) {
        // Automatically add any new columns found in the row
        for (String colName : rowData.keySet()) {
            if (!columnExists(colName)) {
                addColumn(ColumnDef.newAdHocCol(colName, rowData.get(colName)));
            }
        }
    }


    /**
     *
     * @param rowData
     * @param objKey
     * @param appendToBottom
     * @return pos - position of new record in the table
     *   when pinning by key (objKey != null) :
     *     pos < 0 then the record at position (1 - pos) is replaced
     *     pos > 0 then the new record is inserted at position (pos - 1)
     */
    public int addRow(Map<String, Object> rowData, ObjKey objKey, boolean appendToBottom) {
        if (objKey == null) {
            return addRow(rowData, appendToBottom);
        } else {
            return addPinnedByKey(rowData, objKey, appendToBottom);
        }
    }

    private int addRow(Map<String, Object> rowData, boolean appendToBottom) {
        if (appendToBottom) {
            _rows.add(rowData);
            return _rows.size();
        } else {
            _rows.add(0, rowData);
            return 1;
        }
    }

    private int addPinnedByKey(Map<String, Object> rowData, ObjKey objKey, boolean sortDescending) {
        if (_index.size() == 0) { // empty table
            objKey.getObj().startUsing();
            _index.add(0, objKey);
            _rows.add(0, rowData);
            return 1;
        } else {
            for (int i = 0; i < _index.size(); i++) {
                ObjKey key = _index.get(i);
                switch (objKey.compareTo(key)) {
                    case -1:
                        if (sortDescending) {
                            // did not find it, insert it here
                            objKey.getObj().startUsing();
                            _index.add(i, objKey);
                            _rows.add(i, rowData);
                            return i + 1;
                        } else {
                            // did not find it yet, keep going
                            break;
                        }
                    case 0:
                        // found it, replace the object
                        objKey.getObj().startUsing();
                        _index.get(i).getObj().stopUsing();
                        _index.set(i, objKey);
                        _rows.set(i, rowData);
                        return -(i + 1);
                    case 1:
                        if (sortDescending) {
                            // did not find it yet, keep going
                            break;
                        } else {
                            // did not find it, insert it here
                            objKey.getObj().startUsing();
                            _index.add(i, objKey);
                            _rows.add(i, rowData);
                            return i + 1;
                        }
                }
            }
            // add last
            int i = _index.size();
            objKey.getObj().startUsing();
            _index.add(i, objKey);
            _rows.add(i, rowData);
            return i + 1;
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

    public List<ColumnDef> getOrderedColumns() {
        return _orderedColumns;
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
        return (_columns == null) ? 0 : _columns.size();
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
