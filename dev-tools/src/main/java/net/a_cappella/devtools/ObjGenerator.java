package net.a_cappella.devtools;

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

public class ObjGenerator {
    private static final Logger log = LoggerFactory.getLogger(ObjGenerator.class);

    private volatile boolean _allStop = false;

    private SubscriptionThread _subscriptionThread;
    private Set<Long> _activeSubscriptions = new HashSet<>();

    private final PrestoClient _client;
    private final int _snapCnt;
    private final int _subsCnt;
    private final AtomicInteger _nextId = new AtomicInteger();

    public ObjGenerator(PrestoClient client, int snapCnt, int subsCnt) {
        _client = client;
        _snapCnt = snapCnt;
        _subsCnt = subsCnt;
    }

    public void stop() {
        _allStop = true;
    }

    public void stop(long subId) {
        _activeSubscriptions.remove(subId);
        if (_activeSubscriptions.isEmpty()) {
            _subscriptionThread._stop = true;
            _subscriptionThread = null;
            TestViewport.setVerifyConsecutiveValues(true);
        }
    }

    public void onSnapRequest(SnapRequestObj snp) throws Exception {
        if (_subscriptionThread != null) {
            TestViewport.setVerifyConsecutiveValues(false);
        }
        new SnapThread(snp).start();
    }

    public void onSubscriptionRequest(SqlParserResult sqlComps, long subId) {
        if (_subscriptionThread == null) {
            TestViewport.setVerifyConsecutiveValues(true);
            _subscriptionThread = new SubscriptionThread(sqlComps);
            _subscriptionThread.start();
        }
        _activeSubscriptions.add(subId);
    }






    private Obj generateMsg() {
        int i = _nextId.getAndIncrement();
        PingObj obj = new PingObj();
        obj.setId(i % 10);
        obj.setPayload(1000 + i);

        obj.setAdHoc("ID", i % 10);
        obj.setAdHoc("Price", i * 3.1415926);
        obj.setAdHoc("Active", i % 2 == 0 ? true : false);
        obj.setAdHoc("Timestamp", System.currentTimeMillis());
        obj.setAdHoc("Name", "Name " + i);
        return obj;
    }




    private class SnapThread extends Thread {
        private final SnapRequestObj _snp;
        private final String _sql;
        private final SqlParserResult _sqlComps;
        private final String _subj;
        private final WhereNode _evalTree;

        public SnapThread(SnapRequestObj snp) throws Exception {
            _snp = snp;
            _sql = _snp.getSql();

            _sqlComps = SqlParser.parseSql(_sql);
            _subj = _sqlComps.getFromTable();
            _evalTree = _sqlComps.getEvalTree();
        }

        public void run() {
            if (!"ping".equals(_subj)) return;

            try {
                _snp.setSql(null); // reusing object to send begin and end SNP messages

                _client.reply(_snp, PubType.SNP_BEGIN);
                if (_evalTree != null) { // SNAP records need to satisfy the where clause as the SnS mechanism does not do it
                    _evalTree.updateEvalSupportingFields(_subj, ObjectManager.getInstance().getSubjectMetaInfo(_subj));
                    for (int i = 0; i < _snapCnt; i++) {
                        Obj reply = generateMsg();
                        if (_evalTree.satisfiesWhereClause(reply)) {
                            publishReply(reply, _snp, PubType.SNP_MSG);
                        }
                    }
                } else {
                    for (int i = 0; i < _snapCnt; i++) {
                        Obj reply = generateMsg();
                        publishReply(reply, _snp, PubType.SNP_MSG);
                    }
                }
                _client.reply(_snp, PubType.SNP_END);
            } catch (Exception e) {
                log.error("", e);
            }
        }
    }

    private class SubscriptionThread extends Thread {
        private volatile boolean _stop = false;
        private final SqlParserResult _sqlComps;
        private final String _subj;

        public SubscriptionThread(SqlParserResult sqlComps) {
            _sqlComps = sqlComps;
            _subj = _sqlComps.getFromTable();
        }

        public void run() {
            if (!"ping".equals(_subj)) return;

            for (int i = _snapCnt; i < _subsCnt; i++) {
                try { Thread.sleep(1_000); } catch (InterruptedException e) {}
                if (_stop || _allStop) return;

                Obj reply = generateMsg();
                publishReply(reply, null, PubType.PUB);
            }
        }
    }









    private void publishReply(Obj reply, SnapRequestObj snp, PubType pubType) {
        if (snp != null) reply.copyRoutingFields(snp);
        try {
            _client.reply(reply, pubType);
            if (log.isDebugEnabled()) log.info("publishReply {} {}", pubType, reply);
        } catch (Exception x) {
            throw new RuntimeException(x);
        }
    }

}
