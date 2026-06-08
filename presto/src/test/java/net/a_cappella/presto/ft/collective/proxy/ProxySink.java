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

import net.a_cappella.continuo.ShutdownHook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.BindException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Set;
import java.util.concurrent.CountDownLatch;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class ProxySink {
    private static final Logger log = LoggerFactory.getLogger(ProxySink.class);

    protected final String _cmId;

    private final SinkAndPipes _sinkAndPipes;
    private final SinkThread _sinkThread = new SinkThread();
    private final int _port;

    private int _inBufSize = 512;
    private int _outBufSize = 512;
    private ByteBuffer _inBuf;
    private ByteBuffer _outBuf;

    private final CountDownLatch _stopLatch = new CountDownLatch(1);
    private volatile SinkStatus _sinkStatus = SinkStatus.INITIALIZED;

    private enum SinkStatus {
        INITIALIZED, STARTED, STOPPED
    }

    public ProxySink(SinkAndPipes sinkAndPipes, int port, String cmId) {
        _sinkAndPipes = sinkAndPipes;
        _port = port;
        _cmId = cmId;
    }

    protected void sendMsg(SelectionKey key, byte[] bytes) {
        SocketChannel client = (SocketChannel) key.channel();
        try {
            if (log.isDebugEnabled()) log.debug("{}sending {} to {}", _cmId, bytes, keyHash(key));
            _outBuf = ByteBuffer.wrap(bytes);
            do {
                client.write(_outBuf);
                _outBuf.compact();
            } while (_outBuf.position()!=0); // make sure to write the entire buffer
            if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, bytes.length, keyHash(key));
        } catch (IOException x) {
            // Channel is broken; SinkThread will detect it on next read and fire SrcDisconnectEvent
            log.info("{}{} Could not send to {} : {}", _cmId, x.getClass().getName(), keyHash(key), bytes);
        }
    }

    public void startSink() {
        ShutdownHook.registerShutdownAction(() -> stopSink());

        _inBuf = ByteBuffer.allocate(_inBufSize);
        _outBuf = ByteBuffer.allocate(_outBufSize);
        log.info("{}Server starting", _cmId);
        _sinkThread.setName(_cmId+"SinkThread");
        _sinkThread.start();
    }

    public void stopSink() {
        _sinkThread.signalStop();
        try {
            _stopLatch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public boolean isStarted() {
        return _sinkStatus == SinkStatus.STARTED;
    }
    public boolean isStopped() {
        return _sinkStatus == SinkStatus.STOPPED;
    }

    public void setInBufSize(int inBufSize) {
        _inBufSize = inBufSize;
    }
    public void setOutBufSize(int outBufSize) {
        _outBufSize = outBufSize;
    }


    private class SinkThread extends Thread {
        private Selector _selector = null;
        private ServerSocketChannel _server = null;
        private volatile boolean _stop = false;

        public void signalStop() {
            log.info("{}Stopping Sink", _cmId);
            _stop = true;
            if (_selector != null) _selector.wakeup();
        }

        public void run() {
            log.info("{}Starting Sink", _cmId);
            _sinkStatus = SinkStatus.STARTED;

            try {
                _selector = Selector.open();
                _server = ServerSocketChannel.open();
                _server.socket().setReuseAddress(true); // TODO is this really needed? allow rebind during TCP TIME_WAIT
                _server.socket().bind(new InetSocketAddress(_port));
                _server.configureBlocking(false);
                SelectionKey serverKey = _server.register(_selector, SelectionKey.OP_ACCEPT);

                while (!_stop) {
                    _selector.select(); // blocks until a message is received or the selector is woken up by 'signalStop'
                    if (!_selector.isOpen()) {
                        break;
                    }
                    Set<SelectionKey> keys = _selector.selectedKeys();
                    for (Iterator<SelectionKey> i = keys.iterator(); i.hasNext(); ) {
                        SelectionKey key = i.next();
                        i.remove();
                        if (key == serverKey) {
                            if (key.isAcceptable()) {
                                if (log.isDebugEnabled()) log.debug("{}acceptable server key {}", _cmId, keyHash(key));
                                try {
                                    SocketChannel client = _server.accept();
                                    client.socket().setKeepAlive(true);
                                    client.configureBlocking(false);
                                    client.socket().setTcpNoDelay(true);
                                    SelectionKey clientKey = client.register(_selector, SelectionKey.OP_READ);
                                    if (log.isDebugEnabled()) log.debug("{}registered client key {}", _cmId, keyHash(clientKey));
                                    _sinkAndPipes.onSrcConnect(clientKey);
                                } catch (IOException x) {
                                    log.error("{}Ignoring...", _cmId, x);
                                }
                            }
                        } else {
                            if (!key.isReadable()) continue;
                            SocketChannel client = (SocketChannel) key.channel();
                            if (log.isDebugEnabled()) log.debug("{}reading {}", _cmId, keyHash(key));
                            try {
                                int no = client.read(_inBuf);
                                if (no<0) throw new IOException("reached end-of-stream");
                                if (no>0) {
                                    if (log.isDebugEnabled()) log.debug("{}read {} bytes from {}", _cmId, no, keyHash(key));
                                }
                            } catch (IOException x) {
                                log.info("{}exception for key {}: {}", _cmId, keyHash(key), x.getMessage());
                                key.cancel();
                                try {
                                    client.close();
                                } catch (IOException y) {
                                    log.error("{}Ignoring...", _cmId, y);
                                }
                                try {
                                    _sinkAndPipes.onSrcDisconnect(key);
                                } catch (Exception y) {
                                    log.error("{}Unexpected exception", _cmId, y);
                                }
                                continue;
                            }
                            _inBuf.flip();
                            // TODO double check this logic....
                            byte[] bytes = new byte[_inBuf.remaining()];
                            _inBuf.get(bytes); // copy the contents of _inBuf into bytes
                            _inBuf.compact();

                            if (log.isDebugEnabled()) log.debug("{}Received: {}", _cmId, bytes);
                            _sinkAndPipes.onMsgFromSrc(key, bytes);
                        }
                    }
                }

                if (_selector != null) {
                    for (SelectionKey key : _selector.keys()) {
                        if (key == serverKey) continue;
                        try {
                            key.channel().close();   // sends FIN to the connected peer
                        } catch (IOException e) {
                            log.warn("{}error closing client channel {}", _cmId, e.getMessage());
                        }
                        key.cancel();
                    }
                }
                _server.close();
            } catch (BindException x) {
                log.error("{}{} {}", _cmId, x.getMessage(), _port);
            } catch (Exception x) {
                log.error(_cmId, x);
            }

            if (_selector != null && _selector.isOpen()) {
                try {
                    _selector.close();
                } catch (IOException e) {
                    log.error(_cmId, e);
                }
            }

            _stopLatch.countDown();
            log.info("{}Sink stopped", _cmId);
            _sinkStatus = SinkStatus.STOPPED;
        }
    }

}
