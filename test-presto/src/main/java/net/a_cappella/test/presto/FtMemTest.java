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

package net.a_cappella.test.presto;

import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.ft.collective.IFtMemberListener;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FtMemTest implements IFtMemberListener {
    private static final Logger log = LoggerFactory.getLogger(FtMemTest.class);

    private static final int NUM_ITERATIONS = 3;
    private static final int CYCLE_INTERVAL = 1000;
    private static final int OP_INTERVAL = 10;
    private static final int PAUSE_INTERVAL = 1000;
    private static final boolean FORCE_DISCONNECT = false;
    private static final int RECONNECT_INTERVAL = 1000;

    private final CollectiveClient _client;

    public FtMemTest(CollectiveClient client) {
    	_client = client;
    }

    public void start() {
    	try {
            _client.registerFtMemberListener(this);
			Thread.sleep(2000);

			for (int i=0; i<NUM_ITERATIONS; i++) {

				int goal = (i % 3) + 1;

				_client.registerFtMember("foo", 3, goal);
				if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);
				_client.registerFtMember("foo", 2, goal);
				if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);
				_client.registerFtMember("foo", 1, goal);
				if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);


				if (PAUSE_INTERVAL>0) Thread.sleep(PAUSE_INTERVAL);
				if (FORCE_DISCONNECT) {
					_client.stop();
					Thread.sleep(RECONNECT_INTERVAL);
					_client.start();
				} else {
					_client.unregisterFtMember("foo", 1);
					if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);
					_client.unregisterFtMember("foo", 2);
					if (OP_INTERVAL>0) Thread.sleep(OP_INTERVAL);
					_client.unregisterFtMember("foo", 3);
				}

				Thread.sleep(CYCLE_INTERVAL);
			}

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

	@Override // IFtMemberListener
	public void onFtAction(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices) {
		log.info("onFtAction("+groupName+"~"+instance+" '"+op+"' "+sliceNo+"/"+ofSlices+")");
	}
}
