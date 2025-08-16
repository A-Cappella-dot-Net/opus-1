package net.a_cappella.presto.ps;

import org.agrona.BitUtil;
import org.agrona.BufferUtil;
import org.agrona.concurrent.UnsafeBuffer;

public class SharedAeronCoders extends SharedCoders {
    private static final int BUFFER_SIZE = 4096;

    private final UnsafeBuffer _buffer = new UnsafeBuffer(BufferUtil.allocateDirectAligned(BUFFER_SIZE, BitUtil.CACHE_LINE_LENGTH));
    private int _len;

    public UnsafeBuffer getBuffer() {
        return _buffer;
    }

    public void setLen(int len) {
        _len = len;
    }
    public int getLen() {
        return _len;
    }
}
