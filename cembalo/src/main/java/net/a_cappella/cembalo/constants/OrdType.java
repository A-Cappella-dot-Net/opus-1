package net.a_cappella.cembalo.constants;

import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdType_Limit;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdType_Market;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdType_Pegged;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdType_Unknown;

public enum OrdType {
    Market, Limit, Pegged, Unknown;

    public static char toFix(OrdType value) {
        switch (value) {
            case Market: return Val_OrdType_Market;
            case Limit: return Val_OrdType_Limit;
            case Pegged: return Val_OrdType_Pegged;
            default: return Val_OrdType_Unknown;
        }
    }
    public static char toFix(String ordType) {
        switch (ordType) {
            case "Market": return Val_OrdType_Market;
            case "Limit": return Val_OrdType_Limit;
            case "Pegged": return Val_OrdType_Pegged;
            default: return Val_OrdType_Unknown;
        }
    }

    public static OrdType fromFix(char value) {
        switch (value) {
            case Val_OrdType_Market: return Market;
            case Val_OrdType_Limit: return Limit;
            case Val_OrdType_Pegged: return Pegged;
            default: return Unknown;
        }
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(OrdType value) {
        return value.toString();
    }

}
