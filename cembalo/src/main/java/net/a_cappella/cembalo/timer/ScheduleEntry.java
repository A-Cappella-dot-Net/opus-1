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

package net.a_cappella.cembalo.timer;

import java.time.LocalTime;
import java.util.List;

public abstract class ScheduleEntry {
    protected long _time;
    private boolean _relative;

    public ScheduleEntry(String time) {
        try {
            _time = Integer.parseInt(time);
            _relative = true;
        } catch (NumberFormatException x) {
            _time = LocalTime.parse(time).toSecondOfDay();
        }
    }

    public void getEventTimes(long nowSeconds, List<TimeAndMessages> timeAndMessageList) {
        if (_relative) _time += nowSeconds;
        getEventTimes(timeAndMessageList);
    }

    public abstract void getEventTimes(List<TimeAndMessages> timeAndMessageList);

}
