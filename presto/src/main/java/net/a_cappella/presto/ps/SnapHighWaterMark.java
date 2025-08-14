package net.a_cappella.presto.ps;

import net.a_cappella.continuo.obj.Obj;

public interface SnapHighWaterMark {
    void initHighWaterMark(Obj obj);
    boolean isIncludedInSnap(Obj obj);
}
