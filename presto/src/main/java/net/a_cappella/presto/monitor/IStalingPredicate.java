package net.a_cappella.presto.monitor;

import net.a_cappella.continuo.obj.Obj;

public interface IStalingPredicate {
    boolean shouldStale(Obj arg);
}
