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
