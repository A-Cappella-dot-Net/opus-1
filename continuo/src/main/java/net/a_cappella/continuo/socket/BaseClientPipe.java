package net.a_cappella.continuo.socket;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.msg.*;
import net.a_cappella.continuo.utils.Utils;
import org.agrona.concurrent.IdleStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BaseClientPipe {
    private static final Logger log = LoggerFactory.getLogger(BaseClientPipe.class);

    private final String _cmId;

    private final MsgCoder _coder;
    protected AppInfo _myInfo;
    protected ConnInfo _sinkInfo;

    private final String _creatorName;
    private final PipeThread _pipeThread = new PipeThread();
    private SocketChannel _channel = null;

    private int _inBufferSize = 512;
    private int _outBufferSize = 512;
    private ByteBuffer _inBuf;
    private ByteBuffer _outBuf;
    private final List<Msg> _msgs = new ArrayList<>();

    private final RegistrationRequest _reg;

    private int _reconnectIntervalMillis = 200;
    private int _connectionTimeoutNanos = 200 * 1_000; // 200 micros
    private IdleStrategy _idleStrategy = Utils.BACKOFF_IDLE_STRATEGY;

    private volatile PipeStatus _pipeStatus = PipeStatus.INITIALIZED;

    private enum PipeStatus {
        INITIALIZED, STARTED, CONNECTED, DISCONNECTED, STOPPED
    }



    public BaseClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, int inBufferSize, int outBufferSize, String cmId, String creatorName) {
        this(coder, myInfo, sinkInfo, cmId, creatorName);
        _inBufferSize = inBufferSize;
        _outBufferSize = outBufferSize;
    }

    public BaseClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, String cmId, String creatorName) {
        _coder = coder;
        _myInfo = myInfo;
        _sinkInfo = sinkInfo;
        _cmId = (cmId==null) ? "" : (cmId+" ");
        _reg = new RegistrationRequest(_myInfo, 0L);
        _creatorName= creatorName;
    }

    public void startPipe() {
        StackTraceElement ste = Thread.currentThread().getStackTrace()[2];
        String caller = String.format("%s.%s(%s:%d)", ste.getClassName(), ste.getMethodName(), ste.getFileName(), ste.getLineNumber());
        if (_inBuf == null) _inBuf = ByteBuffer.allocate(_inBufferSize);
        if (_outBuf == null) _outBuf = ByteBuffer.allocate(_outBufferSize);
        _inBuf.clear();
        _outBuf.clear();
        _pipeThread.setName(_creatorName + "PipeThread");
        _pipeThread.setCaller(caller);
        _pipeThread.start();
    }

    public void stopPipe() {
        _pipeThread.signalStop();
    }

    public void onConnect() {}
    public void onDisconnect() {}
    public void onStopped() {}

    public void sendMsg(Msg msg) throws IOException { // TODO non synchronized version
        if (log.isDebugEnabled()) log.debug("{}sending {} to {}", _cmId, msg, this);
        int len;
        synchronized (_outBuf) {
            len = _coder.encode(msg, _outBuf);
            _outBuf.flip();
            do {
                _channel.write(_outBuf);
                _outBuf.compact();
            } while (_outBuf.position()!=0);
        }
        if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, len, this);
    }

    public void sendMsg(Msg[] msgs) throws IOException { // TODO non synchronized version
        if (log.isDebugEnabled()) log.debug("{}sending {} to {}", _cmId, Arrays.toString(msgs), this);
        int len;
        synchronized (_outBuf) {
            len = _coder.encode(msgs, _outBuf);
            _outBuf.flip();
            do {
                _channel.write(_outBuf);
                _outBuf.compact();
            } while (_outBuf.position()!=0);
        }
        if (log.isDebugEnabled()) log.debug("{}sent    {} bytes to {}", _cmId, len, this);
    }

    public void onMsg(Msg msg) {
        if (log.isDebugEnabled()) log.debug("{}received {}", _cmId, msg);
    }

    public void onRegistrationResponse() {
        log.info("{}Received: Y from {}", _cmId, _sinkInfo);
    }

    public void setDaemonInfo(ConnInfo myConnInfo) {
        _reg.setMyConnInfo(myConnInfo);
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

    public void setReconnectInterval(int reconnectIntervalMillis) {
        _reconnectIntervalMillis = reconnectIntervalMillis;
    }
    public void setConnectionTimeoutMicros(int connectionTimeoutMicros) {
        _connectionTimeoutNanos = connectionTimeoutMicros * 1000;
    }
    public void setIdleStrategy(Object idleStrategyObj) {
        _idleStrategy = Utils.getIdleStrategy(idleStrategyObj, "backoff");
    }


    public String toString() {
        return _sinkInfo.getConn();
    }
    private String getExceptionSummary(Exception x) {
        return _sinkInfo.getConn()+" - "+(x.getMessage()==null ? x.getClass().getCanonicalName() : x.getMessage());
    }
    private String getConnectionSummary(SocketAddress localAddress) {
        return this+((localAddress==null)?"":(" on "+localAddress));
    }







    private class PipeThread extends Thread {
        private String _caller;
        private volatile boolean _stop = false;

        public void setCaller(String caller) {
            _caller = caller;
        }

        public void signalStop() {
            log.info("{}Stopping ClientPipe {}", _cmId, _sinkInfo);
            try {
                if (_channel!=null && _channel.isConnected()) _channel.shutdownInput();
            } catch (IOException e) {
                if (log.isDebugEnabled()) log.debug("", e);
            }
            _stop = true;
        }

        @Override
        public void run() {
            log.info("{}Starting ClientPipe {} {}", _cmId, _sinkInfo, _caller);
            boolean firstAttempt = true;
            SocketAddress socketAddress = new InetSocketAddress(_sinkInfo.getHost(), _sinkInfo.getPort());
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

                    sendRegistrationRequest();

                    safeOnConnect();

                    readAndProcessMessagesLoop();

                    log.info("{}Disconnected from sink {}", _cmId, getConnectionSummary(localAddress));
                    _pipeStatus = PipeStatus.DISCONNECTED;
                    safeOnDisconnect();
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
            log.info("{}ClientPipe Stopped {} {}", _cmId, BaseClientPipe.this, _caller);
            _pipeStatus = PipeStatus.STOPPED;
            onStopped();
        }

        private void safeOnConnect() {
            try {
                onConnect();
            } catch (Exception e) {
                log.error("{}Unexpected error", _cmId, e);
            }
        }
        private void safeOnDisconnect() {
            try {
                onDisconnect();
            } catch (Exception e) {
                log.error("{}Unexpected error", _cmId, e);
            }
        }

        private void sendRegistrationRequest() {
            _reg.setStartTime();
            try {
                log.info("{}Sending reg request {}", _cmId, _reg);
                sendMsg(_reg);
            } catch (IOException x) {
                String info = "Could not send registration request. Exiting...";
                System.out.println(info);
                log.error(info, x);

                try {Thread.sleep(500);} catch (InterruptedException e) {}
                System.exit(-1);
            }
        }

        private SocketAddress connectNonBlocking(SocketAddress socketAddress) throws IOException {
            boolean connected = _channel.connect(socketAddress);
            long nanoStart = System.nanoTime();
            while (!connected) {
                // If this channel is in non-blocking mode then this method will return false
                connected = _channel.finishConnect();
                if (!connected && (nanoStart+_connectionTimeoutNanos < System.nanoTime())) {
                    throw new IOException("Non blocking connect failed. Is connectionTimeoutMicros (" + (_connectionTimeoutNanos / 1_000) + ") sufficient?");
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
            if (_channel.read(_inBuf)<0) {
                if (log.isDebugEnabled()) log.debug("{}EOF reached {}", _cmId, BaseClientPipe.this);
                return -1;
            }
            int workCount = 0;
            boolean disconnect = false;
            _inBuf.flip();
            _coder.decode(_inBuf, _msgs);
            _inBuf.compact();
            for (int i=0; i<_msgs.size(); i++) {
                workCount++;
                Msg msg = _msgs.get(i);
                if (msg instanceof RegistrationResponse) {
                    RegistrationResponse resp = (RegistrationResponse) msg;
                    if (resp._outcome=='N') {
                        String info = _cmId+" already connected to "+_sinkInfo.getConn()+". Exiting...";
                        System.out.println(info);
                        log.info(info);

                        try {Thread.sleep(500);} catch (InterruptedException x) {}
                        System.exit(1);
                    }
                    _pipeStatus = PipeStatus.CONNECTED;
                    onRegistrationResponse();
                } else if (msg instanceof ForceDisconnect) {
                    onDisconnect();
                    disconnect = true;
                } else {
                    onMsg(msg);
                }
                msg.stopUsing();
            }
            _msgs.clear();
            if (disconnect) return -1;
            return workCount;
        }
    }
}
