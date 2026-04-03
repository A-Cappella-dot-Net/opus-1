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
