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

package net.a_cappella.test.aeron.presto;

import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.test.aeron.presto.DropPing.USE_MINE;

public class DropPong {
    private static final Logger log = LoggerFactory.getLogger(DropPong.class);

    private final String _pongSql = "select * from ping where " + ((USE_MINE) ? "mine" : "id") + " in (1, 3, 5, 7)";

    private final PrestoClient _client;

    public DropPong(PrestoClient client) {
    	_client = client;
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_client.subscribe(_pongSql, (obj, subsId) -> {
    		obj.startUsing();
    		try {
                PingObj pingObj = (PingObj) obj;
                short mine = pingObj.getMine();
                mine++;
                pingObj.setMine(mine);
                pingObj.setId(mine);
                _client.publish(pingObj);
    		} catch (Exception x) {
    			log.error("", x);
    		}
    		obj.stopUsing();
    	});
    	log.info("subscribing to " + _pongSql);
    }
}
