package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.msg.FtMemberMsg;

import java.nio.channels.SelectionKey;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class MemAndKey {
    public FtMemberMsg _mem;
    public SelectionKey _key;
    public char _fromApp;

    public MemAndKey(FtMemberMsg mem) {
        _mem = mem;
    }

    public String toString() {
        return "{"+keyHash(_key)+"="+_fromApp+"}";
    }
}
