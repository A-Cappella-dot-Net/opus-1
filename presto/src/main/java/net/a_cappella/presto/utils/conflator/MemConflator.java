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

import net.a_cappella.presto.ft.beans.ActionNoOf;
import net.a_cappella.presto.ft.beans.GroupAndInstance;
import net.a_cappella.presto.ft.collective.IFtMsgListenerNotifier;
import net.a_cappella.presto.ft.constants.FtMsgOp;

public class MemConflator extends BaseConflator<GroupAndInstance, ActionNoOf> {

    public MemConflator(long conflationInterval, IFtMsgListenerNotifier notifier) {
        super(conflationInterval, notifier);
    }

    @Override
    public void notifyFtMsgListeners(GroupAndInstance key, ActionNoOf value) {
        _notifier.notifyFtMemberListeners(key._groupName, key._instance, value._op, value._sliceNo, value._ofSlices);
    }

    public void conflate(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices, boolean force) {
        conflate(new GroupAndInstance(groupName, instance), new ActionNoOf(op, sliceNo, ofSlices), force);
    }

    public void conflate(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices) {
        conflate(new GroupAndInstance(groupName, instance), new ActionNoOf(op, sliceNo, ofSlices), false);
    }
}
