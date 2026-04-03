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

import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_DoneForDay;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_OrderStatus;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_PendingCancel;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_PendingNew;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_PendingReplace;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Rejected;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Replaced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Trade;

public enum ExecType {
    New, DoneForDay, Canceled, Replaced, PendingCancel, Rejected, PendingNew, PendingReplace, Trade, OrderStatus;

    public static char toFix(ExecType value) {
        switch (value) {
            case New: return Val_ExecType_New;
            case DoneForDay: return Val_ExecType_DoneForDay;
            case Canceled: return Val_ExecType_Canceled;
            case Replaced: return Val_ExecType_Replaced;
            case PendingCancel: return Val_ExecType_PendingCancel;
            case Rejected: return Val_ExecType_Rejected;
            case PendingNew: return Val_ExecType_PendingNew;
            case PendingReplace: return Val_ExecType_PendingReplace;
            case Trade: return Val_ExecType_Trade;
            case OrderStatus: return Val_ExecType_OrderStatus;
        }
        return '?';
    }

    public static char toFix(String value) {
        switch (value) {
            case "New": return Val_ExecType_New;
            case "DoneForDay": return Val_ExecType_DoneForDay;
            case "Canceled": return Val_ExecType_Canceled;
            case "Replaced": return Val_ExecType_Replaced;
            case "PendingCancel": return Val_ExecType_PendingCancel;
            case "Rejected": return Val_ExecType_Rejected;
            case "PendingNew": return Val_ExecType_PendingNew;
            case "PendingReplace": return Val_ExecType_PendingReplace;
            case "Trade": return Val_ExecType_Trade;
            case "OrderStatus": return Val_ExecType_OrderStatus;
        }
        return '?';
    }

    public static ExecType fromFix(char value) {
        switch (value) {
            case Val_ExecType_New: return New;
            case Val_ExecType_DoneForDay: return DoneForDay;
            case Val_ExecType_Canceled: return Canceled;
            case Val_ExecType_Replaced: return Replaced;
            case Val_ExecType_PendingCancel: return PendingCancel;
            case Val_ExecType_Rejected: return Rejected;
            case Val_ExecType_PendingNew: return PendingNew;
            case Val_ExecType_PendingReplace: return PendingReplace;
            case Val_ExecType_Trade: return Trade;
            case Val_ExecType_OrderStatus: return OrderStatus;
        }
        return New;
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(ExecType value) {
        return value.toString();
    }
}
