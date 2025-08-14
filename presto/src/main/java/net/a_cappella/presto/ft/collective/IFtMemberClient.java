package net.a_cappella.presto.ft.collective;

public interface IFtMemberClient {
    void registerFtMemberListener(IFtMemberListener listener);
    void unregisterFtMemberListener(IFtMemberListener listener);
    void registerFtMember(String groupName, int instance, int activeGoal);
    void unregisterFtMember(String groupName, int instance);
}
