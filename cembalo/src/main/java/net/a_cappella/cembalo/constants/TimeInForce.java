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

import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_AtClose;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_AtOpen;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_DAY;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_FOK;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_IOC;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_STO;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TimeInForce_Unknown;

public enum TimeInForce {
    STO, DAY, IOC, FOK, AtOpen, AtClose, NULL_VAL;

    public static char toFix(TimeInForce value) {
        switch (value) {
            case DAY: return Val_TimeInForce_DAY;
            case IOC: return Val_TimeInForce_IOC;
            case FOK: return Val_TimeInForce_FOK;
            case STO: return Val_TimeInForce_STO;
            case AtOpen: return Val_TimeInForce_AtOpen;
            case AtClose: return Val_TimeInForce_AtClose;
            default: return Val_TimeInForce_Unknown;
        }
    }
    public static char toFix(String tif) {
        if ("DAY".equals(tif)) {
            return Val_TimeInForce_DAY;
        } else if ("IOC".equals(tif)) {
            return Val_TimeInForce_IOC;
        } else if ("FOK".equals(tif)) {
            return Val_TimeInForce_FOK;
        } else if ("STO".equals(tif)) {
            return Val_TimeInForce_STO;
        } else if ("AtOpen".equals(tif)) {
            return Val_TimeInForce_AtOpen;
        } else if ("AtClose".equals(tif)) {
            return Val_TimeInForce_AtClose;
        } else {
            return Val_TimeInForce_Unknown;
        }
    }

    public static TimeInForce fromFix(char value) {
        switch (value) {
            case Val_TimeInForce_DAY: return DAY;
            case Val_TimeInForce_IOC: return IOC;
            case Val_TimeInForce_FOK: return IOC;
            case Val_TimeInForce_STO: return STO;
            case Val_TimeInForce_AtOpen: return AtOpen;
            case Val_TimeInForce_AtClose: return AtClose;
            default: return NULL_VAL;
        }
    }

    public static String toString(char value) {
        return fromFix(value).toString();
    }
    public static String toString(TimeInForce value) {
        return value.toString();
    }

    @Deprecated
    public static boolean isAuction(TimeInForce tif) {
        switch (tif) {
            case AtOpen:
            case AtClose:
                return true;
            default:
                return false;
        }
    }

    public static boolean isOpenAuction(TimeInForce tif) {
        return tif == AtOpen;
    }

    public static boolean isCloseAuction(TimeInForce tif) {
        return tif == AtClose;
    }

}
