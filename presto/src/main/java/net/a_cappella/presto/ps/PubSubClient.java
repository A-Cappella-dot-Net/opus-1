package net.a_cappella.presto.ps;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.sql.SqlParserResult;

public interface PubSubClient {
    void waitUntilInitialized();
    void stop();

    AppInfo getAppInfo();

    long snapSubscribe(String sql, ISubscriptionListener subListener) throws Exception;
    long snapSubscribe(String sql, ISubscriptionListener subListener, IMergeManager mergeManager) throws Exception;
    long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception;
    long snap(String sql, ISubscriptionListener subListener) throws Exception;
    long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception;
    long subscribe(String sql, ISubscriptionListener subListener) throws Exception;
    long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception;
    void unsubscribe(long subId);

    int publish(Obj obj) throws Exception;
    int serialize(Obj obj) throws Exception;
    int request(SnapRequestObj obj) throws Exception;
    int reply(Obj obj, PubType pubType) throws Exception;
    void loopback(Obj obj) throws Exception;

    // Chronicle methods
    default void activateSubject(String subject) {}
    default void deactivateSubject(String subject) {}

    // Aeron methods
    default void setMaxReads(int maxRead0, int maxRead1, int maxRead2, int maxRead3) {}
    default void resetStats() {}
    default void logStats() {}
}
