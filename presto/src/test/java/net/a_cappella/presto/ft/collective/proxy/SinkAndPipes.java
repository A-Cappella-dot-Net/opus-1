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

package net.a_cappella.presto.ft.collective.proxy;

import com.google.common.collect.BiMap;
import com.google.common.collect.HashBiMap;
import net.a_cappella.presto.ft.collective.proxy.events.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.channels.SelectionKey;
import java.util.Queue;

public class SinkAndPipes {
    private static final Logger log = LoggerFactory.getLogger(SinkAndPipes.class);

    private final Queue<ProxyEvent> _eventQueue;
    private final int _fromPort;
    private final int _toPort;
    private final int _pipeCnt;

    private ProxySink _sink;
    private ProxyPipe[] _pipes;
    private boolean _stopped = false; // TODO check if this is necessary

    private BiMap<SelectionKey, ProxyPipe> _keyToPipeMap = HashBiMap.create();

    public SinkAndPipes(Queue<ProxyEvent> eventQueue, int fromPort, int toPort, int pipeCnt) {
        _eventQueue = eventQueue;
        _fromPort = fromPort;
        _toPort = toPort;
        _pipeCnt = pipeCnt;
        _pipes = new ProxyPipe[pipeCnt];
    }

    public void start() {
        for (int i = 0; i < _pipeCnt; i++) {
            ProxyPipe pipe = new ProxyPipe(this, _toPort, _fromPort + " ");
            pipe.startPipe();
            _pipes[i] = pipe;
        }
    }

    public void stop() {
        _stopped = true;
        if (_sink != null) {
            _sink.stopSink();
            _sink = null;
        }
        for (int i = 0; i < _pipeCnt; i++) {
            ProxyPipe pipe = _pipes[i];
            if (pipe != null) {
                pipe.stopPipe();
                _pipes[i] = null;
            }
        }
    }


    public void onSrcConnect(SelectionKey key) {
        _eventQueue.add(new SrcConnectEvent(this, key));
    }
    public void handleSrcConnectEvent(SelectionKey key) {
        if (_stopped) return;
        for (int i = 0; i < _pipeCnt; i++) {
            ProxyPipe pipe = _pipes[i];
            if (!_keyToPipeMap.inverse().containsKey(pipe)) {
                _keyToPipeMap.put(key, pipe);
                return;
            }
        }
        throw new RuntimeException("More connections than reserved pipes?");
    }

    public void onSrcDisconnect(SelectionKey key) {
        _eventQueue.add(new SrcDisconnectEvent(this, key));
    }
    public void handleSrcDisconnectEvent(SelectionKey key) {
        if (_stopped) return;
        ProxyPipe oldPipe = _keyToPipeMap.remove(key); // remove stale key before stopping
        if (oldPipe == null) return;
        oldPipe.stopPipe();
        ProxyPipe newPipe = new ProxyPipe(this, _toPort, _fromPort + " ");
        newPipe.startPipe();
        for (int i = 0; i < _pipeCnt; i++) { // keep _pipes[] in sync
            if (_pipes[i] == oldPipe) {
                _pipes[i] = newPipe;
                return;
            }
        }
        log.error("SinkAndPipes handleSrcDisconnectEvent: oldPipe not found in _pipes[]");
    }

    public void onMsgFromSrc(SelectionKey key, byte[] bytes) {
        _eventQueue.add(new MsgFromSrcEvent(this, key, bytes));
    }
    public void handleMsgFromSrcEvent(SelectionKey key, byte[] bytes) {
        if (_stopped) return;
        ProxyPipe pipe = _keyToPipeMap.get(key);
        if (pipe != null) {
            try {
                pipe.sendMsg(bytes);
            } catch (IOException e) {
                log.info("SinkAndPipes {}", e.getMessage());
            }
        }
    }


    public void onDstConnect() {
        _eventQueue.add(new DstConnectEvent(this));
    }
    public void handleDstConnectEvent() {
        if (_stopped) return;
        if (_sink == null) { // first pipe to connect: start the shared sink
            _sink = new ProxySink(this, _fromPort, _fromPort + " ");
            _sink.startSink();
        }
    }

    public void onDstDisconnect() {
        _eventQueue.add(new DstDisconnectEvent(this));
    }
    public void handleDstDisconnectEvent() {
        if (_stopped) return;
        _keyToPipeMap.clear(); // all source connections are gone; clear stale key→pipe entries
        if (_sink != null) {
            _sink.stopSink();
            _sink = null;
        }
    }

    public void onMsgFromDst(ProxyPipe pipe, byte[] bytes) {
        _eventQueue.add(new MsgFromDstEvent(this, pipe, bytes));
    }
    public void handleMsgFromDstEvent(ProxyPipe pipe, byte[] bytes) {
        if (_sink != null) {
            SelectionKey key = _keyToPipeMap.inverse().get(pipe);
            if (key != null) {
                _sink.sendMsg(key, bytes);
            }
        }
    }

}
