package net.a_cappella.continuo.managed;

import java.util.concurrent.atomic.AtomicInteger;

import net.a_cappella.continuo.msg.Msg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class Poolable implements IPoolable {
    private static final Logger log = LoggerFactory.getLogger(Poolable.class);

    protected boolean _pooled;
    protected int _identityHashCode;

    public boolean isPooled() {
        return _pooled;
    }
    public void setPooled(boolean pooled) {
        _pooled = pooled;
        _identityHashCode = System.identityHashCode(this);
    }

    public int getIdentityHashCode() {
        return _identityHashCode;
    }

    protected AtomicInteger _numberOfUsers = new AtomicInteger();

    @Override
    public void acquire() {
        int oldValue = _numberOfUsers.getAndSet(1);
        if (oldValue != 0) {
            if (this instanceof Msg) {
                String info = "===> acquire "+((Msg)this).getMsgType()+" "+_identityHashCode+" "+this;
                System.out.println(info);
                log.error(info);
            } else {
                String info = "===> acquire "+this.getClass().getCanonicalName()+" "+_identityHashCode+" "+this;
                System.out.println(info);
                log.error(info);
            }

//        	try {Thread.sleep(500);} catch(Exception x) {}
//        	System.exit(-1);
        }
    }

    @Override
    public void startUsing() {
        if (!_pooled) return;
        if (_numberOfUsers.getAndIncrement() == 0) {
            // not thread safe!!!
            _numberOfUsers.set(0);
            throw new IllegalStateException("Object has not been acquired from pool yet! " + this);
        }
    }

    @Override
    public void stopUsing() {
        if (!_pooled) return;
        if (_numberOfUsers.decrementAndGet() == 0) {
//			if (this instanceof Msg) {
//				String info = "===> release "+((Msg)this).getMsgType()+" "+_identityHashCode+" "+this;
//				log.info(info);
//				System.out.println(info);
//			}

            this.reset();
            ObjectManager.getInstance().release(this);
        }
    }

    @Override
    public int getNumUsers() {
        return _numberOfUsers.get();
    }
}
