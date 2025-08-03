package net.a_cappella.cembalo.constants;

import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_DoneForDay;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Filled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_PartiallyFilled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_PendingCancel;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Rejected;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Replaced;

public enum OrdStatus {
    New, PartiallyFilled, Filled, DoneForDay, Canceled, Replaced, PendingCancel, Rejected;

    public static char toFix(OrdStatus value) {
        switch (value) {
            case New: return Val_OrdStatus_New;
            case PartiallyFilled: return Val_OrdStatus_PartiallyFilled;
            case Filled: return Val_OrdStatus_Filled;
            case DoneForDay: return Val_OrdStatus_DoneForDay;
            case Canceled: return Val_OrdStatus_Canceled;
            case Replaced: return Val_OrdStatus_Replaced;
            case PendingCancel: return Val_OrdStatus_PendingCancel;
            case Rejected: return Val_OrdStatus_Rejected;
        }
        return '?';
    }

    public static char toFix(String value) {
        switch (value) {
            case "New": return Val_OrdStatus_New;
            case "PartiallyFilled": return Val_OrdStatus_PartiallyFilled;
            case "Filled": return Val_OrdStatus_Filled;
            case "DoneForDay": return Val_OrdStatus_DoneForDay;
            case "Canceled": return Val_OrdStatus_Canceled;
            case "Replaced": return Val_OrdStatus_Replaced;
            case "PendingCancel": return Val_OrdStatus_PendingCancel;
            case "Rejected": return Val_OrdStatus_Rejected;
            default: return '?';
        }
    }

    public static OrdStatus fromFix(char value) {
        switch (value) {
            case Val_OrdStatus_New: return New;
            case Val_OrdStatus_PartiallyFilled: return PartiallyFilled;
            case Val_OrdStatus_Filled: return Filled;
            case Val_OrdStatus_DoneForDay: return DoneForDay;
            case Val_OrdStatus_Canceled: return Canceled;
            case Val_OrdStatus_Replaced: return Replaced;
            case Val_OrdStatus_PendingCancel: return PendingCancel;
            case Val_OrdStatus_Rejected: return Rejected;
        }
        return New;
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(OrdStatus value) {
        return value.toString();
    }
}
