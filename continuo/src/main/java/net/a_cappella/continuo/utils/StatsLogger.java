package net.a_cappella.continuo.utils;

import org.HdrHistogram.Histogram;
import org.slf4j.Logger;

public class StatsLogger {
    public static final String TAB = "\t";
    private static final String NL = "\n";
    private static final String DATAPOINT_MARKER = "DATAPOINT";

    private final Logger _log;
    private final boolean _humanReadableLog;

    private final int _chartSamples;
    private final long[] _bounds;
    private final long[] _labels;
    private final long[] _values;

    public StatsLogger(final Logger log) {
        this(log, false, 10);
    }
    public StatsLogger(final Logger log, boolean humanReadableLog, int chartSamples) {
        _log = log;
        _humanReadableLog = humanReadableLog;

        _chartSamples = chartSamples;
        _bounds = new long[chartSamples+1];
        _labels = new long[chartSamples];
        _values = new long[chartSamples];
    }

    public void dataPointHeader(String paramsHeader) {
        String header = DATAPOINT_MARKER + TAB + paramsHeader;
        header += "cnt"+TAB+"min"+TAB+"50%"+TAB+"90%"+TAB+"99%"+TAB+"max"+TAB;
        header += zoomInHeader(100)+zoomInHeader(99)+zoomInHeader(90)+zoomInHeader(50);
        _log.info(header);
    }
    private String zoomInHeader(int pct) {
        String zih = "zoom" + TAB + pct+"-";
        for (int i=0; i<_chartSamples; i++) {
            zih += "L" + i + TAB;
        }
        for (int i=0; i<_chartSamples; i++) {
            zih += "V" + i + TAB;
        }
        return zih;
    }

    public void logResults(final Histogram h, final String params) {
        long cnt = h.getTotalCount();
        long min = (cnt==0) ? 0 : h.getMinValue();
        long at50 = (cnt==0) ? 0 : h.getValueAtPercentile(50);
        long at90 = (cnt==0) ? 0 : h.getValueAtPercentile(90);
        long at99 = (cnt==0) ? 0 : h.getValueAtPercentile(99);
        long max = (cnt==0) ? 0 : h.getMaxValue();

        if (_humanReadableLog) {
            _log.info(String.format("tot=%d min=%d 50%%=%d 90%%=%d 99%%=%d max=%d", cnt, min, at50, at90, at99, max));
        }

        String dataPoint = cnt + TAB + min + TAB + at50 + TAB + at90 + TAB + at99 + TAB + max + TAB;
        dataPoint += zoomIn(h, min, max, 100);
        dataPoint += zoomIn(h, min, at99, 99);
        dataPoint += zoomIn(h, min, at90, 90);
        dataPoint += zoomIn(h, min, at50, 50);

        _log.info(DATAPOINT_MARKER + TAB + params + dataPoint);
    }
    private String zoomIn(Histogram h, long min, long max, int pct) {
        for (int i=0; i<=_chartSamples; i++) {
            _bounds[i] = (min + i * (max - min) / _chartSamples);
        }
        for (int i=0; i<_chartSamples; i++) {
            try {
                _values[i] = h.getCountBetweenValues(_bounds[i], _bounds[i+1]);
            } catch (ArrayIndexOutOfBoundsException x) {
                _log.error("Could not get countBetweenValues("+_bounds[i]+","+_bounds[i+1]+"); defaulting to -1...");
                _values[i] = -1;
            }
            _labels[i] = (_bounds[i] + _bounds[i+1]) / 2;
        }
        String header = ((pct==100)?"Full Histo":("Zoom In At"+pct+"%"));

        if (_humanReadableLog) {
            String logEntry = "----------------- " + header + NL;
            for (int i=0; i<_chartSamples; i++) {
                logEntry += _labels[i] + TAB + _values[i] + NL;
            }
            _log.info(logEntry);
        }

        String dataPoint = pct + "%" + TAB;
        for (int i=0; i<_chartSamples; i++) {
            dataPoint += _labels[i] + TAB;
        }
        for (int i=0; i<_chartSamples; i++) {
            dataPoint += _values[i] + TAB;
        }
        return dataPoint;
    }
}
