package net.a_cappella.continuo.datatypes;

import net.a_cappella.continuo.utils.Utils;

import java.text.ParseException;
import java.util.Date;

public class PTime {
    private final int _hhmmssSSS;

    public PTime(int hhmmssSSS) {
        _hhmmssSSS = hhmmssSSS;
    }

    public PTime(String hhmmssSSS) throws ParseException {
        _hhmmssSSS = fromMillis(Utils.parse("HH:mm:ss.SSS", hhmmssSSS).getTime());
    }

    public int getTime() {
        return _hhmmssSSS;
    }

    public String toString() {
        int hh = _hhmmssSSS / 10_000_000;
        int mmssSSS = _hhmmssSSS % 10_000_000;
        int mm = mmssSSS / 100_000;
        int ssSSS = mmssSSS % 100_000;
        int ss = ssSSS / 1_000;
        int SSS = ssSSS % 1_000;
        return String.format("%02d:%02d:%02d.%03d", hh, mm, ss, SSS);
    }

    public static PTime parsePTime(String str) {
        if ("now".equals(str)) return new PTime(PTime.fromMillis(System.currentTimeMillis()));
        try {
            return new PTime(str);
        } catch (ParseException x) {
            return new PTime(Integer.parseInt(str));
        }
    }



    private static final long MILLIS_PER_DAY = 1000*60*60*24;

    public static int fromMillis(long timeMillis) {
        long dayMillis = timeMillis % MILLIS_PER_DAY;
        long millis = dayMillis % 1000;
        long hms = dayMillis / 1000;
        long seconds = hms % 60;
        long hm = hms / 60;
        long minutes = hm % 60;
        long h = hm / 60;
        long hours = h % 24;
        return (int) (millis+1000*(seconds+100*(minutes+100*hours)));
    }






    private static boolean isCalculatedCorrectly() {
        boolean isCorrect = true;
        long startingTime = System.currentTimeMillis();
        long endingTime = startingTime + MILLIS_PER_DAY;
        for (long i=startingTime; i<endingTime; i++) {
            isCorrect |= isCalculatedCorrectly(i);
        }
        return isCorrect;
    }

    private static boolean isCalculatedCorrectly(long tsMillis) {
        long valueViaDate = Long.parseLong(Utils.format("HHmmssSSS", new Date(tsMillis)));
        long value = fromMillis(tsMillis);
        boolean isCorrect = valueViaDate==value;
        if (!isCorrect || tsMillis%1000000==0) {
            System.out.println(valueViaDate+" "+value);
        }
        return isCorrect;
    }

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
        System.out.println("It took "+(endMillis-startMillis)+" ms");
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
