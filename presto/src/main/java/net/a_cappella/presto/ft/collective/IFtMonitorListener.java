package net.a_cappella.presto.ft.collective;

public interface IFtMonitorListener {
    void onActivesChanged(String groupName, int actives);
}
