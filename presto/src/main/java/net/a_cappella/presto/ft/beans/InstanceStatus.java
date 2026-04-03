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

import net.a_cappella.presto.ft.constants.FtStatus;

import static net.a_cappella.presto.ft.constants.FtStatus.UNINITIALIZED;

public class InstanceStatus {
    private final int _instance;
    private FtStatus _ftStatus = UNINITIALIZED;
    private int _sliceNo;
    private int _ofSlices;

    public InstanceStatus(int instance) {
        _instance = instance;
    }

    public int getInstance() {
        return _instance;
    }

    public void set(FtStatus ftStatus, int sliceNo, int ofSlices) {
        _ftStatus = ftStatus;
        _sliceNo = sliceNo;
        _ofSlices = ofSlices;
    }
    public boolean already(FtStatus ftStatus, int sliceNo, int ofSlices) {
        return _ftStatus == ftStatus && _sliceNo == sliceNo && _ofSlices == ofSlices;
    }
    public FtStatus getStatus() {
        return _ftStatus;
    }

    public String toString() {
        return String.format("{%s %s %d/%d}", _ftStatus, _instance, _sliceNo, _ofSlices);
    }
}
