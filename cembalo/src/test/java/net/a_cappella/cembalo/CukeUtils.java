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

package net.a_cappella.cembalo;

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
        return Double.parseDouble(str);
    }
}
