package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.ExchangeServer.ServerSink;
import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.fix.FixMessage;
import gnu.trove.procedure.TObjectIntProcedure;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class SendImbalance implements TObjectIntProcedure<SelectionKey> {
    private static final Logger log = LoggerFactory.getLogger(SendImbalance.class);

    private final ServerSink _sink;
    private FixMessage _fixMessage;
    private Imbalance _imbalance;

    public SendImbalance(ServerSink sink) {
        _sink = sink;
    }

    public void setParams(FixMessage fixMessage, Imbalance imbalance) {
        _fixMessage = fixMessage;
        _imbalance = imbalance;
    }
    public boolean execute(SelectionKey key, int maxDepth) {
        _fixMessage.imbalance(_imbalance);
        try {
            _sink.sendMsg(key, _fixMessage);
        } catch (Exception x) {
            log.error("Could not send imbalance to " + keyHash(key), x);
        }
        _fixMessage.reset();
        return true;
    }
}
