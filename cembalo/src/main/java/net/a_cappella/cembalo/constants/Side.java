package net.a_cappella.cembalo.constants;

import static net.a_cappella.cembalo.generated.FixConstants.Val_Side_Buy;
import static net.a_cappella.cembalo.generated.FixConstants.Val_Side_None;
import static net.a_cappella.cembalo.generated.FixConstants.Val_Side_Sell;
import static net.a_cappella.cembalo.generated.FixConstants.Val_Side_SellShort;

public enum Side {
    Buy, Sell, SellShort, None, NULL_VAL;

    public static char toFix(Side value) {
        switch (value) {
            case Buy: return Val_Side_Buy;
            case Sell: return Val_Side_Sell;
            case SellShort: return Val_Side_SellShort;
            case None: return Val_Side_None;
        }
        return Val_Side_None;
    }

    public static char toFix(String side) {
        switch (side) {
            case "Buy": return Val_Side_Buy;
            case "Sell": return Val_Side_Sell;
            case "SellShort": return Val_Side_SellShort;
            default: return Val_Side_None;
        }
    }

    public static Side fromFix(char value) {
        switch (value) {
            case Val_Side_Buy: return Buy;
            case Val_Side_Sell: return Sell;
            case Val_Side_SellShort: return SellShort;
            case Val_Side_None: return None;
        }
        return None;
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(Side value) {
        return value.toString();
    }
}
