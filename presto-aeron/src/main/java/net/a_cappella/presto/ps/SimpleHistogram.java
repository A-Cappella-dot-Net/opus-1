package net.a_cappella.presto.ps;

import java.util.Arrays;

/**
 * This histogram is intended to record the distribution of the number of messages processed in a poll operation.
 * For example,  max=10 [195798034, 950122, 1856, 309, 121, 96, 69, 62, 34, 30, 152, 0]
 * signifies that there at most 10 messages processes in a poll operation, there were 195798034 poll operations that
 * resulted in no messages being processed, there were 950122 poll operations that resulted in one message being
 * processed, there were 152 poll operations that resulted in 10 or more messages being processed, and there were no
 * poll operations that resulted in an error condition.
 */
public class SimpleHistogram {
    private final int _size; // the number of buckets in the histogram is size + 2
    private final int[] _h; // the histogram buckets
    private int _max = Integer.MIN_VALUE; // the maximum recorded value

    public SimpleHistogram(int size) {
        _size = size;
        _h = new int[size+2];
    }

    public void reset() {
        for (int i=0; i<_size+2; i++) {
            _h[i] = 0;
        }
    }

    public void recordValue(int i) {
        _max = Math.max(i, _max);
        if (i<0) {
            _h[_size+1]++;
        } else if (i>_size) {
            _h[_size]++;
        } else {
            _h[i]++;
        }
    }

    public boolean isEmpty() {
        return _max <= 0;
    }

    public String toString() {
        if (_size <= 20) {
            return "max="+_max+" "+Arrays.toString(_h);
        } else {
            StringBuilder sb = new StringBuilder("max=").append(_max).append(" snippets@msgPerSnippet: [ ");
            for (int i = 1, j = 0; i <= _size; i++) {
                int hi = _h[i];
                if (hi > 0) {
                    sb.append(hi).append("@").append(i).append(" ");
                    j++;
                }
                if (j > 30) {
                    sb.append("...");
                    break;
                }
            }
            sb.append("]");
            return sb.toString();
        }
    }
}
