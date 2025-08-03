package net.a_cappella.cembalo;

import static net.a_cappella.continuo.utils.Utils.keyHash;

import java.nio.channels.SelectionKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.ExchangeServer.ServerSink;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.fix.FixMessage;
import gnu.trove.procedure.TObjectIntProcedure;

public class SendInstrumentStatus implements TObjectIntProcedure<SelectionKey> {
    private static final Logger log = LoggerFactory.getLogger(SendInstrumentStatus.class);

    private final ServerSink _sink;
    private FixMessage _fixMessage;
    private InstrumentStatus _status;

    public SendInstrumentStatus(ServerSink sink) {
        _sink = sink;
    }

    public void setParams(FixMessage fixMessage, InstrumentStatus status) {
        _fixMessage = fixMessage;
        _status = status;
    }
    public boolean execute(SelectionKey key, int maxDepth) {
        _fixMessage.instrumentStatus(_status);
        try {
            _sink.sendMsg(key, _fixMessage);
        } catch (Exception x) {
            log.error("Could not send instrument status to " + keyHash(key), x);
        }
        _fixMessage.reset();
        return true;
    }
}
