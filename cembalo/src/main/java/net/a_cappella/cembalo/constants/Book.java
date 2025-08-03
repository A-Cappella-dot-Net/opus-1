package net.a_cappella.cembalo.constants;

import net.a_cappella.cembalo.generated.FixConstants;

public enum Book {
    OPEN_BK, CONTINUOUS_BK, CLOSE_BK, NULL_VAL;

    public static char toFix(Book value) {
        switch (value) {
            case OPEN_BK: return FixConstants.Val_MDBook_Open;
            case CONTINUOUS_BK: return FixConstants.Val_MDBook_Continuous;
            case CLOSE_BK: return FixConstants.Val_MDBook_Close;
            default: return '?';
        }
    }

    public static Book fromFix(char value) {
        switch (value) {
            case FixConstants.Val_MDBook_Open: return OPEN_BK;
            case FixConstants.Val_MDBook_Continuous: return CONTINUOUS_BK;
            case FixConstants.Val_MDBook_Close: return CLOSE_BK;
        }
        return NULL_VAL;
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(Book value) {
        return value.toString();
    }
    public static Book fromString(String value) {
        switch (value) {
            case "open": return OPEN_BK;
            case "close": return CLOSE_BK;
            case "continuous": return CONTINUOUS_BK;
        }
        return NULL_VAL;
    }
}
