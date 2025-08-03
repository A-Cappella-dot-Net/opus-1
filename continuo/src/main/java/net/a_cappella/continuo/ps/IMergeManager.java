package net.a_cappella.continuo.ps;

import net.a_cappella.continuo.obj.Obj;

public interface IMergeManager {
    void setHandler(ISnSHandler handler);
    void onSnpMsg(Obj obj);
    default void onSnpHwm(Obj obj) {}
    void onPub(Obj obj);
    void onSnapComplete();
}
