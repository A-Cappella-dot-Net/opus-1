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

package net.a_cappella.cembalo;

import net.a_cappella.cembalo.constants.Book;

public enum Operation {
    CLOSE, OPEN, ALL, ONLY_NEW, IMBALANCE, AUCTION, NON_MATCHING, MATCHING, HALT, NULL_VAL;

    public static char toChar(Operation value) {
        switch (value) {
            case CLOSE: return '0';
            case OPEN: return '1';
            case ALL: return '2';
            case ONLY_NEW: return '3';
            case IMBALANCE: return '4';
            case AUCTION: return '5';
            case NON_MATCHING: return '6';
            case MATCHING: return '7';
            case HALT: return '8';
            default: return '?';
        }
    }

    public static Operation fromChar(char value) {
        switch (value) {
            case '0': return CLOSE;
            case '1': return OPEN;
            case '2': return ALL;
            case '3': return ONLY_NEW;
            case '4': return IMBALANCE;
            case '5': return AUCTION;
            case '6': return NON_MATCHING;
            case '7': return MATCHING;
            case '8': return HALT;
        }
        return NULL_VAL;
    }

    public static String toString(char value) {
        return fromChar(value).toString();
    }
    public static String toString(Operation value) {
        return value.toString();
    }
    public static Operation fromString(Book book, String value) {
        switch (value) {
            case "open": return OPEN;
            case "close": return CLOSE;
        }

        switch (book) {
            case OPEN_BK:
            case CLOSE_BK:
                switch (value) {
                    case "all": return ALL;
                    case "only_new": return ONLY_NEW;
                    case "imbalance": return IMBALANCE;
                    case "auction": return AUCTION;
                    default: return NULL_VAL;
                }
            case CONTINUOUS_BK:
                switch (value) {
                    case "non_matching": return NON_MATCHING;
                    case "matching": return MATCHING;
                    default: return NULL_VAL;
                }
            default: return NULL_VAL;
        }
    }

}
