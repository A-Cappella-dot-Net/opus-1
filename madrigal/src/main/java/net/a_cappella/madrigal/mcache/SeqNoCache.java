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

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.CacheCmdObj;
import net.a_cappella.presto.obj.SeqNoObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.function.Consumer;

public class SeqNoCache implements IObjCache {
    private static final Logger log = LoggerFactory.getLogger(SeqNoCache.class);

    private final PrestoClient _client;
    private final SeqNoObj _seqNoObj = new SeqNoObj();

    public SeqNoCache(PrestoClient client) {
    	_client = client;
    }

	@Override
	public void onSubscriptionMessage(Obj obj, long subsId) {
		// this is the object received on the snap from the primary cache
		SeqNoObj seqNoObj = (SeqNoObj) obj;
		long seqNo = seqNoObj.getSeqNo();
		log.info("onSubscriptionMessage received seqNo={}", seqNo);
		if (seqNo > _client.getSeqNo()) {
			_client.setSeqNo(seqNo);
		}
	}

	@Override
	public void publishSnapRecords(Consumer<Obj> consumer) {
		long seqNo = _client.getSeqNo(); // get seqNo from client
		_seqNoObj.set(seqNo);
		consumer.accept(_seqNoObj); // publish it back to requester
		log.info("publishSnapRecords sent seqNo={}", seqNo);
	}

	@Override
	public void onCacheCmdMessage(CacheCmdObj obj) {
    	String command = obj.getCommand();
    	switch (command) {
    	case ManagedCache.CMD_CLEAN:
    		_seqNoObj.set(0L);
			_client.setSeqNo(0L);
    		break;
    	case ManagedCache.CMD_LOG:
    		log();
    		break;
    	default:
    		log.warn("Unrecognized command {}", command);
    	}
	}

	@Override
	public void log() {
		log.info("---------------------------------  {}", _client.getSeqNo());
	}
}
