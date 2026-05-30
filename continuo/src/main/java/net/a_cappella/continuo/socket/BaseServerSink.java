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

package net.a_cappella.continuo.socket;

import java.io.IOException;
import java.net.BindException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CountDownLatch;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.continuo.utils.Utils.keyHash;

public class BaseServerSink {
    private static final Logger log = LoggerFactory.getLogger(BaseServerSink.class);

    protected String _cmId;

    private final SinkThread _sinkThread = new SinkThread();
    private final int _port;
    private final ConnectionMaps _conMap;

    private int _inBufSize = 512;
    private int _outBufSize = 512;
    private ByteBuffer _inBuf;
    private ByteBuffer _outBuf;
    private final MsgCoder _coder;
    private final List<Msg> _msgs = new ArrayList<>();

    private final CountDownLatch _stopLatch = new CountDownLatch(1);
    private volatile SinkStatus _sinkStatus = SinkStatus.INITIALIZED;

    private enum SinkStatus {
        INITIALIZED, STARTED, STOPPED
    }


    public BaseServerSink(MsgCoder coder, int port, String cmId) {
        _coder = coder;
        _port = port;
        _cmId = (cmId == null) ? "" : (cmId+" ");
        _conMap = new ConnectionMaps();
    }

    public void onClientConnect(SelectionKey key) {}
    public void onClientConnect(SelectionKey key, RegistrationRequest msg) {}
    public void onClientDisconnect(SelectionKey key) {}
    public void onMsg(SelectionKey key, Msg msg) {}

    public boolean isConnected(SelectionKey selKey) {
        return _conMap.isConnected(selKey);
    }

