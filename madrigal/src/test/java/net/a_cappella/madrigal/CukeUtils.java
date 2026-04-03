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

package net.a_cappella.madrigal;

import io.cucumber.java.ParameterType;
import net.a_cappella.madrigal.common.constants.*;

public class CukeUtils {
    public static double parseDoubleNaN(String str) {
        if (str == null) return Double.NaN;
        if (str.trim().isEmpty()) return Double.NaN;
        if ("NaN".equalsIgnoreCase(str)) return Double.NaN;
        if ("Inf".equalsIgnoreCase(str)) return Double.POSITIVE_INFINITY;
        if ("-Inf".equalsIgnoreCase(str)) return Double.NEGATIVE_INFINITY;
        return Double.parseDouble(str);
    }
    public static double parseDouble(String str) {
        if (str == null) return 0.0;
        if (str.trim().isEmpty()) return 0.0;
        if ("NaN".equalsIgnoreCase(str)) return Double.NaN;
        return Double.parseDouble(str);
    }

    @ParameterType(".+")
    public double price(String string) {
        return parseDoubleNaN(string);
    }

    public static Integer parseInteger(String str) {
        if (str == null) return null;
        return Integer.parseInt(str);
    }

    public static Boolean parseBoolean(String str) {
        if (str == null) return null;
        return Boolean.parseBoolean(str);
    }

    public static int parseInt(String str) {
        if (str == null) return 0;
        return Integer.parseInt(str);
    }

    public static long parseLong(String str) {
        if (str == null) return 0;
        return Long.parseLong(str);
    }

    public static MadrigalActionOnFailover parseMadrigalActionOnFailover(String str) {
        if (str == null) return null;
        if ("ALWAYS_CANCEL".equals(str)) {
            return MadrigalActionOnFailover.ALWAYS_CANCEL;
        } else if ("ALWAYS_RESUME".equals(str)) {
            return MadrigalActionOnFailover.ALWAYS_RESUME;
        } else if ("RESUME_IF_RECENT".equals(str)) {
            return MadrigalActionOnFailover.RESUME_IF_RECENT;
        }
        return null;
    }

    public static MadrigalMode parseMadrigalMode(String str) {
        if (str == null) return null;
        return MadrigalMode.valueOf(str);
    }

    public static MadrigalOrdType parseMadrigalOrdType(String str) {
        if (str == null) return null;
        return MadrigalOrdType.valueOf(str);
    }

    public static MadrigalOrdStatus parseMadrigalOrdStatus(String str) {
        if (str == null) return null;
        return MadrigalOrdStatus.valueOf(str);
    }

    public static MadrigalReqType parseMadrigalReqType(String str) {
        if (str == null) return null;
        return MadrigalReqType.valueOf(str);
    }

    public static MadrigalTimeInForce parseMadrigalTimeInForce(String str) {
        if (str == null) return null;
        return MadrigalTimeInForce.valueOf(str);
    }

    public static MadrigalSide parseMadrigalSide(String str) {
        if (str == null) return null;
        return MadrigalSide.valueOf(str);
    }

    public static Integer parseVer(String str) {
        if (str == null) return 0;
        return Integer.parseInt(str);
    }
}
