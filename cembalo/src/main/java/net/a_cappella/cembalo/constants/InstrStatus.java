package net.a_cappella.cembalo.constants;

import static net.a_cappella.cembalo.generated.FixConstants.Val_QuoteCondition_Closed;
import static net.a_cappella.cembalo.generated.FixConstants.Val_QuoteCondition_Open;

public enum InstrStatus {
    OPEN, CLOSED;

    public static String toFix(InstrStatus value) {
        switch (value) {
            case OPEN: return Val_QuoteCondition_Open;
            case CLOSED: return Val_QuoteCondition_Closed;
        }
        return "?";
    }

    public static InstrStatus fromFix(String value) {
        switch (value) {
            case Val_QuoteCondition_Open: return OPEN;
            case Val_QuoteCondition_Closed: return CLOSED;
        }
        return CLOSED;
    }

    public static String toString(InstrStatus value) {
        return value.toString();
    }

}
