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

import java.util.HashMap;
import java.util.Map;

public class ObjGenerator {
    private static final Logger log = LoggerFactory.getLogger(ObjGenerator.class);

    private volatile boolean _allStop = false;

    private Map<Long, SubscriptionThread> _threadsBySubId = new HashMap<>();

    private final PrestoClient _client;
    private final int _snapCnt;
    private final int _subsCnt;

    public ObjGenerator(PrestoClient client, int snapCnt, int subsCnt) {
        _client = client;
        _snapCnt = snapCnt;
        _subsCnt = subsCnt;
    }

    public void stop() {
        _allStop = true;
    }

    public void stop(long subId) {
        SubscriptionThread thread = _threadsBySubId.get(subId);
        if (thread != null) thread._stop = true;
    }

    private Obj generateMsg(int i) {
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

    public void onSnapRequest(SnapRequestObj snp) throws Exception {
        new SnapThread(snp).start();
    }

    public void onSubscriptionRequest(SqlParserResult sqlComps, long subId) {
        SubscriptionThread thread = new SubscriptionThread(sqlComps, subId);
        _threadsBySubId.put(subId, thread);
        thread.start();
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
                log.info("handleSnapRequest {} {}", _snp.getRtg().getOriginClient(), _snp.getSql());
                _snp.setSql(null); // reusing object to send begin and end SNP messages

                _client.reply(_snp, PubType.SNP_BEGIN);
                if (_evalTree != null) {
                    _evalTree.updateEvalSupportingFields(_subj, ObjectManager.getInstance().getSubjectMetaInfo(_subj));
                    for (int i = 0; i < _snapCnt; i++) {
                        Obj reply = generateMsg(i);
                        if (_evalTree.satisfiesWhereClause(reply)) {
                            publishReply(reply, _snp, PubType.SNP_MSG);
                        }
                    }
                } else {
                    for (int i = 0; i < _snapCnt; i++) {
                        Obj reply = generateMsg(i);
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
        private final long _subId;
        private final String _subj;
        private final WhereNode _evalTree;

        public SubscriptionThread(SqlParserResult sqlComps, long subId) {
            _sqlComps = sqlComps;
            _subj = _sqlComps.getFromTable();
            _evalTree = _sqlComps.getEvalTree();
            _subId = subId;
        }

        public void run() {
            if (!"ping".equals(_subj)) return;

            if (_evalTree != null) {
                _evalTree.updateEvalSupportingFields(_subj, ObjectManager.getInstance().getSubjectMetaInfo(_subj));
                for (int i = _snapCnt; i < _subsCnt; i++) {
                    try {
                        Thread.sleep(1_000);
                    } catch (InterruptedException e) {}
                    if (_stop || _allStop) return;

                    Obj reply = generateMsg(i);
                    if (_evalTree.satisfiesWhereClause(reply)) {
                        publishReply(reply, null, PubType.PUB);
                    }
                }
            } else {
                for (int i = _snapCnt; i < _subsCnt; i++) {
                    try {
                        Thread.sleep(1_000);
                    } catch (InterruptedException e) {}
                    if (_stop || _allStop) return;

                    Obj reply = generateMsg(i);
                    publishReply(reply, null, PubType.PUB);
                }
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
