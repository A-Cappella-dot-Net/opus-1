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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

public class StalingMonitor {
    private static final Logger log = LoggerFactory.getLogger(StalingMonitor.class);

    private MonitorService _service;
    private String _triggerSql;
    private final List<StalingAction> _stalingActions;

    public StalingMonitor(String trigger, List<StalingAction> stalingActions) {
        _triggerSql = trigger;
        _stalingActions = stalingActions;
    }

    public void init(MonitorService service) {
        _service = service;
        for (StalingAction stalingAction : _stalingActions) {
            stalingAction.setService(service);
        }

        if (!_triggerSql.startsWith("select ")) {
            _service.getClient().registerFtMonitor(_triggerSql);
            _triggerSql = "select * from ft.monitor where groupName='"+_triggerSql+"'";
        }

        try {
            log.info("subscribing to triggerSql {}", _triggerSql);
            _service.getClient().subscribe(_triggerSql, (obj, subsId) -> {
                boolean active = _service.isActive();
                log.info("{}handling trigger subscription {} => {}", (active) ? "" : "NOT ", subsId, obj);
                if (!active) return;
                for (StalingAction stalingAction : _stalingActions) {
                    stalingAction.eval(obj);
                }
            });
        } catch (Exception x) {
            log.error("", x);
        }
    }
}

