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
