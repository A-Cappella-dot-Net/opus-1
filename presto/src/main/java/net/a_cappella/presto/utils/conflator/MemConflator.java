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
