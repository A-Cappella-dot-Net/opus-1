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

package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.ft.constants.MemberStatusEnum;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.*;

public class MemberStatus {
    private MemberStatusEnum _viaSink = DOWN;
    private MemberStatusEnum _viaPipe = IDK;

    public MemberStatus() {}

    public void setSinkConnectionStatus(MemberStatusEnum status) {
        _viaSink = status;
    }
    public MemberStatusEnum getSinkConnectionStatus() {
        return _viaSink;
    }
    public void setPipeConnectionStatus(MemberStatusEnum status) {
        _viaPipe = status;
    }
    public MemberStatusEnum getPipeConnectionStatus() {
        return _viaPipe;
    }

    public MemberStatusEnum getStatus(boolean iAmCore) {
        if (_viaPipe == IDK) {
            return IDK;
        }
        if (!iAmCore) {
            // A non-core member only opens an outgoing pipe to the cores; no return sink
            // connection is expected, so the pipe direction alone determines the status.
            return _viaPipe == UP ? UP : DOWN;
        }
        if (_viaSink == UP && _viaPipe == UP) {
            return UP;
        }
        if (_viaSink == DOWN && _viaPipe == DOWN) {
            return DOWN;
        }
        return HALF_UP;
    }

    public String toString() {
        return "{"+_viaSink+" "+_viaPipe+"}";
    }
}
