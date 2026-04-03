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

import static net.a_cappella.cembalo.generated.FixConstants.Val_MDBookPhase_All;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDBookPhase_Closed;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDBookPhase_Matching;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDBookPhase_NonMatching;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDBookPhase_OnlyNew;

public enum InstrPhase {
    CLOSED, ALL, ONLY_NEW, // apply only to Auction book
    NON_MATCHING, MATCHING; // apply only to Continuous Book

    public static char toFix(InstrPhase value) {
        switch (value) {
            case CLOSED: return Val_MDBookPhase_Closed;
            case ALL: return Val_MDBookPhase_All;
            case ONLY_NEW: return Val_MDBookPhase_OnlyNew;
            case NON_MATCHING: return Val_MDBookPhase_NonMatching;
            case MATCHING: return Val_MDBookPhase_Matching;
        }
        return '?';
    }

    public static InstrPhase fromFix(char value) {
        switch (value) {
            case Val_MDBookPhase_Closed: return CLOSED;
            case Val_MDBookPhase_All: return ALL;
            case Val_MDBookPhase_OnlyNew: return ONLY_NEW;
            case Val_MDBookPhase_NonMatching: return NON_MATCHING;
            case Val_MDBookPhase_Matching: return MATCHING;
        }
        return CLOSED;
    }

    public static String toString(InstrPhase value) {
        return value.toString();
    }

}
