package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.constants.FtMsgOp;

public interface IFtMemberListener {
    void onFtAction(String groupName, int instance, FtMsgOp action, int sliceNo, int ofSlices);
}
