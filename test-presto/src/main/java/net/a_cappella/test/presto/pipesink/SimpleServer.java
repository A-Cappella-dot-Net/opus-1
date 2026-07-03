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

package net.a_cappella.test.presto.pipesink;

import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.msg.RegistrationRequest;
import net.a_cappella.continuo.socket.BaseServerSink;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.channels.SelectionKey;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class SimpleServer extends BaseServerSink {
	private static final Logger log = LoggerFactory.getLogger(SimpleServer.class);

	public SimpleServer(MsgCoder coder, ConnInfo connInfo) {
		super(coder, connInfo.getPort(), connInfo.getPort()+"");
	}

	@Override
	public void onClientConnect(SelectionKey key, RegistrationRequest reg) {
		log.info(_cmId+"serverSink.onClientConnect back to "+reg);
	}

	@Override
	public void onClientDisconnect(SelectionKey key) {
		log.info(_cmId+"serverSink.onClientDisconnect "+keyHash(key));
	}

	public void onMsg(SelectionKey key, Msg msg) {
		log.info(_cmId+"serverSink received "+msg+" from "+keyHash(key));
		for (int i=0; i<300; i++) {
			if (isConnected(key)) sendMsg(key, msg);
		}
	}

	public boolean sendMsg(SelectionKey key, Msg msg) {
		boolean sent = super.sendMsg(key, msg);
		if (sent) log.info(_cmId+"serverSink sent "+msg+" to "+keyHash(key));
		return sent;
	}
}
