package net.a_cappella.presto.ps;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

public class SnSManager {
    // TODO optimize for case where there are many subscriptions for limited numbers of key values
    private static final Logger log = LoggerFactory.getLogger(SnSManager.class);
    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
            .setNameFormat(SnSManager.class.getSimpleName() + "-%d").setDaemon(true).build();

    private static final String SNS_PARAM_FROM_INIT = "fromInit";
    private static final String SNS_PARAM_FROM_LATEST = "fromLatest";
    private static final long DFT_FROM_INIT = 1000;
    private static final long DFT_FROM_LATEST = 1000;

    private final long _fromInitMillis;
    private final long _fromLatestMillis;

    public enum SnSOpType {SNAP, SUBSCRIBE, SNAP_SUBSCRIBE}

    public final PubSubClient _client;
    private final Map<String, String> _params;
    private final HandlersManager _handlersManager;
    private final ScheduledExecutorService _scheduler;
    public ScheduledExecutorService getScheduler() {return _scheduler;}

    private final AtomicLong _subscriptionCounter = new AtomicLong(0);
    public long getNextSubsId() {
        return _subscriptionCounter.getAndIncrement();
    }

    private static final ThreadLocal<SnapRequestObj> _snapRequestObjThreadLocal = new ThreadLocal<>() {
        @Override
        public SnapRequestObj initialValue() {
            return new SnapRequestObj();
        }
        @Override
        public SnapRequestObj get() {
            SnapRequestObj snp = super.get();
            snp.reset();
            return snp;
        }
    };

    public SnSManager(PubSubClient client, Map<String, String> params) {
        _client = client;
        _params = params;

        _handlersManager = new HandlersManager(client);

        _fromInitMillis = Utils.getAsLong(params, SNS_PARAM_FROM_INIT, DFT_FROM_INIT);
        _fromLatestMillis = Utils.getAsLong(params, SNS_PARAM_FROM_LATEST, DFT_FROM_LATEST);
        _scheduler = Executors.newSingleThreadScheduledExecutor(_threadFactory);
    }

    public void stop() {
        _scheduler.shutdownNow();
    }


    public long snapSubscribe(String sql, ISubscriptionListener subListener) throws Exception {
        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        long subId = _subscriptionCounter.getAndIncrement();
        return snapSubscribe(sqlComps, subListener, null, subId, _params);
    }

    public long snapSubscribe(String sql, ISubscriptionListener subListener, IMergeManager mergeManager) throws Exception {
        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        long subId = _subscriptionCounter.getAndIncrement();
        return snapSubscribe(sqlComps, subListener, mergeManager, subId, _params);
    }

    public long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = _subscriptionCounter.getAndIncrement();
        return snapSubscribe(sqlComps, subListener, null, subId, _params);
    }

    private long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener, IMergeManager mergeManager, long subId, Map<String, String> params) throws Exception {

        if (log.isDebugEnabled()) log.info("snapSubscribe {} {}", subId, sqlComps.getSql());

        String sql = sqlComps.getSql();
        String subject = sqlComps.getFromTable();
        _client.activateSubject(subject);

        SnSHandler handler = new SnSHandler(_client, this, sqlComps, subId, SnSOpType.SNAP_SUBSCRIBE, subListener);
        register(handler);

        handler.initiateSnap(_fromInitMillis, _fromLatestMillis, mergeManager);

        SnapRequestObj snp = _snapRequestObjThreadLocal.get();
        snp.set(subject, sql, subId);
        _client.request(snp);

        return subId;
    }


    public long snap(String sql, ISubscriptionListener subListener) throws Exception {
        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        long subId = _subscriptionCounter.getAndIncrement();
        return snap(sqlComps, subListener, subId, _params);
    }

    public long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = _subscriptionCounter.getAndIncrement();
        return snap(sqlComps, subListener, subId, _params);
    }

    private long snap(SqlParserResult sqlComps, ISubscriptionListener subListener, long subId, Map<String, String> params) throws Exception {

        if (log.isDebugEnabled()) log.info("snap {} {}", subId, sqlComps.getSql());

        String sql = sqlComps.getSql();
        String subject = sqlComps.getFromTable();
        _client.activateSubject(subject);

        SnSHandler handler = new SnSHandler(_client, this, sqlComps, subId, SnSOpType.SNAP, subListener);
        register(handler);

        handler.initiateSnap(_fromInitMillis, _fromLatestMillis, null);

        SnapRequestObj snp = _snapRequestObjThreadLocal.get();
        snp.set(subject, sql, subId);
        _client.request(snp);

        return subId;
    }

    public long subscribe(String sql, ISubscriptionListener subListener) throws Exception {
        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        long subId = _subscriptionCounter.getAndIncrement();
        return subscribe(sqlComps, subListener, subId, _params);
    }

    public long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = _subscriptionCounter.getAndIncrement();
        return subscribe(sqlComps, subListener, subId, _params);
    }

    private long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener, long subId, Map<String, String> params) {

        if (log.isDebugEnabled()) log.info("subscribe {} {}", subId, sqlComps.getSql());

        _client.activateSubject(sqlComps.getFromTable());

        SnSHandler handler = new SnSHandler(_client, this, sqlComps, subId, SnSOpType.SUBSCRIBE, subListener);
        register(handler);

        return subId;
    }


    private void register(SnSHandler handler) {
        _handlersManager.register(handler);
    }

    public void unsubscribe(long subId) {
        _handlersManager.unregister(subId);
    }
    public void passMsgToAllSubjectSubscribers(String subject, Consumer<List<SnSHandler>> consumer) {
        _handlersManager.passMsgToAllSubjectSubscribers(subject, consumer);
    }

}
