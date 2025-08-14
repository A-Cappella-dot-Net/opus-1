package net.a_cappella.presto.ft.beans;

public class GroupAndInstance {
    public String _groupName;
    public int _instance;

    public GroupAndInstance(String groupName, int instance) {
        _groupName = groupName;
        _instance = instance;
    }

    public int hashCode() {
        return _groupName.hashCode()+_instance;
    }
    public boolean equals(Object o) {
        if (o instanceof GroupAndInstance) {
            GroupAndInstance other = (GroupAndInstance) o;
            return _instance==other._instance && _groupName.equals(other._groupName);
        }
        return false;
    }
    public String toString() {
        return _groupName+"-"+_instance;
    }
}
