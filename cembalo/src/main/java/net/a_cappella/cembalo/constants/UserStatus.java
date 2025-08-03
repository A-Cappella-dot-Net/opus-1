package net.a_cappella.cembalo.constants;

import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_LoggedIn;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_NotLoggedIn;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_PasswordIncorrect;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_UserNotRecognized;

public enum UserStatus {
    LOGGED_IN, NOT_LOGGED_IN, NOT_RECOGNIZED, PASSWORD_INCORRECT, OTHER;

    public static UserStatus fromFix(int value) {
        switch (value) {
            case Val_UserStatus_LoggedIn: return LOGGED_IN;
            case Val_UserStatus_NotLoggedIn: return NOT_LOGGED_IN;
            case Val_UserStatus_UserNotRecognized: return NOT_RECOGNIZED;
            case Val_UserStatus_PasswordIncorrect: return PASSWORD_INCORRECT;
            case Val_UserStatus_Other: return OTHER;
            default: return OTHER;
        }
    }

    public static String toString(UserStatus value) {
        return value.toString();
    }
}
