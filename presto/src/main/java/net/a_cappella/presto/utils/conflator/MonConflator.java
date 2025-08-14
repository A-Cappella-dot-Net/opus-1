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
