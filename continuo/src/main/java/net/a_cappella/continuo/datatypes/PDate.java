package net.a_cappella.continuo.datatypes;

import java.text.ParseException;
import java.util.Date;
import java.util.TimeZone;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

import gnu.trove.map.TIntIntMap;
import gnu.trove.map.hash.TIntIntHashMap;
import net.a_cappella.continuo.utils.Utils;

public class PDate {
    public int _yyyymmdd;

    public PDate(int yyyymmdd) {
        _yyyymmdd = yyyymmdd;
    }

    public PDate(String yyyymmdd) throws ParseException {
        _yyyymmdd = fromMillis(Utils.parse("yyyy-MM-dd", yyyymmdd).getTime());
    }

    public int getDate() {
        return _yyyymmdd;
    }

    public static PDate parsePDate(String str) {
        if ("now".equals(str)) return new PDate(PDate.fromMillis(System.currentTimeMillis()));
        try {
            return new PDate(str);
        } catch (ParseException x) {
            return new PDate(Integer.parseInt(str));
        }
    }

    public String toString() {
        int yyyy = _yyyymmdd / 10_000;
        int mmdd = _yyyymmdd % 10_000;
        int mm = mmdd / 100;
        int dd = mmdd % 100;
        return String.format("%04d-%02d-%02d", yyyy, mm, dd);
    }





    public static int fromMillis(long timeMillis) {
        int yyyyMMdd = 0;
        int daysSinceEpoch = (int) ((timeMillis + _tzOffsetMillis) / MILLIS_PER_DAY);

        if (_threadSafety==ThreadSafetyStrategy.NONE) {
            yyyyMMdd = _datesMap.get(daysSinceEpoch);
            if (yyyyMMdd == _datesMap.getNoEntryValue()) {
                yyyyMMdd = Integer.parseInt(Utils.format("yyyyMMdd", new Date(timeMillis)));
                _datesMap.put(daysSinceEpoch, yyyyMMdd);
            }
        } else if (_threadSafety==ThreadSafetyStrategy.THREAD_LOCAL) {
            TIntIntHashMap datesMap = _datesMapThreadLocal.get();
            yyyyMMdd = datesMap.get(daysSinceEpoch);
            if (yyyyMMdd == datesMap.getNoEntryValue()) {
                yyyyMMdd = Integer.parseInt(Utils.format("yyyyMMdd", new Date(timeMillis)));
                datesMap.put(daysSinceEpoch, yyyyMMdd);
            }
        } else if (_threadSafety==ThreadSafetyStrategy.SYNCHRONIZED) {
            synchronized (_datesMap) {
                yyyyMMdd = _datesMap.get(daysSinceEpoch);
                if (yyyyMMdd == _datesMap.getNoEntryValue()) {
                    yyyyMMdd = Integer.parseInt(Utils.format("yyyyMMdd", new Date(timeMillis)));
                    _datesMap.put(daysSinceEpoch, yyyyMMdd);
                }
            }
        } else if (_threadSafety==ThreadSafetyStrategy.LOCK) {
            _lock.lock();
            try {
                yyyyMMdd = _datesMap.get(daysSinceEpoch);
                if (yyyyMMdd == _datesMap.getNoEntryValue()) {
                    yyyyMMdd = Integer.parseInt(Utils.format("yyyyMMdd", new Date(timeMillis)));
                    _datesMap.put(daysSinceEpoch, yyyyMMdd);
                }
            } finally {
                _lock.unlock();
            }
        }

        return yyyyMMdd;
    }

    public enum ThreadSafetyStrategy {
        NONE, THREAD_LOCAL, SYNCHRONIZED, LOCK
    }
    private static final ThreadSafetyStrategy _threadSafety = ThreadSafetyStrategy.NONE;
    private static final long MILLIS_PER_DAY = 1000*60*60*24;

    private static final int _tzOffsetMillis = TimeZone.getDefault().getOffset(System.currentTimeMillis());
    private static final TIntIntMap _datesMap = new TIntIntHashMap();
    private static final Lock _lock = new ReentrantLock();
    private static final ThreadLocal<TIntIntHashMap> _datesMapThreadLocal = new ThreadLocal<>() {
        public TIntIntHashMap initialValue() {
            return new TIntIntHashMap();
        }
    };

    private static void oneDayPerformance() {
        long startMillis = System.currentTimeMillis();
        System.out.println(startMillis+" "+fromMillis(startMillis));

        long startingTime = System.currentTimeMillis();
        long endingTime = startingTime + MILLIS_PER_DAY;
        for (long i=startingTime; i<endingTime; i++) {
            fromMillis(i);
        }

        long endMillis = System.currentTimeMillis();
        System.out.println(endMillis+" "+fromMillis(endMillis));
        System.out.println(_threadSafety+" took "+(endMillis-startMillis)+" ms");

        if (_threadSafety==ThreadSafetyStrategy.NONE || _threadSafety==ThreadSafetyStrategy.SYNCHRONIZED || _threadSafety==ThreadSafetyStrategy.LOCK) {
            System.out.println(_datesMap);
        } else {
            System.out.println(_datesMapThreadLocal.get());
        }
    }

    public static void main(String[] args) throws InterruptedException {
        oneDayPerformance();

        while (true) {
            long millis = System.currentTimeMillis();
            System.out.println("inMillis="+fromMillis(millis));
            Thread.sleep(1000);
        }
    }
}
