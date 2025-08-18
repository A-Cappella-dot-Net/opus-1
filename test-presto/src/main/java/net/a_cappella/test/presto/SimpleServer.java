package net.a_cappella.test.presto;

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

	public void sendMsg(SelectionKey key, Msg msg) {
		super.sendMsg(key, msg);
		log.info(_cmId+"serverSink sent "+msg+" to "+keyHash(key));
	}
}
