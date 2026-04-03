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

package net.a_cappella.presto.ps;

import io.aeron.driver.ThreadingMode;
import org.agrona.DirectBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.awt.event.KeyEvent;

public class Utils {
    private static final Logger log = LoggerFactory.getLogger(Utils.class);

    private static final char[] hex_table = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };

    /**
     * Convert a byte array to a human-readable String for debugging purposes.
     * Alternatively, use org.apache.commons.io.HexDump (org.apache.commons/commons-lang3)
     */
    public static String hexDump(byte[] data) {
        StringBuilder str = new StringBuilder(data.length * 3);
        str.append("\n");

        for (int i = 0; i < data.length; i += 16) {
            // dump the header: 00000000:
            String offset = Integer.toHexString(i);

            // "0" left pad offset field so it is always 8 char's long.
            for (int offlen = offset.length(); offlen < 8; offlen++)
                str.append("0");
            str.append(offset);
            str.append(":");

            // dump hex version of 16 bytes per line.
            for (int j = 0; (j < 16) && ((i + j) < data.length); j++) {
                byte byte_value = data[i + j];

                // add spaces between every 2 bytes.
                if ((j % 2) == 0)
                    str.append(" ");

                // dump a single byte.
                byte high_nibble = (byte) ((byte_value & 0xf0) >>> 4);
                byte low_nibble = (byte) (byte_value & 0x0f);

                str.append(hex_table[high_nibble]);
                str.append(hex_table[low_nibble]);
            }
            if (i+16 > data.length) {
                int k = data.length % 16;
                if (k%2 == 0) {
                    for (int j=k/2; j<8; j++) str.append("     ");
                } else {
                    for (int j=(k+1)/2; j<8; j++) str.append("     ");
                    str.append("  ");
                }
            }

            // dump ascii version of 16 bytes
            str.append("  ");

            for (int j = 0; (j < 16) && ((i + j) < data.length); j++) {
                char char_value = (char) data[i + j];

                // RESOLVE (really want isAscii() or isPrintable())
                if (isPrintableChar3(char_value)) // (Character.isLetterOrDigit(char_value))
                    str.append(char_value);
                else
                    str.append(".");
            }

            // new line
            str.append("\n");
        }
        return str.toString();

    }

    public static String hexDump(DirectBuffer buffer, int offset, int length) {
        StringBuilder str = new StringBuilder(length * 3);
        str.append("\n");

        for (int i = 0; i < length; i += 16) {
            // dump the header: 00000000:
            String header = Integer.toHexString(i);

            // "0" left pad offset field so it is always 8 char's long.
            for (int offlen = header.length(); offlen < 8; offlen++)
                str.append("0");
            str.append(header);
            str.append(":");

            // dump hex version of 16 bytes per line.
            for (int j = 0; (j < 16) && ((i + j) < length); j++) {
                byte byte_value = buffer.getByte(offset + i + j);

                // add spaces between every 2 bytes.
                if ((j % 2) == 0)
                    str.append(" ");

                // dump a single byte.
                byte high_nibble = (byte) ((byte_value & 0xf0) >>> 4);
                byte low_nibble = (byte) (byte_value & 0x0f);

                str.append(hex_table[high_nibble]);
                str.append(hex_table[low_nibble]);
            }
            if (i+16 > length) {
                int k = length % 16;
                if (k%2 == 0) {
                    for (int j=k/2; j<8; j++) str.append("     ");
                } else {
                    for (int j=(k+1)/2; j<8; j++) str.append("     ");
                    str.append("  ");
                }
            }

            // dump ascii version of 16 bytes
            str.append("  ");

            for (int j = 0; (j < 16) && ((i + j) < length); j++) {
                char char_value = (char) buffer.getByte(offset + i + j);

                // RESOLVE (really want isAscii() or isPrintable())
                if (isPrintableChar3(char_value)) // (Character.isLetterOrDigit(char_value))
                    str.append(char_value);
                else
                    str.append(".");
            }

            // new line
            str.append("\n");
        }
        return str.toString();

    }

    private static boolean isPrintableChar( char c ) {
        Character.UnicodeBlock block = Character.UnicodeBlock.of( c );
        return (!Character.isISOControl(c)) &&
                c != KeyEvent.CHAR_UNDEFINED &&
                block != null &&
                block != Character.UnicodeBlock.SPECIALS;
    }

    private static boolean isPrintableChar2( char c ) {
        switch (Character.getType(c)) {
            case Character.CONTROL:
            case Character.FORMAT:
            case Character.PRIVATE_USE:
            case Character.SURROGATE:
            case Character.UNASSIGNED:
                return false;
            default:
                return true;
        }
    }

    private static boolean isPrintableChar3( char ch ) {
        return ch >= 32 && ch < 127;
    }

    public static ThreadingMode getThreadingMode(String threadingModeStr, ThreadingMode defaultThreadingMode) {
        switch (threadingModeStr) {
            case "invoker":
                return ThreadingMode.INVOKER;
            case "shared":
                return ThreadingMode.SHARED;
            case "shared-network":
                return ThreadingMode.SHARED_NETWORK;
            case "dedicated":
                return ThreadingMode.DEDICATED;
            default:
                log.warn("Unknown threading mode " + threadingModeStr + ". Defaulting to " + defaultThreadingMode);
                return defaultThreadingMode;
        }
    }





    public static void main(String[] args) {
        byte[] bytes = new byte[] {
                0,1,2,3,4,5,6,7,8,9,
                10,11,12,13,14,15,16,17,18,19,
                20,21,22,23,24,25,26,27,28,29,
                30,31,32,33,34,35,36,37,38,39,
                40,41,42,43,44,45,46,47,48,49,
                50,51,52,53,54,55,56,57,58,59,
                60,61,62,63,64,65,66,67,68,69,
                70,71,72,73,74,75,76,77,78,79,
                80,81,82,83,84,85,86,87,88,89,
                90,91,92,93,94,95,96,97,98,99,
        };
        System.out.println(hexDump(bytes));
    }
}
