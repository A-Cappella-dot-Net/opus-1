package net.a_cappella.presto.ps;

import net.a_cappella.continuo.obj.Obj;

public class PassThruMergeManager extends AbstractMergeManager {

    @Override
    public void onSnpMsg(Obj obj) {
        _subListener.onSubscriptionMessage(obj, _subId);
    }

    @Override
    public void onPub(Obj obj) {
        _subListener.onSubscriptionMessage(obj, _subId);
    }

    @Override
    public void onSnapComplete() {
        // do nothing
    }
}
