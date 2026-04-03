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

package net.a_cappella.presto.utils.conflator;

import net.a_cappella.presto.ft.collective.IFtMsgListenerNotifier;

public class MonConflator extends BaseConflator<String, Integer> {

    public MonConflator(long conflationInterval, IFtMsgListenerNotifier notifier) {
        super(conflationInterval, notifier);
    }

    @Override
    public void notifyFtMsgListeners(String groupName, Integer actives) {
        _notifier.notifyFtMonitorListeners(groupName, actives);
    }

    public void conflate(String groupName, int actives, boolean force) {
        super.conflate(groupName, actives, force);
    }

    public void conflate(String groupName, int actives) {
        super.conflate(groupName, actives, false);
    }
}
