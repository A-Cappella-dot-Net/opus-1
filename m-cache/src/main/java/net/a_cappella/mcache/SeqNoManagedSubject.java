package net.a_cappella.mcache;

import net.a_cappella.madrigal.common.interfaces.IDateRollListener;
import net.a_cappella.madrigal.common.utils.TradeDateUtils;

import java.time.Instant;

public class SeqNoManagedSubject extends ManagedSubject implements IDateRollListener {
    private final TradeDateUtils _tradeDate;

    public SeqNoManagedSubject(String sql, TradeDateUtils tradeDate) throws Exception {
    	super(sql);
        _tradeDate = tradeDate;
    }

    @Override // ManagedSubject
    public void initializeAndMaintainSubjectCache() throws Exception {
        _objCache = new SeqNoCache(_client);
    	// seq.no is not published regularly but is updated in the header of serialized messages by the serializer
    	// we still need to snapSubscribe (as opposed to snap) otherwise we will not be able to handle snap requests
        _client.snapSubscribe(_sql, this);
        _tradeDate.addListener(this);
    }

    @Override // IDateRollListener
    public void onDateRoll(Instant tradeDate) {
    	_cache.loopbackCacheCmdMessage(ManagedCache.CMD_CLEAN, _subj, null);
    }
}
