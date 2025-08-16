package net.a_cappella.presto.ps;

import java.util.Arrays;

public class SimpleHistogram {
    private final int _size;
    private final int[] _h;
    private int _max = Integer.MIN_VALUE;

    public SimpleHistogram(int size) {
        _size = size;
        _h = new int[size+1];
    }

    public void reset() {
        for (int i=0; i<_size+1; i++) {
            _h[i] = 0;
        }
    }

    public void recordValue(int i) {
        _max = Math.max(i, _max);
        if (i<0) {
            _h[0]++;
        } else if (i>_size) {
            _h[_size]++;
        } else {
            _h[i]++;
        }
    }

    public String toString() {
        return "max="+_max+" "+Arrays.toString(_h);
    }
}
