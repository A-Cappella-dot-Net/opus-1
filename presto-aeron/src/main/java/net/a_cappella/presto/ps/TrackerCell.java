package net.a_cappella.presto.ps;

import org.agrona.BitUtil;
import org.agrona.BufferUtil;
import org.agrona.DirectBuffer;
import org.agrona.concurrent.UnsafeBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TrackerCell {
    private static final Logger log = LoggerFactory.getLogger(TrackerCell.class);

    public static final int RECENT_MILLIS = 1_000;

    public long _serialId;
    public long _ts;
    public int _msgLength;
    public UnsafeBuffer _buffer;

    public AeronSerializer.RequestFragmentHandler _handler;

    public TrackerCell(int bufferSize) {
        _buffer = new UnsafeBuffer(BufferUtil.allocateDirectAligned(bufferSize, BitUtil.CACHE_LINE_LENGTH));
    }

    public boolean isEmpty() {
        return _serialId == 0;
    }

    public void reset() {
        _serialId = 0;
        _ts = 0;
        _msgLength = 0;
        _handler = null;
    }

    public boolean isRecent() {
        return _ts + RECENT_MILLIS > System.currentTimeMillis();
    }

    public void update(DirectBuffer buffer, int offset, int length, long serialId, AeronSerializer.RequestFragmentHandler handler) {
        _ts = System.currentTimeMillis();
        _serialId = serialId;
        if (_buffer.capacity() < length) {
            log.warn("Reserved buffer too small {} for message of length {}; replacing with a bigger one...", _buffer.capacity(), length);
            _buffer = new UnsafeBuffer(BufferUtil.allocateDirectAligned(length * 2, BitUtil.CACHE_LINE_LENGTH));
        }
        _msgLength = length;
        if (handler != null) {
            _buffer.putBytes(0, buffer, offset, length);
            _handler = handler;
        }
    }

    @Override
    public String toString() {
        return "{" + _serialId + "/" + _msgLength + "/" + _buffer.capacity() + "}";
    }
}
