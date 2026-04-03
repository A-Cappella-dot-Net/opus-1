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

public enum FtMsgType {
    NONE, REQUEST, RESPONSE;

    public static char toChar(FtMsgType msgType) {
        switch (msgType) {
            case REQUEST:
                return 'Q';
            case RESPONSE:
                return 'P';
            default:
                return ' ';
        }
    }

    public static FtMsgType toEnum(char msgType) {
        switch (msgType) {
            case 'Q':
                return REQUEST;
            case 'P':
                return RESPONSE;
            default:
                return NONE;
        }
    }
}
