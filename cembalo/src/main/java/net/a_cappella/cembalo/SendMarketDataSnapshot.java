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

package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.ExchangeServer.ServerSink;
import net.a_cappella.cembalo.fix.FixMessage;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import gnu.trove.procedure.TObjectIntProcedure;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class SendMarketDataSnapshot implements TObjectIntProcedure<SelectionKey> {
    private static final Logger log = LoggerFactory.getLogger(SendMarketDataSnapshot.class);

    private final ServerSink _sink;
    private FixMessage _fixMessage;
    private MarketDataSnapshot _mds;

    public SendMarketDataSnapshot(ServerSink sink) {
        _sink = sink;
    }

    public void setParams(FixMessage fixMessage, MarketDataSnapshot mds) {
        _fixMessage = fixMessage;
        _mds = mds;
    }
    public boolean execute(SelectionKey key, int maxDepth) {
        _fixMessage.marketDataSnapshot(_mds, maxDepth); // TODO group by maxDepth and save some processing
        try {
            _sink.sendMsg(key, _fixMessage);
        } catch (Exception x) {
            log.error("Could not send market data snapshot to " + keyHash(key), x);
        }
        _fixMessage.reset();
        return true;
    }
}
