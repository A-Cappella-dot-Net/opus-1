package net.a_cappella.presto.ft.collective;

public interface IFtMonitorClient {
    void registerFtMonitorListener(IFtMonitorListener listener);
    void unregisterFtMonitorListener(IFtMonitorListener listener);
    void registerFtMonitor(String groupName);
    void unregisterFtMonitor(String groupName);
}