    protected void sendMsg(SelectionKey key, Msg msg) { // TODO non synchronized version
        SocketChannel client = (SocketChannel) key.channel();
        try {
            if (log.isDebugEnabled()) log.debug("{}sending {} to {}", _cmId, msg, keyHash(key));
            int len;
            synchronized (_outBuf) {
                _outBuf.clear();
                len = _coder.encode(msg, _outBuf);
                _outBuf.flip();
                do {
                    client.write(_outBuf);
                    _outBuf.compact();
                } while (_outBuf.position()!=0); // make sure to write the entire buffer
            }
            if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, len, keyHash(key));
            ((LongHolder) key.attachment()).incrementValue();
        } catch (IOException x) {
            log.info("{}{} Could not send to {} : {}", _cmId, x.getClass().getName(), keyHash(key), msg);
            throw new RuntimeException(x);
        }
    }
    protected void sendMsg(SelectionKey key, Msg[] msgs) { // TODO non synchronized version
        SocketChannel client = (SocketChannel) key.channel();
        try {
            if (log.isDebugEnabled()) log.debug("{}sending {} messages {}", _cmId, msgs.length, Arrays.toString(msgs));
            int len;
            synchronized (_outBuf) {
                _outBuf.clear();
                len = _coder.encode(msgs, _outBuf);
                _outBuf.flip();
                do {
                    client.write(_outBuf);
                    _outBuf.compact();
                } while (_outBuf.position()!=0); // make sure to write the entire buffer
            }
            if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, len, keyHash(key));
            ((LongHolder) key.attachment()).incrementValue();
        } catch (IOException x) {
            log.info("{}{} Could not send to {} {}", _cmId, x.getClass().getName(), keyHash(key), Arrays.toString(msgs));
            throw new RuntimeException(x);
        }
    }


    public void startSink() {
        ShutdownHook.registerShutdownAction(() -> stopSink());

        _inBuf = ByteBuffer.allocate(_inBufSize);
        _outBuf = ByteBuffer.allocate(_outBufSize);
        log.info("{}Server starting", _cmId);
        _conMap.logConnectionsMaps();
        _sinkThread.setName(_cmId+"SinkThread");
        _sinkThread.start();
    }

    public void stopSink() {
        _sinkThread.signalStop();
        try {
            _stopLatch.await();
        } catch (InterruptedException e) {}
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
                                    clientKey.attach(new LongHolder(0)); // TODO not really used
                                    if (log.isDebugEnabled()) log.debug("{}registered client key {}", _cmId, keyHash(clientKey));
                                    onClientConnect(clientKey);
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
                                    _conMap.disconnect(key);
                                    onClientDisconnect(key);
                                } catch (Exception y) {
                                    log.error("{}Unexpected exception", _cmId, y);
                                }
                                continue;
                            }
                            _inBuf.flip();
                            _coder.decode(_inBuf, _msgs);
                            _inBuf.compact();

                            for (int j=0; j<_msgs.size(); j++) {
                                Msg msg = _msgs.get(j);
                                if (msg==null) continue;
                                if (msg!=null) {
                                    try {
                                        handleMsg(key, msg);
                                    } catch (Exception y) {
                                        log.error("{}Unexpected exception", _cmId, y);
                                    }
                                }
                                msg.stopUsing();
                            }

                            _msgs.clear();
                        }
                    }
                }

                _conMap.sendDisconnectMessages();
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


    private void handleMsg(SelectionKey key, Msg msg) {
        if (msg instanceof RegistrationRequest) {
            RegistrationRequest req = (RegistrationRequest) msg;
            log.info("{}Received reg request: {}", _cmId, req);

            RegistrationResponse resp;
            SelectionKeyRequestPair pair = _conMap.connect(key, req);
            try {
                if (pair==null) {
                    resp = new RegistrationResponse('Y');
                    sendMsg(key, resp);
                    onClientConnect(key, req);
                } else {
                    resp = new RegistrationResponse('N');
                    sendMsg(key, resp);
                    _conMap.disconnect(key);
                }
                log.info("{}Sent: {} to {}", _cmId, resp, req.getMyConnInfo());
            } catch (Exception x) {
                _conMap.disconnect(key);
                throw x;
            }
        } else {
            if (log.isDebugEnabled()) log.debug("{}Received: {}", _cmId, msg);
            onMsg(key, msg);
        }
    }

    public SelectionKey getSelKeyForConn(ConnInfo connInfo) {
        return _conMap.getSelKeyForConn(connInfo);
    }

    public Set<SelectionKey> getSelectionKeys() {
        return _conMap._selKey2regKeyMap.keySet();
    }








    private class ConnectionMaps {
        private final ForceDisconnect _forceDisconnectMsg = new ForceDisconnect();
        private final ConcurrentMap<String, SelectionKeyRequestPair> _regKey2pairMap = new ConcurrentHashMap<>();
        private final ConcurrentMap<SelectionKey, String> _selKey2regKeyMap = new ConcurrentHashMap<>();

        public ConnectionMaps() {}

        public SelectionKey getSelKeyForConn(ConnInfo connInfo) {
            String regKey = connInfo.getConn();
            SelectionKeyRequestPair pair = _regKey2pairMap.get(regKey);
            if (pair == null) return null;
            return pair._selKey;
        }

        public SelectionKeyRequestPair connect(SelectionKey selKey, RegistrationRequest reg) {
            if (log.isDebugEnabled()) {
                log.debug("{}connecting {} {}", _cmId, keyHash(selKey), reg);
            }
            String regKey = reg.getKey();
            _selKey2regKeyMap.put(selKey, regKey);
            SelectionKeyRequestPair oldPair = _regKey2pairMap.putIfAbsent(regKey, new SelectionKeyRequestPair(selKey, reg));
            logConnectionsMaps();
            if (log.isTraceEnabled()) {
                log.trace("{}oldPair={}", _cmId, oldPair);
            }
            return oldPair;
        }

        public boolean isConnected(SelectionKey selKey) {
            return _selKey2regKeyMap.get(selKey) != null;
        }

        public void disconnect(SelectionKey selKey) {
            SelectionKeyRequestPair pair = null;
            String regKey = _selKey2regKeyMap.remove(selKey);
            if (regKey==null) {
                log.info("{}not disconnecting unknown key {}", _cmId, keyHash(selKey));
                return;
            }
            if (log.isDebugEnabled()) log.debug("{}disconnecting {}", _cmId, keyHash(selKey));
            SelectionKeyRequestPair oldPair = _regKey2pairMap.get(regKey);
            if (oldPair!=null && oldPair._selKey.equals(selKey)) {
                pair = _regKey2pairMap.remove(regKey);
            }
            logConnectionsMaps();
            log.info("{}disconnected {}{}", _cmId, keyHash(selKey), ((pair==null) ? "" : " <-> "+pair._reg.getAppInfo()));
        }

        public void sendDisconnectMessages() {
            for (SelectionKey key : _selKey2regKeyMap.keySet()) {
                try {
                    sendMsg(key, _forceDisconnectMsg);
                } catch (Exception x) {
                    log.info("{}Could not send disconnect message to {} {}", _cmId, keyHash(key), x.getMessage());
                }
            }
        }

        public String toString() {
            return "\n  selKey2reqKeyMap="+selKey2reqKeyMap2String()+"\n  reqKey2pairMap="+_regKey2pairMap;
        }
        public void logConnectionsMaps() {
            if (log.isTraceEnabled()) {
                log.trace("{}  selKey2reqKeyMap={}", _cmId, selKey2reqKeyMap2String());
                log.trace("{}  reqKey2pairMap={}", _cmId, _regKey2pairMap);
            }
        }

        private String selKey2reqKeyMap2String() {
            Iterator<Entry<SelectionKey, String>> i = _selKey2regKeyMap.entrySet().iterator();
            if (! i.hasNext())
                return "{}";

            StringBuilder sb = new StringBuilder();
            sb.append('{');
            for (;;) {
                Entry<SelectionKey, String> e = i.next();
                SelectionKey key = e.getKey();
                String value = e.getValue();
                sb.append(keyHash(key));
                sb.append('=');
                sb.append(value);
                if (! i.hasNext())
                    return sb.append('}').toString();
                sb.append(',').append(' ');
            }
        }
    }

    private static class SelectionKeyRequestPair {
        public SelectionKey _selKey;
        public RegistrationRequest _reg;
        public SelectionKeyRequestPair(SelectionKey selKey, RegistrationRequest reg) {
            _selKey = selKey;
            _reg = new RegistrationRequest(reg);
        }
        public String toString() {
            return "("+keyHash(_selKey)+","+_reg+")";
        }
    }

    private static class LongHolder {
        private long _value;

        public LongHolder(long value) {
            _value = value;
        }
        public long getValue() {
            return _value;
        }
        public void setValue(long value) {
            _value = value;
        }
        public void incrementValue() {
            _value++;
        }
    }
}
