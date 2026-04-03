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
