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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class TestViewport {
    private static final Logger log = LoggerFactory.getLogger(TestViewport.class);

    private static AtomicBoolean _verifyConsecutiveValues = new AtomicBoolean(true);
    public static void setVerifyConsecutiveValues(boolean verifyConsecutiveValues) {
        log.info("{} === verifyingConsecutiveValues: {}", verifyConsecutiveValues);
        _verifyConsecutiveValues.set(verifyConsecutiveValues);
    }

    private final String _remote;
    private final String _idColumnName;
    private final boolean _ascending;
    private final boolean _pinByKey;
    private int _idColumnIndex;
    private final List<Number> _rows = new ArrayList<>();
    private int _bSR;
    private int _bER;
    private int _vSR;
    private int _vER;

    public TestViewport(String remote, String idColumnName, boolean ascending, boolean pinByKey) {
        _remote = remote;
        _idColumnName = idColumnName;
        _ascending = ascending;
        _pinByKey = pinByKey;
    }

    public void updateIdColumnIndex(TableData table, int startCol, int endCol) {
        List<ColumnDef> columns = table.getOrderedColumns();
        _idColumnIndex = -1;
        if (columns.size() == 0) return;
        for (int i = 0; i < columns.size(); i++) {
            ColumnDef columnDef = columns.get(i);
            if (columnDef.name.equals(_idColumnName)) {
                if ("integer".equals(columnDef.type)) {
                    if (startCol <= i && i < endCol) {
                        _idColumnIndex = i - startCol;
                    }
                } else {
                    log.error("{} updateIdColumnIndex: the idColumn {} needs to be of 'integer' type, it's of type {}", _remote, _idColumnName, columnDef.type);
                    handleException();
                }
                return;
            }
        }
        log.error("{} updateIdColumnIndex: please double check the idColumnName {} as it does not appear in the defined columns {}", _remote, _idColumnName, columns);
        handleException();
    }

    public void handleRowUpdate(List<Object> row, int relativePosition) {
        if (_idColumnIndex >= 0) { // id column is visible
            if (relativePosition < 0 || relativePosition >= _rows.size()) {
                log.error("{} handleRowUpdate: invalid position {} as there are only {} rows in the viewport", _remote, relativePosition, _rows.size());
                handleException();
            } else {
                _rows.set(relativePosition, (Number) row.get(_idColumnIndex));
            }
        }
    }

    public void handleDeltaUpdate(List<List<Object>> rows, int position, int bSR, int bER, int vSR, int vER) {
        _bSR = bSR;
        _bER = bER;
        _vSR = vSR;
        _vER = vER;
        if (verifyRange() && verifyPosition(position) && _idColumnIndex >= 0) {
            position -= _bSR;
            List<Number> delta = new ArrayList<>();
            for (int i = 0; i < rows.size(); i++) {
                List<Object> row = rows.get(i);
                Number id = (Number) row.get(_idColumnIndex);
                delta.add(id);
            }
            _rows.addAll(position, delta);
            if (verifyBufferBounds()) {
                verifyConsecutiveValues();
            }
        }
    }

    public void handleDeltaUpdate(List<List<Object>> rows, int position, int bSR, int bER, int vSR, int vER, int deleteCount, String deleteFrom) {
        _bSR = bSR;
        _bER = bER;
        _vSR = vSR;
        _vER = vER;
        if (verifyRange() && verifyPosition(position) && verifyDeleteFrom(deleteFrom) && _idColumnIndex >= 0) {
            position -= _bSR;
            List<Number> delta = new ArrayList<>();
            for (int i = 0; i < rows.size(); i++) {
                List<Object> row = rows.get(i);
                Number id = (Number) row.get(_idColumnIndex);
                delta.add(id);
            }
            _rows.addAll(position, delta);
            if ("top".equals(deleteFrom)) {
                _rows.subList(0, deleteCount).clear();
            } else {
                int size = _rows.size();
                _rows.subList(size - deleteCount, size).clear();
            }
            if (verifyBufferBounds()) {
                verifyConsecutiveValues();
            }
        }
    }

    public void handleFullUpdate(List<List<Object>> rows, int startRow) {
        _bSR = _vSR = startRow;
        _bER = _vER = startRow + _rows.size() - 1;
        _rows.clear();
        if (_idColumnIndex >= 0) {
            for (int i = 0; i < rows.size(); i++) {
                List<Object> row = rows.get(i);
                Number id = (Number) row.get(_idColumnIndex);
                _rows.add(id);
            }
            verifyConsecutiveValues();
        }
    }

    public void handleScrollMetricsVertical(int bSR, int bER, int vSR, int vER) {
        _bSR = bSR;
        _bER = bER;
        _vSR = vSR;
        _vER = vER;
        if (verifyRange() && _idColumnIndex >= 0) {
            verifyBufferBounds();
            log.debug("{} ****************** handleScrollMetricsVertical rows[{}]={} {}", _remote, _vSR, _rows.get(_vSR-_bSR), _rows);
        }
    }

    private boolean verifyPosition(int position) {
        // should be able to insert after the last record
        if (position < _bSR || position > _bER + 1) {
            log.error("{} invalid position {} - not in buffer [{}, {}]", _remote, position, _bSR, _bER + 1);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyRange() {
        if (_vSR < _bSR || _vER > _bER) {
            log.error("{} invalid range - visible [{}, {}] not in buffer [{}, {}]", _remote, _vSR, _vER, _bSR, _bER);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyBufferBounds() {
        if (_bER + 1 - _bSR != _rows.size()) {
            log.error("{} invalid buffer bounds - [{}, {}] not consistent with actual buffer size {}", _remote, _bSR, _bER, _rows.size());
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyDeleteFrom(String deleteFrom) {
        if (!"top".equals(deleteFrom) && !"bottom".equals(deleteFrom)) {
            log.error("{} invalid deleteFrom {}", _remote, deleteFrom);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyConsecutiveValues() {
        if (_rows.size() <= 1) {
            if (_pinByKey && _rows.size() == 1 && _rows.get(0).longValue() > 1) {
                // consecutive values are guaranteed only if the first value is in {0, 1}
                setVerifyConsecutiveValues(false);
            }
            return true;
        }
        if (!_verifyConsecutiveValues.get()) {
            return true;
        }
        log.debug("{} ****************** verifyConsecutiveValues rows[{}]={} {}", _remote, _vSR, _rows.get(_vSR-_bSR), _rows);
        long prev = _rows.get(0).longValue();
        for (int i = 1; i < _rows.size(); i++) {
            long crt = _rows.get(i).longValue();
            int cmp = Long.compare(prev, crt);
            if (cmp == 0) { // prev == crt
                log.error("{} duplicate rows at indices {} and {} : {}", _remote, i - 1, i, crt);
                handleException();
                return false;
            } else if (cmp < 0) { // prev < crt
                if (_ascending) {
                    if (prev + 1 != crt) {
                        log.error("{} non consecutive values at indices {} and {} : {} + 1 != {}", _remote, i - 1, i, prev, crt);
                        handleException();
                        return false;
                    }
                } else {
                    log.error("{} inconsistent ordering at indices {} and {} : {} < {}", _remote, i - 1, i, prev, crt);
                    handleException();
                    return false;
                }
            } else { // prev > crt
                if (_ascending) {
                    log.error("{} inconsistent ordering at indices {} and {} : {} > {}", _remote, i - 1, i, prev, crt);
                    handleException();
                    return false;
                } else {
                    if (prev != crt + 1) {
                        log.error("{} non consecutive values at indices {} and {} : {} != {} + 1", _remote, i - 1, i, prev, crt);
                        handleException();
                        return false;
                    }
                }
            }
            prev = crt;
        }
        log.debug("{} ****************** verifyConsecutiveValues last to compare => {} ascending={}", _remote, prev, _ascending);
        return true;
    }

    private void handleException() {
        log.error("{}", _remote, new Exception("stack trace"));
        new Thread(() -> {
            try {
                Thread.sleep(500);
            } catch (InterruptedException ignore) {}
            System.exit(-1);
        }).start();
    }
}
