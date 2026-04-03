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

package net.a_cappella.continuo.utils.interner;

/*
 * Based on org.apache.commons.codec.digest.MurmurHash3.
 * Implements method hash32x86 with CharSequence parameter instead of byte[].
 */
public class MurmurHash3 {

    public static final int DEFAULT_SEED = 104729;

    // Constants for 32-bit variant
    private static final int C1_32 = 0xcc9e2d51;
    private static final int C2_32 = 0x1b873593;
    private static final int R1_32 = 15;
    private static final int R2_32 = 13;
    private static final int M_32 = 5;
    private static final int N_32 = 0xe6546b64;

    public static int hash32x86(final CharSequence data, final int offset, final int length, final int seed) {
        int hash = seed;
        final int nblocks = length >> 2;

        // body
        for (int i = 0; i < nblocks; i++) {
            final int index = offset + (i << 2);
            final int k = getLittleEndianInt(data, index);
            hash = mix32(k, hash);
        }

        // tail
        final int index = offset + (nblocks << 2);
        int k1 = 0;
        switch (offset + length - index) {
            case 3:
                k1 ^= (data.charAt(index + 2) & 0xff) << 16;
            case 2:
                k1 ^= (data.charAt(index + 1) & 0xff) << 8;
            case 1:
                k1 ^= (data.charAt(index) & 0xff);

                // mix functions
                k1 *= C1_32;
                k1 = Integer.rotateLeft(k1, R1_32);
                k1 *= C2_32;
                hash ^= k1;
        }

        hash ^= length;
        return fmix32(hash);
    }

    private static int getLittleEndianInt(final CharSequence data, final int index) {
        return ((data.charAt(index    ) & 0xff)      ) |
                ((data.charAt(index + 1) & 0xff) <<  8) |
                ((data.charAt(index + 2) & 0xff) << 16) |
                ((data.charAt(index + 3) & 0xff) << 24);
    }

    private static int mix32(int k, int hash) {
        k *= C1_32;
        k = Integer.rotateLeft(k, R1_32);
        k *= C2_32;
        hash ^= k;
        return Integer.rotateLeft(hash, R2_32) * M_32 + N_32;
    }

    private static int fmix32(int hash) {
        hash ^= (hash >>> 16);
        hash *= 0x85ebca6b;
        hash ^= (hash >>> 13);
        hash *= 0xc2b2ae35;
        hash ^= (hash >>> 16);
        return hash;
    }
}
