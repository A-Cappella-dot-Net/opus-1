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
