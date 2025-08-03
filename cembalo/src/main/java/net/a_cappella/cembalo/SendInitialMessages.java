package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;
import java.util.function.BiConsumer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.ExchangeServer.ServerSink;
import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class SendInitialMessages implements BiConsumer<String, Matcher> {
    private static final Logger log = LoggerFactory.getLogger(SendInitialMessages.class);

    private final ServerSink _sink;
    private int _marketDepth;
    private SelectionKey _key;
    private final FixMessage _fixMessage = new FixMessage(new FixFields());

    public SendInitialMessages(ServerSink sink) {
        _sink = sink;
    }

    public void setParams(SelectionKey key, int marketDepth) {
        _key = key;
        _marketDepth = marketDepth;
    }

    @Override
    public void accept(String securityID, Matcher matcher) {
        try {
            MarketDataSnapshot mds = matcher._continuousOrderBook.getSnapshot();
            _fixMessage.marketDataSnapshot(mds, _marketDepth);
            _sink.sendMsg(_key, _fixMessage);
            _fixMessage.reset();

            InstrumentStatus status = matcher._continuousOrderBook.getStatus();
            _fixMessage.instrumentStatus(status);
            _sink.sendMsg(_key, _fixMessage);
            _fixMessage.reset();
            status = matcher._openAuctionOrderBook.getStatus();
            _fixMessage.instrumentStatus(status);
            _sink.sendMsg(_key, _fixMessage);
            _fixMessage.reset();
            status = matcher._closeAuctionOrderBook.getStatus();
            _fixMessage.instrumentStatus(status);
            _sink.sendMsg(_key, _fixMessage);
            _fixMessage.reset();

            Imbalance imbalance = matcher._openAuctionOrderBook.getImbalance();
            if (imbalance.isPublishable()) {
                _fixMessage.imbalance(imbalance);
                _sink.sendMsg(_key, _fixMessage);
                _fixMessage.reset();
            }
            imbalance = matcher._closeAuctionOrderBook.getImbalance();
            if (imbalance.isPublishable()) {
                _fixMessage.imbalance(imbalance);
                _sink.sendMsg(_key, _fixMessage);
                _fixMessage.reset();
            }
        } catch (Exception x) {
            log.error("Could not send fix message to " + keyHash(_key), x);
        } finally {
            _fixMessage.reset();
        }
    }
}
