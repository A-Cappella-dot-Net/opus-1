package net.a_cappella.presto.ps;

import io.aeron.Publication;
import net.a_cappella.continuo.utils.Utils;
import org.agrona.concurrent.UnsafeBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import sbe.generated.CombinedSbePrestoHeaderEncoder;
import sbe.generated.SbeBoolean;

public class PublicationHelper {
    private static final Logger log = LoggerFactory.getLogger(PublicationHelper.class);

    private int _retriesOnBackPressure = 0; // {<0 = forever; 0 = do not retry; >0 = retry and give up eventually}
    public void setRetriesOnBackPressure(String retriesOnBackPressure) {
        _retriesOnBackPressure = Utils.parseAsInt("retriesOnBackPressure", retriesOnBackPressure, _retriesOnBackPressure);
    }
    private int _sleepNanosOnBackPressureRetry = 1_000_000; // sleep between retries; default is 1 milli
    public void setSleepNanosOnBackPressureRetry(String sleepNanosOnBackPressureRetry) {
        _sleepNanosOnBackPressureRetry = Utils.parseAsInt("sleepNanosOnBackPressureRetry", sleepNanosOnBackPressureRetry, _sleepNanosOnBackPressureRetry);
    }

    private final CombinedSbePrestoHeaderEncoder ENCODER = new CombinedSbePrestoHeaderEncoder();

    public int offer(boolean loopback, Publication publication, UnsafeBuffer buffer, int offset, int len) {
        long result;
        boolean published = false;
        boolean repeat;
        int retries = _retriesOnBackPressure;

        do {
            result = publication.offer(buffer, offset, len);
            if (result >= 0) {
                published = true;
                repeat = false;
            } else {
                if (result == Publication.ADMIN_ACTION) {
                    repeat = true;
                } else if (result == Publication.BACK_PRESSURED) {
//			      	log.error("before"+presto.ps.Utils.hexDump(buffer, offset, len));
                    ENCODER.wrap(buffer, 0);
                    ENCODER.backPressured(SbeBoolean.TRUE);
//			      	log.error("after"+presto.ps.Utils.hexDump(buffer, offset, len));
                    if (retries == 0) {
                        repeat = false;
                    } else {
                        if (retries > 0) retries--;
                        repeat = true;
                        if (_sleepNanosOnBackPressureRetry>0) Utils.sleepNanosDelay(_sleepNanosOnBackPressureRetry);
                    }
                } else {
                    repeat = false;
                }
            }
        } while (repeat);

        logResult(loopback, result, published, publication);

        int res = (result>=0) ? 0 : (int) -result;
        if (!published) res |= 1<<8;
        if (loopback) res = res << 16;
        return res;
    }

    public static boolean isPublished(int result) {
        return (result & (1<<8 | 1<<24)) == 0;
    }

    private static final String LOOPBACK = "Loopback: ";
    private static final String BACK_PRESSURED = "Offer failed due to back pressure "+Publication.BACK_PRESSURED;
    private static final String BACK_PRESSURED_RETRIED = "Back pressured offer was successful after retry "+Publication.BACK_PRESSURED;
    private static final String NOT_CONNECTED = "Offer failed because publisher was not connected to subscriber "+Publication.NOT_CONNECTED;
    private static final String CLOSED = "Offer failed publication was closed "+Publication.CLOSED;
    private static final String MAX_POSITION_EXCEEDED = "Offer failed due to publication reaching max position "+Publication.MAX_POSITION_EXCEEDED;
    private static final String UNKNOWN = "Offer failed due to unknown reason ";

    private void logResult(boolean loopback, long result, boolean published, Publication publication) {
        if (result < 0) {
            String streamId = " streamId=" + publication.streamId();
            if (loopback) {
                if (result == Publication.BACK_PRESSURED) {
                    if (published) log.info(LOOPBACK+BACK_PRESSURED_RETRIED+streamId);
                    else log.info(LOOPBACK+BACK_PRESSURED+streamId);
                } else if (result == Publication.NOT_CONNECTED) {
                    log.info(LOOPBACK+NOT_CONNECTED+streamId);
                } else if (result == Publication.CLOSED) {
                    log.info(LOOPBACK+CLOSED+streamId);
                } else if (result == Publication.MAX_POSITION_EXCEEDED) {
                    log.info(LOOPBACK+MAX_POSITION_EXCEEDED+streamId);
                } else {
                    log.info(LOOPBACK+UNKNOWN+result+streamId);
                }
            } else {
                if (result == Publication.BACK_PRESSURED) {
                    if (published) log.info(BACK_PRESSURED_RETRIED+streamId);
                    else log.info(BACK_PRESSURED+streamId);
                } else if (result == Publication.NOT_CONNECTED) {
                    log.info(NOT_CONNECTED+streamId);
                } else if (result == Publication.CLOSED) {
                    log.info(CLOSED+streamId);
                } else if (result == Publication.MAX_POSITION_EXCEEDED) {
                    log.info(MAX_POSITION_EXCEEDED+streamId);
                } else {
                    log.info(UNKNOWN+result+streamId);
                }
            }
        }
    }
}
