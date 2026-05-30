/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.continuo.utils;

import net.a_cappella.continuo.utils.interner.StringInterner;
import org.agrona.concurrent.BackoffIdleStrategy;
import org.agrona.concurrent.BusySpinIdleStrategy;
import org.agrona.concurrent.IdleStrategy;
import org.agrona.concurrent.NoOpIdleStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Field;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.UnknownHostException;
import java.nio.channels.SelectionKey;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.Enumeration;
import java.util.Map;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

public class Utils {
    private static final Logger log = LoggerFactory.getLogger(Utils.class);

    public static final int TEST_INT = 128;

    private static final double EPSILON = 0.000000001;
    private static final double NEGATIVE_EPSILON = -EPSILON;

    public static void main(String[] adr) {
        System.out.println(nextId());
        for (int i=0; i<10; i++) {
            System.out.println(randomInt(10));
        }
    }

    public static double alignDown(double value, double tickValue) {
        return Math.floor(value / tickValue) * tickValue;
    }
    public static double alignUp(double value, double tickValue) {
        return Math.ceil(value / tickValue) * tickValue;
    }

    public static int randomUpTo(int max) {
        if (max == 0) return 0;
        return (int) Math.round(max * Math.random());
    }
    public static int randomInt(int max) {
        if (max == 0) return 0;
        return (int) Math.rint(max * Math.random());
    }

