/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.madrigal.mcache;

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.madrigal.common.interfaces.IDateRollListener;
import net.a_cappella.madrigal.common.obj.FinalizeOrderObj;
import net.a_cappella.madrigal.common.utils.TradeDateUtils;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.util.List;

public class OrderStateManagedSubject extends ManagedSubject implements IDateRollListener {
    private static final Logger log = LoggerFactory.getLogger(OrderStateManagedSubject.class);

    private final String _finalizeOrderSql;
    private final TradeDateUtils _tradeDate;
    private final OrderObjCache _orderObjCache = new OrderObjCache(); // local variable to avoid casting

    public OrderStateManagedSubject(String orderSql, String finalizeOrderSql, TradeDateUtils tradeDate) throws Exception {
    	super(orderSql);

    	_finalizeOrderSql = finalizeOrderSql;
        _tradeDate = tradeDate;
        _objCache = _orderObjCache;
    }


    @Override // ManagedSubject
    public void initializeAndMaintainSubjectCache() throws Exception {
        _tradeDate.addListener(this);
        // snap from ft cache first and then subscribe
        _client.snapSubscribe(_sql, this);
        _client.subscribe(_finalizeOrderSql, (obj, subsId) -> {
            _orderObjCache.onFinalizeOrder((FinalizeOrderObj) obj);
        });
    }

	@Override // ManagedSubject
    protected void handleSnapRequest(SnapRequestObj snp) throws Exception {
        log.info("handleSnapRequest {} {}", snp.getRtg().getOriginClient(), snp.getSql());
        String sql = snp.getSql();
    	snp.setSql(null); // reusing object to send begin and end RPL messages

        SqlParserResult sqlComps = SqlParser.parseSql(sql);
        String subj = sqlComps.getFromTable(); // 'order'
        WhereNode evalTree = sqlComps.getEvalTree();

        _client.reply(snp, PubType.SNP_BEGIN);
        long seqNo = _client.getSeqNo();
        if (evalTree != null) { // "where ecn in ('%s', lh-'%s')" - it's a line handler snapping me
        	evalTree.updateEvalSupportingFields(subj, ObjectManager.getInstance().getSubjectMetaInfo(subj));
        	List<Object> ecnFilter = evalTree.getFilter("ecn");
        	if (!ecnFilter.isEmpty()) {
            	String ecn = (String) ecnFilter.get(0);
                _orderObjCache.publishSnapRecords(ecn, reply -> {
                    if (evalTree.satisfiesWhereClause(reply)) {
                    	publishReply(reply, snp, PubType.SNP_MSG);
                    }
                });
                _orderObjCache.publishHighWaterMark(ecn, hwm -> {
                	hwm.setSeqNo(seqNo);
                	publishReply(hwm, snp, PubType.SNP_HWM);
                });
        	} else {
        		log.warn("handleSnapRequest - where clause without ecn filter is not supported: {}", sql);
        	}
        } else { // no where clause, i.e., it's other caches snapping me
        	_orderObjCache.publishSnapRecords(reply -> publishReply(reply, snp, PubType.SNP_MSG));
        	_orderObjCache.publishHighWaterMark(hwm -> {
            	hwm.setSeqNo(seqNo);
        		publishReply(hwm, snp, PubType.SNP_HWM);
        	});
        }
    	_client.reply(snp, PubType.SNP_END);

    }

	@Override // ISubscriptionListener
	public void onSubscriptionMessage(Obj obj, long subsId) {
		_orderObjCache.onSubscriptionMessage(obj, subsId);
	}

	@Override // ISubscriptionListener
	public void onHighWaterMark(Obj obj) {
		_orderObjCache.initHighWaterMark(obj);
	}

	@Override // ISnapCompleteListener
	public void onSnapComplete(long subId) {
		super.onSnapComplete(subId);
		_orderObjCache.setSnapComplete(true);
	}

	@Override // IDateRollListener
    public void onDateRoll(Instant tradeDate) {
    	_cache.loopbackCacheCmdMessage(ManagedCache.CMD_CLEAN, _subj, null);
    }
}
