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

import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Pong {
    private static final Logger log = LoggerFactory.getLogger(Pong.class);

    private final String _pongTestSql = "select * from test where mine=0";
    private final String _pongPingSql = "select * from ping where mine=0";

    private PrestoClient _client;

    public Pong(PrestoClient client) {
    	_client = client;
    }

    private final ISubscriptionListener _listener =
    		(obj, subsId) -> {
        		obj.startUsing();
        		try {
        			if (obj.getTsNanos() == Long.MIN_VALUE) {
        		        System.gc();
        			} else {
            			obj.setMine((short) 1);
                        _client.publish(obj);
        			}
        		} catch (Exception x) {
        			log.error("", x);
	    		} finally {
	        		obj.stopUsing();
        		}
        	};    		

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_client.subscribe(_pongTestSql, _listener);
    	_client.subscribe(_pongPingSql, _listener);
    }
}
