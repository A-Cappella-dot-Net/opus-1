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

import net.a_cappella.continuo.utils.Utils;
import org.agrona.concurrent.IdleStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.concurrent.CountDownLatch;

public class ProxyPipe {
    private static final Logger log = LoggerFactory.getLogger(ProxyPipe.class);

    private final String _localHost = Utils._localhost;

    private final SinkAndPipes _sinkAndPipes;
    private final int _port;
    private final String _cmId;

    private final PipeThread _pipeThread = new PipeThread();
    private SocketChannel _channel = null;

    private int _inBufferSize = 512;
    private int _outBufferSize = 512;
    private ByteBuffer _inBuf;
    private ByteBuffer _outBuf;

    private final CountDownLatch _stopLatch = new CountDownLatch(1);
    private volatile PipeStatus _pipeStatus = PipeStatus.INITIALIZED;

    private enum PipeStatus {
        INITIALIZED, STARTED, CONNECTED, DISCONNECTED, STOPPED
    }

    private int _reconnectIntervalMillis = 200;
    private long _connectionTimeoutNanos = 200L * 1_000_000L; // 200 millis
    private IdleStrategy _idleStrategy = Utils.getIdleStrategy("backoff");

    public ProxyPipe(SinkAndPipes sinkAndPipes, int port, String cmId) {
        _sinkAndPipes = sinkAndPipes;
        _port = port;
        _cmId = cmId;
    }

    public void startPipe() {
        StackTraceElement ste = Thread.currentThread().getStackTrace()[2];
        String caller = String.format("%s.%s(%s:%d)", ste.getClassName(), ste.getMethodName(), ste.getFileName(), ste.getLineNumber());
        if (_inBuf == null) _inBuf = ByteBuffer.allocate(_inBufferSize);
        if (_outBuf == null) _outBuf = ByteBuffer.allocate(_outBufferSize);
        _inBuf.clear();
        _outBuf.clear();
        _pipeThread.setName(_cmId + " PipeThread");
        _pipeThread.setCaller(caller);
        _pipeThread.start();
    }

