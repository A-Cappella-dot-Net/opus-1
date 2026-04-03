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

package net.a_cappella.presto.ft.constants;

public enum FtMsgOp {
    NONE,
    REGISTER, UNREGISTER,                         // REQUESTs
    ACTIVATE, DEACTIVATE, DISCONNECT, DUPLICATE,  // RESPONSEs
    ;

    public static char toChar(FtMsgOp msgOp) {
        switch (msgOp) {
            case REGISTER:
                return 'R';
            case UNREGISTER:
                return 'U';
            case ACTIVATE:
                return '1';
            case DEACTIVATE:
                return '0';
            case DISCONNECT:
                return 'C';
            case DUPLICATE:
                return 'P';
            default:
                return '-';
        }
    }

    public static FtMsgOp toEnum(char msgOp) {
        switch (msgOp) {
            case 'R':
                return REGISTER;
            case 'U':
                return UNREGISTER;
            case '1':
                return ACTIVATE;
            case '0':
                return DEACTIVATE;
            case 'C':
                return DISCONNECT;
            case 'P':
                return DUPLICATE;
            default:
                return NONE;
        }
    }
}
