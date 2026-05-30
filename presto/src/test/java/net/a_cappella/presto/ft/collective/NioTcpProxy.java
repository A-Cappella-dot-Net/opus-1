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

package net.a_cappella.presto.ft.collective;

import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;

public class NioTcpProxy {
    private static final Logger log = LoggerFactory.getLogger(NioTcpProxy.class);

    private final SinkThread[] _sinkThreads;

    private final String _targetHost = Utils._localhost;

    public NioTcpProxy(int[][] fromToList) {
        _sinkThreads = new SinkThread[fromToList.length];
        for (int i = 0; i < fromToList.length; i++) {
            _sinkThreads[i] = new SinkThread(fromToList[i][0], fromToList[i][1]);
        }
    }

    public void start() {
        for (int i = 0; i < _sinkThreads.length; i++) {
            _sinkThreads[i].start();
        }
    }

    public void stop() {
        for (int i = 0; i < _sinkThreads.length; i++) {
            _sinkThreads[i].signalStop();
        }
    }

    private class SinkThread extends Thread {
        private final String _cmId;

        private final int _localPort;
        private final int _targetPort;

        private final ByteBuffer _buffer = ByteBuffer.allocateDirect(1024);
        private Selector _selector = null;
        private volatile boolean _stop = false;

        public SinkThread(int localPort, int targetPort) {
            _cmId = localPort + " ";
            setName(_cmId+"SinkThread");

            _localPort = localPort;
            _targetPort = targetPort;
        }

        public void signalStop() {
            if (!_stop) {
                log.info("{}Stopping Sink", _cmId);
                _stop = true;
                if (_selector != null) _selector.wakeup();
            }
        }

        public void run() {
            try {
                log.info("{}Starting Sink", _cmId);
                _selector = Selector.open();

                // Setup the listening server socket
                ServerSocketChannel serverChannel = ServerSocketChannel.open();
                serverChannel.bind(new InetSocketAddress(_localPort));
                serverChannel.configureBlocking(false);
                serverChannel.register(_selector, SelectionKey.OP_ACCEPT);

                log.info("Proxy listening on port {} -> Forwarding to {}:{}", _localPort, _targetHost, _targetPort);

                while (!_stop) {
                    _selector.select(); // blocks until a message is received or the selector is woken up by 'signalStop'
                    if (!_selector.isOpen()) {
                        break;
                    }

                    Iterator<SelectionKey> keys = _selector.selectedKeys().iterator();
                    while (keys.hasNext()) {
                        SelectionKey key = keys.next();
                        keys.remove();

                        if (!key.isValid()) continue;

                        try {
                            if (key.isAcceptable()) {
                                handleAccept(serverChannel, _selector);
                            } else if (key.isConnectable()) {
                                handleConnect(key);
                            } else if (key.isReadable()) {
                                handleRead(key);
                            }
                        } catch (IOException e) {
                            log.error("Error handling key, closing connection: {}", e.getMessage());
                            closeConnection(key);
                        }
                    }
                }

                serverChannel.close();
                log.info("{}Sink stopped", _cmId);
            } catch (IOException x) {
                throw new RuntimeException(x);
            }
        }

        private void handleAccept(ServerSocketChannel serverChannel, Selector selector) throws IOException {
            SocketChannel clientChannel = serverChannel.accept();
            if (clientChannel == null) return;

            clientChannel.configureBlocking(false);
            log.info("Accepted new connection from: {}", clientChannel.getRemoteAddress());

            // Connect to the remote target server asynchronously
            SocketChannel targetChannel = SocketChannel.open();
            targetChannel.configureBlocking(false);
            targetChannel.connect(new InetSocketAddress(_targetHost, _targetPort));

            // Create the circular bridge attachments
            ConnectionState clientState = new ConnectionState(targetChannel);
            ConnectionState targetState = new ConnectionState(clientChannel);

            // Register client for reading immediately
            SelectionKey clientKey = clientChannel.register(selector, 0, clientState);
            // Register target for connect finish event
            SelectionKey targetKey = targetChannel.register(selector, SelectionKey.OP_CONNECT, targetState);

            // Link peer keys together so we can update interest sets dynamically if needed
            clientState._peerKey = targetKey;
            targetState._peerKey = clientKey;
        }

        private void handleConnect(SelectionKey key) throws IOException {
            SocketChannel targetChannel = (SocketChannel) key.channel();
            if (targetChannel.finishConnect()) {
                log.info("Connected to target: {}", targetChannel.getRemoteAddress());
                // Connection is established. Shift interest from OP_CONNECT to OP_READ
                key.interestOps(SelectionKey.OP_READ);
                // Also enable reading on the client side now that the target is ready
                ConnectionState state = (ConnectionState) key.attachment();
                if (state._peerKey != null) state._peerKey.interestOps(SelectionKey.OP_READ);
            }
        }

        private void handleRead(SelectionKey key) throws IOException {
            SocketChannel sourceChannel = (SocketChannel) key.channel();
            ConnectionState state = (ConnectionState) key.attachment();
            SocketChannel destinationChannel = state._peerChannel;

            _buffer.clear();
            int bytesRead = sourceChannel.read(_buffer);

            if (bytesRead == -1) {
                // Clean EOF from source side, teardown proxy pair
                throw new IOException("Connection closed by peer.");
            }

            if (bytesRead > 0) {
                _buffer.flip();
                // In a production app, you should handle partial writes by registering OP_WRITE.
                // For a simple example, we block-write the buffer out.
                while (_buffer.hasRemaining()) {
                    destinationChannel.write(_buffer);
                }
            }
        }

        private void closeConnection(SelectionKey key) {
            try {
                ConnectionState state = (ConnectionState) key.attachment();
                key.channel().close();
                key.cancel();

                if (state != null && state._peerChannel != null && state._peerChannel.isOpen()) {
                    state._peerChannel.close();
                    if (state._peerKey != null) {
                        state._peerKey.cancel();
                    }
                }
                log.info("Connection closed safely.");
            } catch (IOException e) {
                log.info("Error while closing channels: {}", e.getMessage());
            }
        }

    }

    // Attachment class to stitch the proxy legs together
    private static class ConnectionState {
        final SocketChannel _peerChannel;
        SelectionKey _peerKey;

        ConnectionState(SocketChannel peerChannel) {
            _peerChannel = peerChannel;
        }
    }
}