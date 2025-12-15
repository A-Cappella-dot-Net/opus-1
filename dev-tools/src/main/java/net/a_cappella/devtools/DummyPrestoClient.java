package net.a_cappella.devtools;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.presto.ft.collective.IFtMemberListener;
import net.a_cappella.presto.ft.collective.IFtMonitorListener;
import net.a_cappella.presto.obj.*;
import net.a_cappella.presto.ps.ISnSListener;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

public class DummyPrestoClient implements PrestoClient {
    private static final Logger log = LoggerFactory.getLogger(DummyPrestoClient.class);

    static {
        ObjImpl.setRtgCtor("net.a_cappella.presto.msg.RtgImpl");
        try {
            ObjectManager objectManager = ObjectManager.getInstance();
            objectManager.setMsgInstantiators(
                    Arrays.asList(
                            new MsgInstantiator(MapObj.class.getName(), MapCoder.class.getName(), null),
                            new MsgInstantiator(TestObj.class.getName(), TestCoder.class.getName(), null),
                            new MsgInstantiator(PingObj.class.getName(), PingCoder.class.getName(), null)
                    )
            );
        } catch (Exception e) {
            log.error("", e);
        }
    }

    private long _subId = 0;
    private Map<Long, ObjGenerator> _generatorsBySubId = new HashMap<>();


    @Override
    public void waitUntilInitialized() {

    }

    @Override
    public void stop() {

    }

    @Override
    public AppInfo getAppInfo() {
        return null;
    }

    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener) throws Exception {
        return 0;
    }

    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener, IMergeManager mergeManager) throws Exception {
        return 0;
    }

    private static class ObjGenerator {
        private volatile boolean _stop = false;
        private Thread _thread;
        private final ISubscriptionListener _subListener;
        private final WhereNode _whereClause;
        private final String _subject;

        public ObjGenerator(long subId, ISubscriptionListener subListener, SqlParserResult sqlComps, int snapCnt, int subsCnt) {
            _subListener = subListener;
            _subject = sqlComps.getFromTable();
            _whereClause = sqlComps.getEvalTree();
            if ("ping".equals(sqlComps.getFromTable())) { // test data
                _thread = new Thread(() -> {
                    for (int i = 0; i < snapCnt; i++) {
                        Obj obj = generateMsg(i);
                        subListener.onSubscriptionMessage(obj, subId);
                        if (_stop) return;
                    }
                    if (subListener instanceof ISnSListener) {
                        ((ISnSListener) subListener).onSnapComplete(subId);
                    }

                    for (int i = snapCnt; i < subsCnt; i++) {
                        Obj obj = generateMsg(i);
                        subListener.onSubscriptionMessage(obj, subId);
                        try {
                            Thread.sleep(1_000);
                        } catch (InterruptedException e) {
                        }
                        if (_stop) return;
                    }
                });
            }
        }
        public String getSubject() {
            return _subject;
        }
        public void start() {
            if (_thread != null) _thread.start();
        }
        public void stop() {
            _stop = true;
        }

        private Obj generateMsg(int i) {
            PingObj obj = new PingObj();
            obj.setId(i % 10);
            obj.setPayload(1000 + i);

//            new ColumnDef("ID", "integer", 60);
//            new ColumnDef("Name", "string", 100);
//            new ColumnDef("Status", "string", 100);
//            new ColumnDef("ExtraCol", "string", 150);
//
//            new ColumnDef("ID", "integer", 100);
//            new ColumnDef("Price", "decimal", 120, 3); // decimals:2
//            new ColumnDef("Timestamp", "datetime", 180, "time"); // format:short,ISO,locale,date,time
//            new ColumnDef("Active", "boolean", 80); // align:center,left,right
//            new ColumnDef("Name", "string", 200);
//
//            obj.setAdHoc("ID", i % 10);
//            obj.setAdHoc("Name", "Item " + i);
//            obj.setAdHoc("Status", i % 2 == 0 ? "Active" : "Inactive");
//            if (i % 10 == 3) {
//                obj.setAdHoc("ExtraCol", "Special value " + i);
//            }

            obj.setAdHoc("ID", i % 10);
            obj.setAdHoc("Price", i * 3.1415926);
            obj.setAdHoc("Active", i % 2 == 0 ? true : false);
            obj.setAdHoc("Timestamp", System.currentTimeMillis());
            obj.setAdHoc("Name", "Name " + i);
            return obj;
        }
    }

    @Override
    public long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = ++ _subId;
        ObjGenerator gen = new ObjGenerator(subId, subListener, sqlComps, 5, 10_000);
        _generatorsBySubId.put(subId, gen);
        gen.start();
        return subId;
    }

    @Override
    public long snap(String sql, ISubscriptionListener subListener) throws Exception {
        return 0;
    }

    @Override
    public long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = ++ _subId;
        ObjGenerator gen = new ObjGenerator(subId, subListener, sqlComps, 10, 0);
        _generatorsBySubId.put(subId, gen);
        gen.start();
        return subId;
    }

    @Override
    public long subscribe(String sql, ISubscriptionListener subListener) throws Exception {
        return 0;
    }

    @Override
    public long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = ++ _subId;
        ObjGenerator gen = new ObjGenerator(subId, subListener, sqlComps, 0, 10_000);
        _generatorsBySubId.put(subId, gen);
        gen.start();
        return subId;
    }

    @Override
    public void unsubscribe(long subId) {
        ObjGenerator gen = _generatorsBySubId.remove(subId);
        if (gen != null) gen.stop();
    }

    @Override
    public int publish(Obj obj) throws Exception {
        log.info("@@@@@@@@@@ publishing {}", obj);
        String subject = obj.getSubject();
        _generatorsBySubId.forEach((subId, gen) -> {
            if (subject.equals(gen.getSubject())) {
                if (gen._whereClause == null || gen._whereClause.satisfiesWhereClause(obj)) {
                    gen._subListener.onSubscriptionMessage(obj, subId);
                }
            }
        });
        return 0;
    }

    @Override
    public int serialize(Obj obj) throws Exception {
        return 0;
    }

    @Override
    public int request(SnapRequestObj obj) throws Exception {
        return 0;
    }

    @Override
    public int reply(Obj obj, PubType pubType) throws Exception {
        return 0;
    }

    @Override
    public void loopback(Obj obj) throws Exception {

    }

    @Override
    public long getSeqNo() {
        return 0;
    }

    @Override
    public void setSeqNo(long seqNo) {

    }

    @Override
    public void addSnippet(TightLoopSnippet snippet) {

    }

    @Override
    public boolean onTLT() {
        return false;
    }

    @Override
    public void registerFtMemberListener(IFtMemberListener listener) {

    }

    @Override
    public void unregisterFtMemberListener(IFtMemberListener listener) {

    }

    @Override
    public void registerFtMember(String groupName, int instance, int activeGoal) {

    }

    @Override
    public void unregisterFtMember(String groupName, int instance) {

    }

    @Override
    public void registerFtMonitorListener(IFtMonitorListener listener) {

    }

    @Override
    public void unregisterFtMonitorListener(IFtMonitorListener listener) {

    }

    @Override
    public void registerFtMonitor(String groupName) {

    }

    @Override
    public void unregisterFtMonitor(String groupName) {

    }
}
