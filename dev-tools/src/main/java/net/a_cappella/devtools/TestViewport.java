package net.a_cappella.devtools;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class TestViewport {
    private static final Logger log = LoggerFactory.getLogger(TestViewport.class);

    private final String _idColumnName;
    private final boolean _ascending;
    private int _idColumnIndex;
    private final List<Number> _rows = new ArrayList<>();
    private int _bSR;
    private int _bER;
    private int _vSR;
    private int _vER;

    public TestViewport(String idColumnName, boolean ascending) {
        _idColumnName = idColumnName;
        _ascending = ascending;
    }

    public void updateIdColumnIndex(TableData table, int startCol, int endCol) {
        List<ColumnDef> columns = table.getOrderedColumns();
        _idColumnIndex = -1;
        for (int i = 0; i < columns.size(); i++) {
            ColumnDef columnDef = columns.get(i);
            if (columnDef.name.equals(_idColumnName)) {
                if ("integer".equals(columnDef.type)) {
                    if (startCol <= i && i < endCol) {
                        _idColumnIndex = i - startCol;
                    }
                } else {
                    log.error("updateIdColumnIndex: the idColumn {} needs to be of 'integer' type, it's of type {}", _idColumnName, columnDef.type);
                    handleException();
                }
                return;
            }
        }
        log.error("updateIdColumnIndex: please double check the idColumnName {} as it does not appear in the defined columns {}", _idColumnName, columns);
        handleException();
    }

    public void handleRowUpdate(List<Object> row, int relativePosition) {
        if (relativePosition < 0 || relativePosition >= _rows.size()) {
            log.error("handleRowUpdate: invalid position {} as there are only {} rows in the viewport", relativePosition, _rows.size());
            handleException();
        } else {
            if (_idColumnIndex >= 0) {
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
            if (verifyBounds()) {
                verifyRowOrder();
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
            if (verifyBounds()) {
                verifyRowOrder();
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
            verifyRowOrder();
        }
    }

    public void handleScrollMetricsVertical(int bSR, int bER, int vSR, int vER) {
        _bSR = bSR;
        _bER = bER;
        _vSR = vSR;
        _vER = vER;
        if (verifyRange() && _idColumnIndex >= 0) {
            verifyBounds();
            log.debug("****************** handleScrollMetricsVertical rows[{}]={} {}", _vSR, _rows.get(_vSR-_bSR), _rows);
        }
    }

    private boolean verifyPosition(int position) {
        // should be able to insert after the last record
        if (position < _bSR || position > _bER + 1) {
            log.error("invalid position {} - not in [{}, {}]", position, _bSR, _bER + 1);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyRange() {
        if (_vSR < _bSR || _vER > _bER) {
            log.error("invalid range - [{}, {}] not in [{}, {}]", _vSR, _vER, _bSR, _bER);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyBounds() {
        if (_bER + 1 - _bSR != _rows.size()) {
            log.error("invalid bounds - [{}, {}] not consistent with viewport height {}", _bSR, _bER, _rows.size());
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyDeleteFrom(String deleteFrom) {
        if (!"top".equals(deleteFrom) && !"bottom".equals(deleteFrom)) {
            log.error("invalid deleteFrom {}", deleteFrom);
            handleException();
            return false;
        }
        return true;
    }

    private boolean verifyRowOrder() {
        if (_rows.size() <= 1) {
            return true;
        }
        log.debug("****************** verifyRowOrder rows[{}]={} {}", _vSR, _rows.get(_vSR-_bSR), _rows);
        long prev = _rows.get(0).longValue();
        for (int i = 1; i < _rows.size(); i++) {
            long crt = _rows.get(i).longValue();
            int cmp = Long.compare(prev, crt);
            if (cmp == 0) { // prev == crt
                log.error("duplicate rows at indices {} and {} : {}", i - 1, i, crt);
                handleException();
                return false;
            } else if (cmp < 0) { // prev < crt
                if (_ascending) {
                    if (prev + 1 != crt) {
                        log.error("non consecutive values at indices {} and {} : {} + 1 != {}", i - 1, i, prev, crt);
                        handleException();
                        return false;
                    }
                } else {
                    log.error("inconsistent ordering at indices {} and {} : {} < {}", i - 1, i, prev, crt);
                    handleException();
                    return false;
                }
            } else { // prev > crt
                if (_ascending) {
                    log.error("inconsistent ordering at indices {} and {} : {} > {}", i - 1, i, prev, crt);
                    handleException();
                    return false;
                } else {
                    if (prev != crt + 1) {
                        log.error("non consecutive values at indices {} and {} : {} != {} + 1", i - 1, i, prev, crt);
                        handleException();
                        return false;
                    }
                }
            }
            prev = crt;
        }
        return true;
    }

    private void handleException() {
        log.error("", new Exception("stack trace"));
        new Thread(() -> {
            try {
                Thread.sleep(500);
            } catch (InterruptedException ignore) {}
            System.exit(-1);
        }).start();
    }
}
