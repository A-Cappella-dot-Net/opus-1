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

package net.a_cappella.continuo.msg;

import static net.a_cappella.continuo.PrestoConstants.SERIAL;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputFilter;
import java.io.ObjectInputStream;
import java.io.ObjectOutput;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.nio.ByteBuffer;

import net.a_cappella.continuo.managed.Poolable;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class Msg extends Poolable implements ITypedMsg, Serializable {
    private static final Logger log = LoggerFactory.getLogger(Msg.class);

    /**
     * System property holding <em>additional</em> {@link ObjectInputFilter} allow-patterns for the
     * Java-serialization decode path (see {@link #decode(ByteBuffer, int)}). A deployment sets this
     * from its own launch configuration to permit its own {@link Msg} subclasses, without editing
     * this class or repository:
     *
     * <pre>-DserialFilterAdditions="com.acme.msg.**;com.acme.util.Ticket"</pre>
     *
     * <p>The name is unqualified so it is independent of the package layout (a rename never changes
     * it). System-property names share one JVM-wide namespace, so keep it distinctive to avoid
     * colliding with unrelated components.
     *
     * <p>The value is a semicolon-separated list of class/package patterns in the standard JDK
     * filter grammar ({@link ObjectInputFilter.Config#createFilter(String)}). These <em>extend</em>
     * the built-in {@link #BASELINE_SERIAL_FILTER}: the effective filter allows the baseline classes
     * <em>and</em> these additions, and rejects everything else. Supply only the extra allow-patterns
     * — the leading limits and the trailing reject-all come from the baseline, so a {@code !*} here is
     * unnecessary and would prematurely reject any additions listed after it.
     */
    public static final String SERIAL_FILTER_PROPERTY = "serialFilterAdditions";

    /**
     * Built-in baseline allow-list for {@link #decode(ByteBuffer, int)}, always applied.
     *
     * <p>{@code decode} deserializes attacker-reachable wire bytes with
     * {@link ObjectInputStream#readObject()}. Without a filter, {@code readObject} instantiates
     * <em>any</em> serializable class named in the byte stream (running its {@code readObject}/
     * {@code readResolve} logic) before the {@code (Msg)} cast is reached — the classic
     * Java-deserialization remote-code-execution vector via gadget chains.
     *
     * <p>The baseline permits only the project's own package subtree — the group root of
     * {@link Msg}'s package plus all subpackages (e.g. {@code net.a_cappella.**}). The root is
     * derived at runtime via {@link #projectPackageRoot()} rather than hard-coded, so the packages
     * can be refactored without editing this filter. Those project classes are the only ones present
     * in a legitimately encoded stream: pool bookkeeping ({@code _pooled}, {@code _identityHashCode},
     * {@code _numberOfUsers}) is declared in {@link net.a_cappella.continuo.managed.Poolable}, which
     * is deliberately <em>not</em> {@link java.io.Serializable}; Java therefore skips those inherited
     * fields when serializing a {@link Msg} and re-runs {@code Poolable}'s constructor on decode.
     * Nothing from {@code java.*} is written to the wire, so no JDK value type needs to be
     * allow-listed here.
     *
     * <p>The {@code max*} limits bound graph depth / references / array length as defence-in-depth
     * against decompression-style DoS. Any patterns from {@link #SERIAL_FILTER_PROPERTY} are appended
     * after this, then a reject-all ({@code !*}) is appended last, so anything outside the baseline and
     * the configured additions is refused before its code can run.
     */
    private static final String BASELINE_SERIAL_FILTER =
            "maxdepth=32;maxrefs=10000;maxarray=100000;" + projectPackageRoot() + ".**";

    private static final ObjectInputFilter DESERIALIZATION_FILTER =
            buildFilter(System.getProperty(SERIAL_FILTER_PROPERTY));

    /**
     * Builds the decode allow-list: the {@link #BASELINE_SERIAL_FILTER}, extended with the
     * caller-supplied {@code additions} (typically from {@link #SERIAL_FILTER_PROPERTY}), then
     * terminated with a reject-all so it stays a strict allow-list. Fails safe: if {@code additions}
     * is not a valid filter pattern, the baseline-only allow-list is used rather than leaving the
     * decode path unfiltered.
     */
    static ObjectInputFilter buildFilter(String additions) {
        String extra = (additions == null) ? "" : additions.trim();
        if (!extra.isEmpty()) {
            try {
                return ObjectInputFilter.Config.createFilter(BASELINE_SERIAL_FILTER + ";" + extra + ";!*");
            } catch (RuntimeException e) {
                log.error("Ignoring invalid {}='{}'; using baseline serialization allow-list only",
                        SERIAL_FILTER_PROPERTY, extra, e);
            }
        }
        return ObjectInputFilter.Config.createFilter(BASELINE_SERIAL_FILTER + ";!*");
    }

    /**
     * Number of leading package labels that form the project's group root — the two labels
     * {@code net.a_cappella} of {@code net.a_cappella.continuo.msg}. This is the granularity of the
     * allow-list prefix; if the packages are ever re-rooted at a different depth, change this one
     * value rather than a hard-coded string.
     */
    private static final int PROJECT_PACKAGE_ROOT_LABELS = 2;

    /**
     * The project group root, taken from {@link Msg}'s own package (see
     * {@link #PROJECT_PACKAGE_ROOT_LABELS}), e.g. {@code net.a_cappella}. Deriving it from the class
     * — the way {@code LoggerFactory.getLogger(Msg.class)} derives its name — keeps the deserialization
     * allow-list correct across package renames. Falls back to the full package name if it has fewer
     * labels than expected.
     */
    private static String projectPackageRoot() {
        String pkg = Msg.class.getPackageName();
        int cut = -1;
        for (int i = 0; i < PROJECT_PACKAGE_ROOT_LABELS; i++) {
            int next = pkg.indexOf('.', cut + 1);
            if (next < 0) return pkg; // fewer labels than expected: allow-list the whole package
            cut = next;
        }
        return pkg.substring(0, cut);
    }

    public Msg() {}

    public Msg clone() {
        throw new RuntimeException("'clone' not implemented " + getClass().getName());
    }

    @Override
    public int getMsgType() {
        return SERIAL;
    }

    public void encode(ByteBuffer buffer) {
        try {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            ObjectOutput out = new ObjectOutputStream(bos);
            out.writeObject(this);
            out.close();
            byte[] buf = bos.toByteArray();
            buffer.put(buf);
        } catch (Exception x) {
            log.error("", x);
        }
    }

    public Msg decode(ByteBuffer buffer, int len) {
        byte[] bytes = new byte[len];
        buffer.get(bytes);
        Msg obj = null;
        try {
            ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bytes));
            in.setObjectInputFilter(DESERIALIZATION_FILTER);
            obj = (Msg) in.readObject();
            in.close();
        } catch (Exception x) {
            log.error("", x);
        }
        return obj;
    }


    public static void putString(ByteBuffer buffer, String str) {
        if (str == null) {
            buffer.putShort((short) -1);
        } else {
            int len = str.length();
            buffer.putShort((short) len);
            for (int i = 0; i < len; i++) {
                buffer.putChar(str.charAt(i));
            }
        }
    }

    public static String getString(ByteBuffer buffer) {
        int len = buffer.getShort();
        if (len < 0) return null;
        if (len==0) return "";
        StringBuilder sb = Utils.getThreadLocalStringBuilder();
        for (int i = 0; i < len; i++) {
            sb.append(buffer.getChar());
        }
        return sb.toString();
    }

    public static String getInternedString(ByteBuffer buffer) {
        int len = buffer.getShort();
        if (len < 0) return null;
        if (len==0) return "";
        StringBuilder sb = Utils.getThreadLocalStringBuilder();
        for (int i = 0; i < len; i++) {
            sb.append(buffer.getChar());
        }
        return Utils.intern(sb);
    }



    public static long decodeLongFromString(ByteBuffer buffer) {
        long result = 0;
        int i = 0;
        int len = buffer.getShort();

        while (i < len) {
            int digit = Character.digit(buffer.getChar(), 10);
            result *= 10;
            result += digit;
            i++;
        }

        return result;
    }

    public static void encodeLongAsString(ByteBuffer buffer, long value) {
        int size = stringSize(value);
        buffer.putShort((short) size);

        getChars(value, size, buffer);
    }

    // copied from java.lang.Long
    private static int stringSize(long x) {
        long p = 10;
        for (int i=1; i<19; i++) {
            if (x < p) return i;
            p = 10*p;
        }
        return 19;
    }

    // adapted from java.lang.Long
    private static void getChars(long i, int index, ByteBuffer buf) {
        long q;
        int r;
        int charPos = buf.position() + index*Character.BYTES;
        buf.position(charPos);

        // Get 2 digits/iteration using longs until quotient fits into an int
        while (i > Integer.MAX_VALUE) {
            q = i / 100;
            // really: r = i - (q * 100);
            r = (int)(i - ((q << 6) + (q << 5) + (q << 2)));
            i = q;
            charPos -= Character.BYTES;
            buf.putChar(charPos, DigitOnes[r]);
            charPos -= Character.BYTES;
            buf.putChar(charPos, DigitTens[r]);
        }

        // Get 2 digits/iteration using ints
        int q2;
        int i2 = (int)i;
        while (i2 >= 65536) {
            q2 = i2 / 100;
            // really: r = i2 - (q * 100);
            r = i2 - ((q2 << 6) + (q2 << 5) + (q2 << 2));
            i2 = q2;
            charPos -= Character.BYTES;
            buf.putChar(charPos, DigitOnes[r]);
            charPos -= Character.BYTES;
            buf.putChar(charPos, DigitTens[r]);
        }

        // Fall thru to fast mode for smaller numbers
        // assert(i2 <= 65536, i2);
        for (;;) {
            q2 = (i2 * 52429) >>> (16+3);
            r = i2 - ((q2 << 3) + (q2 << 1));  // r = i2-(q2*10) ...
            charPos -= Character.BYTES;
            buf.putChar(charPos, digits[r]);
            i2 = q2;
            if (i2 == 0) break;
        }
    }

    private final static char[] digits = {
            '0' , '1' , '2' , '3' , '4' , '5' ,
            '6' , '7' , '8' , '9' , 'a' , 'b' ,
            'c' , 'd' , 'e' , 'f' , 'g' , 'h' ,
            'i' , 'j' , 'k' , 'l' , 'm' , 'n' ,
            'o' , 'p' , 'q' , 'r' , 's' , 't' ,
            'u' , 'v' , 'w' , 'x' , 'y' , 'z'
    };

    private final static char [] DigitTens = {
            '0', '0', '0', '0', '0', '0', '0', '0', '0', '0',
            '1', '1', '1', '1', '1', '1', '1', '1', '1', '1',
            '2', '2', '2', '2', '2', '2', '2', '2', '2', '2',
            '3', '3', '3', '3', '3', '3', '3', '3', '3', '3',
            '4', '4', '4', '4', '4', '4', '4', '4', '4', '4',
            '5', '5', '5', '5', '5', '5', '5', '5', '5', '5',
            '6', '6', '6', '6', '6', '6', '6', '6', '6', '6',
            '7', '7', '7', '7', '7', '7', '7', '7', '7', '7',
            '8', '8', '8', '8', '8', '8', '8', '8', '8', '8',
            '9', '9', '9', '9', '9', '9', '9', '9', '9', '9',
    } ;

    private final static char [] DigitOnes = {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    } ;
}