    public static String nextId() {
        long tMillis = System.currentTimeMillis() % MILLIS_PER_DAY;
        byte[] ipByteArr;
        long ipLong = 0;
        try {
            ipByteArr = InetAddress.getLocalHost().getAddress();
            ipLong += ipByteArr[3];
            ipLong += 1000*ipByteArr[2];
            ipLong += 1000000*ipByteArr[1];
            ipLong += 1000000000L*ipByteArr[0];
        } catch (UnknownHostException e) {
            log.error("", e);
        }
        long result = ipLong*100000000 + tMillis;
        return encode(result);
    }
    private static final long MILLIS_PER_DAY = 1000*60*60*24;
    private static final char[] idCodes = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    };
    private static String encode(long number) {
        if (number<0) number = -number;
        StringBuilder sb = new StringBuilder(15);
        while (number>0) {
            int mod = (int) (number%idCodes.length);
            number /= idCodes.length;
            sb.append(idCodes[mod]);
        }
        return sb.reverse().toString();
    }

    public static String _localhost;
    static {
        try {
            _localhost = getLocalHostLANAddress().getHostAddress();
            log.info("localhost="+_localhost);
        } catch (UnknownHostException e) {
            log.error("", e);
        }
    }

    public static String frc(double price) {
        if (Double.isNaN(price)) return "NaN";
        int priceInt = (int) price;
        double price32ndsD = (price-priceInt)*32;
        int price32nds = (int) price32ndsD;
        int price256th = (int) Math.round((price32ndsD - price32nds)*8);
        return String.format("%d-%02d%s", priceInt, price32nds, ((price256th==4)?"+":(price256th==0)?"":price256th+""));
    }

    public static int cmp(double a, double b) {
        double dif = a-b;
        if (dif>EPSILON) return 1;
        if (dif<NEGATIVE_EPSILON) return -1;
        return 0;
    }

    public static boolean doubleEquals(double a, double b) {
        if (Double.isNaN(a) && Double.isNaN(b)) return true;
        if (Double.isNaN(a) || Double.isNaN(b)) return false;
        return cmp(a, b)==0;
    }

    public static int doubleCmp(double a, double b) {
        if (Double.isNaN(a) && Double.isNaN(b)) return 0;
        if (Double.isNaN(a)) return -1;
        if (Double.isNaN(b)) return 1;
        return cmp(a, b);
    }

    public static boolean parseAsBoolean(String name, String valStr, boolean defaultVal) {
        if (valStr.startsWith("${")) {
            log.warn("Invalid {} value {}. Defaulting to {}", name, valStr, defaultVal);
            return defaultVal;
        }
        return Boolean.parseBoolean(valStr);
    }
    public static int parseAsInt(String name, String valStr, int defaultVal) {
        int val = defaultVal;
        try {
            val = Integer.parseInt(valStr);
        } catch (NumberFormatException x) {
            log.warn("Invalid {} value {}. Defaulting to {}", name, valStr, defaultVal);
        }
        return val;
    }
    public static int getAsInt(Map<String, String> map, String key, int defaultVal) {
        int val = defaultVal;
        if (map != null && map.containsKey(key)) {
            val = parseAsInt(key, map.get(key), defaultVal);
        }
        return val;
    }

    public static long parseAsLong(String name, String valStr, long defaultVal) {
        long val = defaultVal;
        try {
            val = Long.parseLong(valStr);
        } catch (NumberFormatException x) {
            log.warn("Invalid {} value {}. Defaulting to {}", name, valStr, defaultVal);
        }
        return val;
    }
    public static long getAsLong(Map<String, String> map, String key, long defaultVal) {
        long val = defaultVal;
        if (map != null && map.containsKey(key)) {
            val = parseAsLong(key, map.get(key), defaultVal);
        }
        return val;
    }

    public static String parseAsString(String name, String value, String defaultVal) {
        if (!value.startsWith("${")) return value;
        log.warn("Invalid {} value {}. Defaulting to {}", name, value, defaultVal);
        return defaultVal;
    }


    private static final StringInterner _interner = new StringInterner(8 * 1024); // TODO ability to size the interner properly
    public static String intern(StringBuilder sb) {
        return _interner.intern(sb);
    }

    private static final ThreadLocal<StringBuilder> _sbThreadLocal = new ThreadLocal<>() {
        public StringBuilder initialValue() {
            return new StringBuilder();
        }
    };
    public static StringBuilder getThreadLocalStringBuilder() {
        StringBuilder sb = _sbThreadLocal.get();
        sb.setLength(0);
        return sb;
    }

    private static final ThreadLocal<SimpleDateFormat> _sdfThreadLocal = new ThreadLocal<>() {
        public SimpleDateFormat initialValue() {
            return new SimpleDateFormat();
        }
    };

    static {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
    }

    public static String format(String pattern, Date date) {
        SimpleDateFormat sdf = _sdfThreadLocal.get();
        sdf.applyPattern(pattern);
        return sdf.format(date);
    }
    public static Date parse(String pattern, String string) throws ParseException {
        SimpleDateFormat sdf = _sdfThreadLocal.get();
        sdf.applyPattern(pattern);
        return sdf.parse(string);
    }

    private static final DateTimeFormatter _fixTsFormatter = DateTimeFormatter.ofPattern("yyyyMMdd-HH:mm:ss.SSS").withZone(ZoneId.from(ZoneOffset.UTC));
    public static String formatMillis(long epochMilli) {
        return _fixTsFormatter.format(Instant.ofEpochMilli(epochMilli));
    }
    public static long parseMillis(String string) {
        return _fixTsFormatter.parse(string, Instant::from).toEpochMilli();
    }

    public static int getIntConstant(String staticConstant) throws Exception {
        try {
            return Integer.parseInt(staticConstant);
        } catch (Exception x) {
            int pos = staticConstant.lastIndexOf(".");
            String className = staticConstant.substring(0, pos);
            String fieldName = staticConstant.substring(pos+1);
            Class<?> clazz = Class.forName(className);
            Field field = clazz.getField(fieldName);
            return field.getInt(clazz);
        }
    }

    public static void busyMicrosDelay(int delayInMicros) {
        if (delayInMicros > 0) {
            long end = System.nanoTime() + delayInMicros * 1000;
            while (System.nanoTime() < end) ;
        }
    }
    public static void sleepMillisDelay(int delayInMillis) {
        if (delayInMillis > 0) {
            try {
                Thread.sleep(delayInMillis);
            } catch (InterruptedException e) {
                log.info("", e);
            }
        }
    }
    public static void sleepNanosDelay(int delayInNanos) {
        if (delayInNanos > 0) {
            if (delayInNanos > 1_000_000) sleepMillisDelay(delayInNanos / 1_000_000);
            else busyMicrosDelay(delayInNanos / 1_000);
        }
    }
    public static void sleep(long millis) {
        long end = System.currentTimeMillis() + millis;
        try {
            Thread.sleep(millis);
        } catch (InterruptedException x) {
            log.info("", x);
            long left = end - System.currentTimeMillis();
            if (left > 0) {
                sleep(left);
            }
        }
        // presto.utils.conflator.ConflatorTest.conflationTest fails spuriously at lines 241 and 248
        // this is trying to prove that the issue is with the sleep not returning fast enough
        // so far have not been able to reproduce the issue
        long actual = System.currentTimeMillis() - end;
        if (actual>millis) { // at least twice as intended
            String info = "===> slept too long... "+millis+" vs "+(actual+millis);
            System.out.println(info);
            log.info(info);
        }
    }




    public static String keyHash(SelectionKey key) {
        return Integer.toHexString(key.hashCode());
    }

    /**
     * https://issues.apache.org/jira/browse/JCS-40
     *
     * Returns an <code>InetAddress</code> object encapsulating what is most likely the machine's LAN IP address.
     * <p/>
     * This method is intended for use as a replacement of JDK method <code>InetAddress.getLocalHost</code>, because
     * that method is ambiguous on Linux systems. Linux systems enumerate the loopback network interface the same
     * way as regular LAN network interfaces, but the JDK <code>InetAddress.getLocalHost</code> method does not
     * specify the algorithm used to select the address returned under such circumstances, and will often return the
     * loopback address, which is not valid for network communication. Details
     * <a href="http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4665037">here</a>.
     * <p/>
     * This method will scan all IP addresses on all network interfaces on the host machine to determine the IP address
     * most likely to be the machine's LAN address. If the machine has multiple IP addresses, this method will prefer
     * a site-local IP address (e.g. 192.168.x.x or 10.10.x.x, usually IPv4) if the machine has one (and will return the
     * first site-local address if the machine has more than one), but if the machine does not hold a site-local
     * address, this method will return simply the first non-loopback address found (IPv4 or IPv6).
     * <p/>
     * If this method cannot find a non-loopback address using this selection algorithm, it will fall back to
     * calling and returning the result of JDK method <code>InetAddress.getLocalHost</code>.
     * <p/>
     *
     * @throws UnknownHostException If the LAN address of the machine cannot be found.
     */
    private static InetAddress getLocalHostLANAddress() throws UnknownHostException {
        try {
            InetAddress candidateAddress = null;
            // Iterate all NICs (network interface cards)...
            for (Enumeration<NetworkInterface> ifaces = NetworkInterface.getNetworkInterfaces(); ifaces.hasMoreElements();) {
                NetworkInterface iface = ifaces.nextElement();
                // Iterate all IP addresses assigned to each card...
                for (Enumeration<InetAddress> inetAddrs = iface.getInetAddresses(); inetAddrs.hasMoreElements();) {
                    InetAddress inetAddr = inetAddrs.nextElement();
                    if (!inetAddr.isLoopbackAddress()) {

                        if (inetAddr.isSiteLocalAddress()) {
                            // Found non-loopback site-local address. Return it immediately...
                            return inetAddr;
                        }
                        else if (candidateAddress == null) {
                            // Found non-loopback address, but not necessarily site-local.
                            // Store it as a candidate to be returned if site-local address is not subsequently found...
                            candidateAddress = inetAddr;
                            // Note that we don't repeatedly assign non-loopback non-site-local addresses as candidates,
                            // only the first. For subsequent iterations, candidate will be non-null.
                        }
                    }
                }
            }
            if (candidateAddress != null) {
                // We did not find a site-local address, but we found some other non-loopback address.
                // Server might have a non-site-local address assigned to its NIC (or it might be running
                // IPv6 which deprecates the "site-local" concept).
                // Return this non-loopback candidate address...
                return candidateAddress;
            }
            // At this point, we did not find a non-loopback address.
            // Fall back to returning whatever InetAddress.getLocalHost() returns...
            InetAddress jdkSuppliedAddress = InetAddress.getLocalHost();
            if (jdkSuppliedAddress == null) {
                throw new UnknownHostException("The JDK InetAddress.getLocalHost() method unexpectedly returned null.");
            }
            return jdkSuppliedAddress;
        } catch (Exception e) {
            UnknownHostException unknownHostException = new UnknownHostException("Failed to determine LAN address: " + e);
            unknownHostException.initCause(e);
            throw unknownHostException;
        }
    }




    public static final IdleStrategy NO_OP_IDLE_STRATEGY = new NoOpIdleStrategy();
    public static final BusySpinIdleStrategy BUSY_SPIN_IDLE_STRATEGY = new BusySpinIdleStrategy();

    public static IdleStrategy getIdleStrategy(Object idleStrategyObj) {
        IdleStrategy idleStrategy = null;
        if (idleStrategyObj instanceof IdleStrategy) {
            idleStrategy = (IdleStrategy) idleStrategyObj;
        } else if (idleStrategyObj instanceof String) {
            String idleStrategyStr = ((String) idleStrategyObj).toLowerCase();
            switch (idleStrategyStr) {
                case "backoff":
                    idleStrategy = new BackoffIdleStrategy(100, 10, TimeUnit.MICROSECONDS.toNanos(1), TimeUnit.MICROSECONDS.toNanos(100));
                    break;
                case "nop":
                    idleStrategy = NO_OP_IDLE_STRATEGY;
                    break;
                case "busyspin":
                    idleStrategy = BUSY_SPIN_IDLE_STRATEGY;
                    break;
            }
        }
        return idleStrategy;
    }

    public static IdleStrategy getIdleStrategy(Object idleStrategyObj, String defaultIdleStrategy) {
        IdleStrategy idleStrategy = getIdleStrategy(idleStrategyObj);
        if (idleStrategy == null) {
            log.error("Unknown idleStrategy " + idleStrategyObj + ". Defaulting to '" + defaultIdleStrategy + "'");
            idleStrategy = getIdleStrategy(defaultIdleStrategy);
        }
        return idleStrategy;
    }
}
