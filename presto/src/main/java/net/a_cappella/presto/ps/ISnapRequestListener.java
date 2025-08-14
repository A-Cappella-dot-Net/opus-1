package net.a_cappella.presto.ps;

import net.a_cappella.presto.obj.SnapRequestObj;

@FunctionalInterface
public interface ISnapRequestListener {
    void onSnapRequest(SnapRequestObj obj, long subsId);
}
