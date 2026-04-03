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

import net.a_cappella.presto.obj.TestObj;
import net.a_cappella.presto.ps.AeronClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BurstPong {
    private static final Logger log = LoggerFactory.getLogger(BurstPong.class);

    private final String _parsSql = "select * from test";
    private final String _pongSql = "select * from ping where mine=1";

    private final AeronClient _client;

    public BurstPong(PrestoClient client) {
    	_client = (AeronClient) client;
    }

    public void start() throws Exception {
    	_client.waitUntilInitialized();

    	_client.subscribe(_parsSql, (obj, subsId) -> {
    		obj.startUsing();
    		try {
    			TestObj testObj = (TestObj) obj;
    			int retriesOnBackPressure = testObj._anInt;
    			long sleepNanosOnBackPressureRetry = testObj._aLong;
                _client._pubHelper.setRetriesOnBackPressure(""+retriesOnBackPressure);
    			_client._pubHelper.setSleepNanosOnBackPressureRetry(""+sleepNanosOnBackPressureRetry);
    			log.info("==> retriesOnBackPressure="+retriesOnBackPressure+" sleepNanosOnBackPressureRetry="+sleepNanosOnBackPressureRetry);
    		} catch (Exception x) {
    			log.error("", x);
    		}
    		obj.stopUsing();
			System.gc();
    	});

    	_client.subscribe(_pongSql, (obj, subsId) -> {
    		obj.startUsing();
    		try {
                obj.setMine((short) 0);
                _client.publish(obj);
    		} catch (Exception x) {
    			log.error("", x);
    		}
    		obj.stopUsing();
    	});
    }
}
