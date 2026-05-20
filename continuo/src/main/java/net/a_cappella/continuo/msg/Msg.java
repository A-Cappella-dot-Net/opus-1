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
