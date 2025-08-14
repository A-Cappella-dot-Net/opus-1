package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.ft.constants.MemberStatusEnum;

import static net.a_cappella.presto.ft.constants.MemberStatusEnum.*;

public class MemberStatus {
    private MemberStatusEnum _viaSink = DOWN;
    private MemberStatusEnum _viaPipe = IDK;

    public MemberStatus() {}

    public void setSinkConnectionStatus(MemberStatusEnum status) {
        _viaSink = status;
    }
    public MemberStatusEnum getSinkConnectionStatus() {
        return _viaSink;
    }
    public void setPipeConnectionStatus(MemberStatusEnum status) {
        _viaPipe = status;
    }
    public MemberStatusEnum getPipeConnectionStatus() {
        return _viaPipe;
    }

    public void setStatus(MemberStatusEnum status) {
        _viaSink = status;
        _viaPipe = status;
    }
    public MemberStatusEnum getStatus(boolean iAmCore) {
        if (_viaPipe == IDK) {
            return IDK;
        }
        if ((!iAmCore || _viaSink == UP) && _viaPipe == UP) {
            return UP;
        }
        return DOWN;
    }

    public String toString() {
        return "{"+_viaSink+" "+_viaPipe+"}";
    }
}
