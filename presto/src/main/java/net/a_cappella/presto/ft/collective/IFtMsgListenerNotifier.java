package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.constants.FtMsgOp;

public interface IFtMsgListenerNotifier {
    void notifyFtMemberListeners(String groupName, int instance, FtMsgOp action, int sliceNo, int ofSlices);
    void notifyFtMonitorListeners(String groupName, int actives);
    String getNotifierId();
}
