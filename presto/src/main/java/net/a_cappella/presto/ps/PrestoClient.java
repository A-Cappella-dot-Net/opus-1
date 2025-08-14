package net.a_cappella.presto.ps;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.presto.ft.collective.IFtMemberClient;
import net.a_cappella.presto.ft.collective.IFtMonitorClient;

public interface PrestoClient extends IFtMemberClient, IFtMonitorClient, PubSubClient {
    AppInfo getAppInfo();
    long getSeqNo();
    void setSeqNo(long seqNo);
    void addSnippet(TightLoopSnippet snippet);
    boolean onTLT();
}
