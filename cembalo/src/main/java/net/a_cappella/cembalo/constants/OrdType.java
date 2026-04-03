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
