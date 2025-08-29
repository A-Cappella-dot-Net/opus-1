package net.a_cappella.mcache;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.CacheCmdObj;

import java.util.function.Consumer;

public interface IObjCache {
	void onSubscriptionMessage(Obj obj, long subsId);
	default void initHighWaterMark(Obj hwm) {}
	void publishSnapRecords(Consumer<Obj> consumer);
	default void publishHighWaterMark(Consumer<Obj> consumer) {}
	void onCacheCmdMessage(CacheCmdObj obj);
	void log();
}
