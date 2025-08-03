package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;

import net.a_cappella.cembalo.ExchangeServer.ServerSink;
import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.fix.FixMessage;

public class ExchangeServerHelper {

    private final ServerSink _sink;

    private final SendInitialMessages _sendInitialMessages;
    private final SendMarketDataSnapshot _sendMarketDataSnapshot;
    private final SendInstrumentStatus _sendInstrumentStatus;
    private final SendImbalance _sendImbalance;

    public ExchangeServerHelper(ServerSink sink) {
        _sink = sink;

        _sendInitialMessages = new SendInitialMessages(_sink);
        _sendMarketDataSnapshot = new SendMarketDataSnapshot(_sink);
        _sendInstrumentStatus = new SendInstrumentStatus(_sink);
        _sendImbalance = new SendImbalance(_sink);
    }

    public SendInitialMessages getSendInitialMessages(SelectionKey key, int marketDepth) {
        _sendInitialMessages.setParams(key, marketDepth);
        return _sendInitialMessages;
    }


    public SendMarketDataSnapshot getSendMarketDataSnapshot(FixMessage fixMessage, MarketDataSnapshot mds) {
        _sendMarketDataSnapshot.setParams(fixMessage, mds);
        return _sendMarketDataSnapshot;
    }
    public SendInstrumentStatus getSendInstrumentStatus(FixMessage fixMessage, InstrumentStatus status) {
        _sendInstrumentStatus.setParams(fixMessage, status);
        return _sendInstrumentStatus;
    }
    public SendImbalance getSendImbalance(FixMessage fixMessage, Imbalance imbalance) {
        _sendImbalance.setParams(fixMessage, imbalance);
        return _sendImbalance;
    }
}