    public void stopPipe() {
        _pipeThread.signalStop();
        try {
            _stopLatch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void sendMsg(byte[] bytes) throws IOException {
        if (_channel == null || !_channel.isConnected()) return;
        if (log.isDebugEnabled()) log.debug("{}sending {} to {}", _cmId, bytes, this);
        _outBuf = ByteBuffer.wrap(bytes);
        do {
            _channel.write(_outBuf);
            _outBuf.compact();
        } while (_outBuf.position()!=0);
        if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, bytes.length, this);
    }

    public boolean isStarted() {
        return _pipeStatus == PipeStatus.STARTED;
    }
    public boolean isConnected() {
        return _pipeStatus == PipeStatus.CONNECTED;
    }
    public boolean isDisconnected() {
        return _pipeStatus == PipeStatus.DISCONNECTED;
    }
    public boolean isStopped() {
        return _pipeStatus == PipeStatus.STOPPED;
    }

    public String toString() {
        return Integer.toString(_port);
    }
    private String getExceptionSummary(Exception x) {
        return _port+" - "+(x.getMessage()==null ? x.getClass().getCanonicalName() : x.getMessage());
    }
    private String getConnectionSummary(SocketAddress localAddress) {
        return _port+((localAddress==null)?"":(" on "+localAddress));
    }


    private class PipeThread extends Thread {
        private String _caller;
        private volatile boolean _stop = false;

        public void setCaller(String caller) {
            _caller = caller;
        }

        public void signalStop() {
            log.info("{}Stopping ClientPipe {}", _cmId, _port);
            try {
                if (_channel!=null && _channel.isConnected()) _channel.shutdownInput();
            } catch (IOException e) {
                if (log.isDebugEnabled()) log.debug("", e);
            }
            _stop = true;
        }

        @Override
        public void run() {
            log.info("{}Starting ClientPipe {} {}", _cmId, _port, _caller);
            boolean firstAttempt = true;
            SocketAddress socketAddress = new InetSocketAddress(_localHost, _port);
            _pipeStatus = PipeStatus.STARTED;
            while (!_stop) {
                boolean connected = false;
                SocketAddress localAddress = null;
                if (firstAttempt) log.info("{}Connecting to sink {}", _cmId, getConnectionSummary(localAddress));
                try {
                    _channel = SocketChannel.open();
                    _channel.socket().setSoLinger(true, 1);
                    _channel.socket().setKeepAlive(true);
                    _channel.configureBlocking(false);
                    _channel.socket().setTcpNoDelay(true);

                    localAddress = connectNonBlocking(socketAddress);
                    connected = true;

                    log.info("{}Connected to sink {}", _cmId, getConnectionSummary(localAddress));
                    _inBuf.clear();
                    _outBuf.clear();

                    safeOnConnect();

                    readAndProcessMessagesLoop();

                    log.info("{}Disconnected from sink {}", _cmId, getConnectionSummary(localAddress));
                } catch (IOException x) {
                    if (firstAttempt) {
                        log.info("{}Disconnected from sink {}", _cmId, getExceptionSummary(x));
                    }
                } finally {
                    if (firstAttempt) {
                        _pipeStatus = PipeStatus.DISCONNECTED;
                        safeOnDisconnect();

                        log.info("{}Closing channel {}", _cmId, getConnectionSummary(localAddress));
                        firstAttempt = false;
                    }
                    try {
                        _channel.close();
                    } catch (IOException e) {
                        if (log.isDebugEnabled()) log.debug("{}Closing channel failed {}", _cmId, getConnectionSummary(localAddress), e);
                    }
                    if (connected) {
                        firstAttempt = true;
                    }
                }

                if (_stop) break;
                try {Thread.sleep(_reconnectIntervalMillis);} catch (InterruptedException x) {}
            }

            _stopLatch.countDown();
            log.info("{}ClientPipe Stopped {} {}", _cmId, getConnectionSummary(null), _caller);
            _pipeStatus = PipeStatus.STOPPED;
        }

        private void safeOnConnect() {
            try {
                _sinkAndPipes.onDstConnect();
            } catch (Exception e) {
                log.error("{}Unexpected error", _cmId, e);
            }
        }
        private void safeOnDisconnect() {
            try {
                _sinkAndPipes.onDstDisconnect();
            } catch (Exception e) {
                log.error("{}Unexpected error", _cmId, e);
            }
        }

        private SocketAddress connectNonBlocking(SocketAddress socketAddress) throws IOException {
            boolean connected = _channel.connect(socketAddress);
            long nanoStart = System.nanoTime();
            _idleStrategy.reset();
            while (!connected) {
                _idleStrategy.idle();
                // If this channel is in non-blocking mode then this method will return false
                connected = _channel.finishConnect();
                if (!connected && (nanoStart+_connectionTimeoutNanos < System.nanoTime())) {
                    throw new IOException("Non blocking connect failed. Is connectionTimeoutMillis (" + (_connectionTimeoutNanos / 1_000_000) + ") sufficient?");
                }
            }
            return _channel.getLocalAddress();
        }

        private void readAndProcessMessagesLoop() {
            int workCount;
            while (!_stop) {
                workCount = -1;
                try {
                    workCount = readAndProcessMessages();
                } catch (IOException e) {
                    log.info("{}Read loop {}", _cmId, getExceptionSummary(e));
                } catch (Exception e) {
                    log.error("{}Read loop {}", _cmId, getExceptionSummary(e), e);
                }
                if (workCount<0) break;
                _idleStrategy.idle(workCount);
            }
        }
        private int readAndProcessMessages() throws Exception {
            int bytesRead = _channel.read(_inBuf);
            if (bytesRead < 0) {
                if (log.isDebugEnabled()) log.debug("{}EOF reached {}", _cmId, this);
                return -1;
            }
            if (bytesRead == 0) {
                return 0; // no data — let idle strategy back off
            }
            _inBuf.flip();
            byte[] bytes = new byte[_inBuf.remaining()];
            _inBuf.get(bytes);
            _inBuf.clear();
            _sinkAndPipes.onMsgFromDst(ProxyPipe.this, bytes);
            return 1;
        }
    }
}
