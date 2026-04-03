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

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.msg.TestMsg;
import net.a_cappella.continuo.socket.BaseClientPipe;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

public class SimpleClient {
	private static final Logger log = LoggerFactory.getLogger(SimpleClient.class);

	private final ClientPipe _pipe;

	public SimpleClient(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, String cmId) {
		_pipe = new ClientPipe(coder, myInfo, sinkInfo, cmId);
	}
	
	public void start() {
		_pipe.startPipe();
	}

	public class ClientPipe extends BaseClientPipe {
		public ClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, String cmId) {
			super(coder, myInfo, sinkInfo, cmId, "SimpleClient");
		}

		@Override
		public void onRegistrationResponse() {
			super.onRegistrationResponse();
			TestMsg msg = new TestMsg();
			msg.setTimeNanos(System.currentTimeMillis());
			try {
				_pipe.sendMsg(msg);
			} catch (IOException e) {
				log.error(msg+"", e);
			}
			Utils.sleepNanosDelay(1_000_000);
			System.exit(0);
		}
		@Override
		public void onDisconnect() {
			super.onDisconnect();
		}
		@Override
		public void onMsg(Msg msg) {
			super.onMsg(msg);
			log.info("clientPipe received "+msg+" from server");
		}
		@Override
		public void sendMsg(Msg msg) throws IOException {
			super.sendMsg(msg);
		}
	}
}
