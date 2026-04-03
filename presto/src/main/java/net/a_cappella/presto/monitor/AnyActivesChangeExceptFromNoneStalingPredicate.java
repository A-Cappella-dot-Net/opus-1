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

package net.a_cappella.presto.monitor;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.obj.FtMonitorObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AnyActivesChangeExceptFromNoneStalingPredicate implements IStalingPredicate {
    private static final Logger log = LoggerFactory.getLogger(AnyActivesChangeExceptFromNoneStalingPredicate.class);

    private int _actives = CollectiveClient.NONE;

    @Override
    public boolean shouldStale(Obj obj) {
        boolean result;

        FtMonitorObj ftMon = (FtMonitorObj) obj;
        int actives = ftMon.getActives();

        if (actives == _actives) result = false;
        else if (_actives == CollectiveClient.NONE) {
            _actives = actives;
            result = false;
        } else {
            _actives = actives;
            result = true;
        }

        log.info("shouldStale({}) => {}", obj, result);
        return result;
    }

}
