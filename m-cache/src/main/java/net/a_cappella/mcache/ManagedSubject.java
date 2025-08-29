package net.a_cappella.mcache;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.presto.obj.CacheCmdObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.ISnSListener;
import net.a_cappella.presto.ps.ISnapRequestListener;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class ManagedSubject implements ISnSListener, ISnapRequestListener {
    private static final Logger log = LoggerFactory.getLogger(ManagedSubject.class);

    private final String _cacheCmdSubSql = "select * from " + PrestoConstants.SUBJ_CACHE_CMD + " where cacheSubject ='%s'";

    protected PrestoClient _client;
    protected ManagedCache _cache;

    protected final String _sql;
    protected final String _subj;

    protected IObjCache _objCache;

    public ManagedSubject(String sql) throws Exception {
        _sql = sql;
        _subj = SqlParser.parseSql(sql).getFromTable();
    }

    public abstract void initializeAndMaintainSubjectCache() throws Exception;

    public String getSubj() {
    	return _subj;
    }

    public void init(PrestoClient client, ManagedCache cache) throws Exception {
        log.info("init {}", this);
        _client = client;
        _cache = cache;

        _client.subscribe(String.format(_cacheCmdSubSql, _subj), (obj, subsId) -> {
        	onCacheCmdMessage((CacheCmdObj) obj);
        });

        initializeAndMaintainSubjectCache(); // initialize cache and then subscribe
    }

	@Override // ISubscriptionListener
	public void onSubscriptionMessage(Obj obj, long subsId) {
        _objCache.onSubscriptionMessage(obj, subsId);
	}

	@Override // ISubscriptionListener
    public void onSnapRequest(SnapRequestObj obj, long subsId) {
    	try {
			if (_cache.isActive()) {
				handleSnapRequest(obj);
			}
    	} catch (Exception e) {
    		log.error("", e);
    	}
    }

	@Override // ISnapCompleteListener
	public void onSnapComplete(long subId) {
		log.info("===== onSnapComplete {}", subId);
	}

    protected void handleSnapRequest(SnapRequestObj snp) throws Exception {
        log.info("handleSnapRequest {} {}", snp.getRtg().getOriginClient(), snp.getSql());
        String sql = snp.getSql();
    	snp.setSql(null); // reusing object to send begin and end SNP messages

        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        String subj = sqlComps.getFromTable();
        WhereNode evalTree = sqlComps.getEvalTree();

        _client.reply(snp, PubType.SNP_BEGIN);
        if (evalTree != null) {
            evalTree.updateEvalSupportingFields(subj, ObjectManager.getInstance().getSubjectMetaInfo(subj));
            _objCache.publishSnapRecords(reply -> {
                if (evalTree.satisfiesWhereClause(reply)) {
                	publishReply(reply, snp, PubType.SNP_MSG);
                }
            });
        } else {
            _objCache.publishSnapRecords(reply -> {
            	publishReply(reply, snp, PubType.SNP_MSG);
            });
        }
    	_client.reply(snp, PubType.SNP_END);

    }

    protected void publishReply(Obj reply, SnapRequestObj snp, PubType pubType) {
    	reply.copyRoutingFields(snp);
    	try {
    		_client.reply(reply, pubType);
    		if (log.isDebugEnabled()) log.info("publishReply {} {}", pubType, reply);
    	} catch (Exception x) {
    		throw new RuntimeException(x);
    	}
    }

    private void onCacheCmdMessage(CacheCmdObj obj) {
        log.info("onCacheCmdMessage {}", obj);
    	_objCache.onCacheCmdMessage(obj);
    }

    public void log() {
        log.info("--------- "+this);
        _objCache.log();
    }

    public String toString() {
    	return "{" + _sql + "}";
    }

}
