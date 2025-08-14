package net.a_cappella.presto.ps;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISnSHandler;
import net.a_cappella.continuo.ps.ISubscriptionListener;

public abstract class AbstractMergeManager implements IMergeManager {
    protected ISubscriptionListener _subListener;
    protected String _subject;
    protected long _subId;

    @Override
    public void setHandler(ISnSHandler handler) {
        _subListener = handler.getSubListener();
        _subject = handler.getSubject();
        _subId = handler.getSubId();
    }

    abstract public void onSnpMsg(Obj obj);
    abstract public void onPub(Obj obj);
    abstract public void onSnapComplete();
}
