package net.a_cappella.presto.ps;

import org.agrona.DirectBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Tracker {
    private static final Logger log = LoggerFactory.getLogger(Tracker.class);

    private final TrackerCell[] _list;

    private final int _n;
    private int _oldest;
    private int _newest;

    public Tracker(int n, int bufferSize) {
        _n = n;
        _oldest = 0;
        _newest = n - 1;

        _list = new TrackerCell[n];
        for (int i=0; i<n; i++) {
            _list[i] = new TrackerCell(bufferSize);
        }
        log.debug("{}", this);
    }

    public int getOldest() {
        return _oldest;
    }

    public int getNewest() {
        return _newest;
    }

    public void onMsg(DirectBuffer buffer, int offset, int length, long serialId, AeronSerializer.RequestFragmentHandler handler) {
        if (log.isDebugEnabled()) log.info("{} {}", (handler==null) ? "--- " : "+++ ", serialId);
        int pos = find(serialId);
        if (pos >= 0) { // found the record, i.e., this is the second message for this serialId
            _list[pos].reset();
            if (pos == _oldest) {
                advanceOldest();
            }
        } else { // first occurrence of this serialId
            if (isFull()) { // list is full, will override oldest
                TrackerCell oldestCell = _list[_oldest];
                if (oldestCell.isRecent()) {
                    log.info("Overwriting recent cell @{} : {}", _oldest, oldestCell._serialId);
                }
                oldestCell.reset();
                advanceOldest();
            }
            _newest = (_newest + 1) % _n;
            TrackerCell newestCell = _list[_newest];
            newestCell.update(buffer, offset, length, serialId, handler);
        }
        log.debug("{}", this);
    }
    private void advanceOldest() {
        do {
            _oldest = (_oldest + 1) % _n;
        } while (_list[_oldest]._serialId == 0L && (_oldest != (_newest + 1) % _n));
    }

    public void onActivate() {
        log.info("activating...");
        while (!isEmpty() && _list[_oldest]._serialId != 0L) {
            TrackerCell cell = _list[_oldest];
            AeronSerializer.RequestFragmentHandler handler = cell._handler;
            if (handler != null) { // should always be not null
                log.info("serializing @{} : {}", _oldest, cell._serialId);
                handler.serialize(cell._buffer, 0, cell._msgLength);
            }
            cell.reset();
            _oldest = (_oldest + 1) % _n;
        }
        log.info("done activating...");
        log.debug("{}", this);
    }

    private int find(long serialId) {
        if (isEmpty()) return -1;
        int i = _oldest;
        do {
            if (_list[i]._serialId == serialId) return i;
            if (i == _newest) return -1;
            i = (i + 1) % _n;
        } while (true);
    }

    private boolean isEmpty() {
        return _oldest == (_newest + 1) % _n && _list[_oldest].isEmpty();
    }

    private boolean isFull() {
        return _oldest == (_newest + 1) % _n && !_list[_oldest].isEmpty();
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("[ ");
        for (int i=0; i<_n; i++) {
            sb.append(_list[i]._serialId).append(" ");
        }
        sb.append("] o=").append(_oldest).append(" n=").append(_newest).append(" ").append((isEmpty() ? "empty" : isFull() ? "full" : ""));
        return sb.toString();
    }
}
