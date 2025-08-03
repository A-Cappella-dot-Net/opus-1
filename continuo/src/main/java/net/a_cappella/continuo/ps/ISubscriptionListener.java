package net.a_cappella.continuo.ps;

import net.a_cappella.continuo.obj.Obj;

@FunctionalInterface
public interface ISubscriptionListener {
    void onSubscriptionMessage(Obj obj, long subsId);
    default void onHighWaterMark(Obj hwm) {}
}
