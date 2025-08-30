package net.a_cappella.presto.ps;

import io.aeron.Aeron;
import io.aeron.FragmentAssembler;
import io.aeron.Publication;
import io.aeron.Subscription;
import io.aeron.logbuffer.FragmentHandler;
import io.aeron.logbuffer.Header;
import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.obj.SnapTimeoutObj;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.agrona.DirectBuffer;
import org.agrona.MutableDirectBuffer;
import org.agrona.concurrent.MessageHandler;
import org.agrona.concurrent.SnowflakeIdGenerator;
import org.agrona.concurrent.UnsafeBuffer;
import org.agrona.concurrent.ringbuffer.OneToOneRingBuffer;
import org.agrona.concurrent.ringbuffer.RingBuffer;
import org.agrona.concurrent.ringbuffer.RingBufferDescriptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.Map;

public class AeronClient extends CollectiveClient implements PrestoClient {
    private static final Logger log = LoggerFactory.getLogger(AeronClient.class);

    /**
     * When setting _useIpcLoopback to true make sure loopback via hardware is disabled.
     * For example, if using a SolarFlare card set EF_MCAST_RECV_HW_LOOP=0.
     */
    private boolean _useIpcLoopback = false;
    public void setUseIpcLoopback(String useIpcLoopbackStr) {
        _useIpcLoopback = Boolean.parseBoolean(useIpcLoopbackStr);
    }

    private final String _ipcChannel = "aeron:ipc";
    private String _multicastChannel = "aeron:udp?endpoint=224.0.1.1:40123";
    public void setMulticastChannel(String multicastChannel) {
        _multicastChannel = Utils.parseAsString("multicastChannel", multicastChannel, _multicastChannel);
    }
    private String _unicastChannel = "aeron:udp?endpoint=localhost:40123";
    public void setUnicastChannel(String unicastChannel) {
        _unicastChannel = Utils.parseAsString("unicastChannel", unicastChannel, _unicastChannel);
    }

    private String _channel = _multicastChannel;
    public void setChannelType(String channel) {
        switch (channel) {
            case "unicast":
                _channel = _unicastChannel;
                break;
            case "multicast":
                _channel = _multicastChannel;
                break;
            case "ipc":
                _channel = _ipcChannel;
                break;
            default:
                log.error("Un recognized channel {}. Defaulting to {}", channel, _channel);
                break;
        }
    }

    private int _pubStream = 10;
    public void setPubStream(String pubStream) {
        _pubStream = Utils.parseAsInt("pubStream", pubStream, _pubStream);
    }
    private int _subStream = 10;
    public void setSubStream(String subStream) {
        _subStream = Utils.parseAsInt("subStream", subStream, _subStream);
    }

    private int _maxRead_0 = Integer.MAX_VALUE;
    public void setMaxRead0(int maxRead) {
        _maxRead_0 = maxRead;
    }
    private int _maxRead_1 = Integer.MAX_VALUE;
    public void setMaxRead1(int maxRead) {
        _maxRead_1 = maxRead;
    }
    private int _maxRead_2 = 1;
    public void setMaxRead2(int maxRead) {
        _maxRead_2 = maxRead;
    }
    private int _maxRead_3 = Integer.MAX_VALUE;
    public void setMaxRead3(int maxRead) {
        _maxRead_3 = maxRead;
    }
    private int _maxRead_4 = Integer.MAX_VALUE;
    public void setMaxRead4(int maxRead) {
        _maxRead_4 = maxRead;
    }



    private final TightLoopThread _tightLoopThread;
    private final SnSManager _sns;
    private final MsgAccumulator _msgAcc = new MsgAccumulator();
    private final AeronObjCoder _objCoder;
    public final PublicationHelper _pubHelper;

    private final Aeron _aeron;

    private Publication _pubIpc_0;
    private Publication _pubIpc_1;
    private Publication _pubIpc_2;
    private Publication _pubIpc_3;
    private Publication _pubIpc_4;
    private Publication _pubIpc_5;
    private Publication _pubIpc_6;
    private Publication _pubMct_0;
    private Publication _pubMct_1;
    private Publication _pubMct_2;
    private Publication _pubMct_3;
    private Publication _pubMct_4;
    private Publication _pubMct_5;
    private Publication _pubMct_6;
    private Subscription _subIpc_0;
    private Subscription _subIpc_1;
    private Subscription _subIpc_2;
    private Subscription _subIpc_3;
    private Subscription _subMct_0;
    private Subscription _subMct_1;
    private Subscription _subMct_2;
    private Subscription _subMct_3;

    private FragmentAssembler _assemblerIpc_0;
    private FragmentAssembler _assemblerIpc_1;
    private FragmentAssembler _assemblerIpc_2;
    private FragmentAssembler _assemblerIpc_3;
    private FragmentAssembler _assemblerMct_0;
    private FragmentAssembler _assemblerMct_1;
    private FragmentAssembler _assemblerMct_2;
    private FragmentAssembler _assemblerMct_3;

    private final MessageHandler _loopbackHandler = new LoopbackMessageHandler();

    private int _ringBufferSizePowerOf2Exponent = 20;
    public void setRingBufferSizePowerOf2Exponent(String ringBufferSizePowerOf2Exponent) {
        _ringBufferSizePowerOf2Exponent = Utils.parseAsInt("ringBufferSizePowerOf2Exponent", ringBufferSizePowerOf2Exponent, _ringBufferSizePowerOf2Exponent);
    }
    private RingBuffer _ringBuffer;

    private final SnowflakeIdGenerator _idGenerator;

    private long _seqNo = 0L;
    public long getSeqNo() {
        return _seqNo;
    }
    public void setSeqNo(long seqNo) {
        _seqNo = seqNo;
    }

    public AeronClient(MsgCoder coder, String connInfoStr, String monConfInterval, String memConfInterval,
                       TightLoopThread tightLoopThread, PublicationHelper pubHelper, Map<String, String> params) {
        super(coder, connInfoStr, monConfInterval, memConfInterval);

        _idGenerator = new SnowflakeIdGenerator(Math.abs(_myInfo.getId().hashCode()) % SnowflakeIdGenerator.MAX_NODE_ID_AND_SEQUENCE_BITS);
        _tightLoopThread = tightLoopThread;
        _pubHelper = pubHelper;
        _sns = new SnSManager(this, params);
        _objCoder = new AeronObjCoder(_myInfo.getId());
        _aeron = Aeron.connect(new Aeron.Context());
    }

    public void addSnippet(TightLoopSnippet snippet) {
        _tightLoopThread.add(snippet);
    }

    public boolean onTLT() {
        return _tightLoopThread.isCurrentThread();
    }

    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener) throws Exception {
        return _sns.snapSubscribe(sql, subListener);
    }
    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener, IMergeManager mergeManager) throws Exception {
        return _sns.snapSubscribe(sql, subListener, mergeManager);
    }
    @Override
    public long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        return _sns.snapSubscribe(sqlComps, subListener);
    }
    @Override
    public long snap(String sql, ISubscriptionListener subListener) throws Exception {
        return _sns.snap(sql, subListener);
    }
    @Override
    public long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        return _sns.snap(sqlComps, subListener);
    }
    @Override
    public long subscribe(String sql, ISubscriptionListener subListener) throws Exception {
        return _sns.subscribe(sql, subListener);
    }
    @Override
    public long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        return _sns.subscribe(sqlComps, subListener);
    }
    @Override
    public void unsubscribe(long subId) {
        _sns.unsubscribe(subId);
    }

    @Override // CollectiveClient
    public void start() {
        ShutdownHook.registerShutdownAction(() -> stop());

        int ringBufferSize = (1<<_ringBufferSizePowerOf2Exponent) + RingBufferDescriptor.TRAILER_LENGTH;
        log.info("ringBufferSize="+ringBufferSize);
        _ringBuffer = new OneToOneRingBuffer(new UnsafeBuffer(ByteBuffer.allocateDirect(ringBufferSize)));
        log.info("ringBuffer capacity="+_ringBuffer.capacity()+", maxMsgLength="+_ringBuffer.maxMsgLength());

        if (_useIpcLoopback) {
            log.info("Channel {} & stream {}/{}", _ipcChannel, _pubStream, _subStream);
            _pubIpc_0 = _aeron.addPublication(_ipcChannel, _pubStream);
            _pubIpc_1 = _aeron.addPublication(_ipcChannel, _pubStream+1);
            _pubIpc_2 = _aeron.addPublication(_ipcChannel, _pubStream+2);
            _pubIpc_3 = _aeron.addPublication(_ipcChannel, _pubStream+3);

            _pubIpc_4 = _aeron.addPublication(_ipcChannel, _pubStream+4);
            _pubIpc_5 = _aeron.addPublication(_ipcChannel, _pubStream+5);
            _pubIpc_6 = _aeron.addPublication(_ipcChannel, _pubStream+6);

            _subIpc_0 = _aeron.addSubscription(_ipcChannel, _subStream);
            _subIpc_1 = _aeron.addSubscription(_ipcChannel, _subStream+1);
            _subIpc_2 = _aeron.addSubscription(_ipcChannel, _subStream+2);
            _subIpc_3 = _aeron.addSubscription(_ipcChannel, _subStream+3);

            _assemblerIpc_0 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream));
            _assemblerIpc_1 = new FragmentAssembler(new ClientFragmentHandler(true,  _subStream+1));
            _assemblerIpc_2 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream+2));
            _assemblerIpc_3 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream+3));
        }

        log.info("Channel {} & stream {}/{}", _channel, _pubStream, _subStream);
        _pubMct_0 = _aeron.addPublication(_channel, _pubStream+10);
        _pubMct_1 = _aeron.addPublication(_channel, _pubStream+11);
        _pubMct_2 = _aeron.addPublication(_channel, _pubStream+12);
        _pubMct_3 = _aeron.addPublication(_channel, _pubStream+13);

        _pubMct_4 = _aeron.addPublication(_channel, _pubStream+14);
        _pubMct_5 = _aeron.addPublication(_channel, _pubStream+15);
        _pubMct_6 = _aeron.addPublication(_channel, _pubStream+16);

        _subMct_0 = _aeron.addSubscription(_channel, _subStream+10);
        _subMct_1 = _aeron.addSubscription(_channel, _subStream+11);
        _subMct_2 = _aeron.addSubscription(_channel, _subStream+12);
        _subMct_3 = _aeron.addSubscription(_channel, _subStream+13);

        _assemblerMct_0 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream+10));
        _assemblerMct_1 = new FragmentAssembler(new ClientFragmentHandler(true,  _subStream+11));
        _assemblerMct_2 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream+12));
        _assemblerMct_3 = new FragmentAssembler(new ClientFragmentHandler(false, _subStream+13));

        TightLoopSnippet op = new SubscriptionDispatcher();
        _tightLoopThread.add(op);
        super.setPrestoClient(this);
        super.start();
    }

    public void stop() {
        log.info("Stopping AeronClient");
        super.stop();
        _aeron.close();
        _sns.stop();
    }

    public void waitUntilInitialized() {
        log.info("Waiting for AeronClient to connect");

        if (_useIpcLoopback) {
            while (!_pubIpc_0.isConnected());
            while (!_pubIpc_1.isConnected());
            while (!_pubIpc_2.isConnected());
            while (!_pubIpc_3.isConnected());
        } else {
            while (!_pubMct_0.isConnected());
            while (!_pubMct_1.isConnected());
            while (!_pubMct_2.isConnected());
            while (!_pubMct_3.isConnected());
        }

        log.info("all publications connected...");

        if (_useIpcLoopback) {
            while (!_subIpc_0.isConnected());
            while (!_subIpc_1.isConnected());
            while (!_subIpc_2.isConnected());
            while (!_subIpc_3.isConnected());
        } else {
            while (!_subMct_0.isConnected());
            while (!_subMct_1.isConnected());
            while (!_subMct_2.isConnected());
            while (!_subMct_3.isConnected());
        }

        log.info("all subscriptions connected...");
    }

    private class SubscriptionDispatcher implements TightLoopSnippet {

        @Override // TightLoopSnippet
        public int executeSnippet() {

            int fragmentsRead = 0;

            if (_useIpcLoopback) {
                int read10 = _subIpc_0.poll(_assemblerIpc_0, _maxRead_0);
                fragmentsRead += read10;
                if (_hIpc_0!=null) _hIpc_0.recordValue(read10);
            }

            int read20 = _subMct_0.poll(_assemblerMct_0, _maxRead_0);
            fragmentsRead += read20;
            if (_hMct_0!=null) _hMct_0.recordValue(read20);

            if (_useIpcLoopback) {
                int read11 = _subIpc_1.poll(_assemblerIpc_1, _maxRead_1);
                fragmentsRead += read11;
                if (_hIpc_1!=null) _hIpc_1.recordValue(read11);
            }

            int read21 = _subMct_1.poll(_assemblerMct_1, _maxRead_1);
            fragmentsRead += read21;
            if (_hMct_1!=null) _hMct_1.recordValue(read21);

            _msgAcc.notifyAndReset();

            if (_useIpcLoopback) {
                int read12 = _subIpc_2.poll(_assemblerIpc_2, _maxRead_2);
                fragmentsRead += read12;
                if (_hIpc_2!=null) _hIpc_2.recordValue(read12);
            }

            int read22 = _subMct_2.poll(_assemblerMct_2, _maxRead_2);
            fragmentsRead += read22;
            if (_hMct_2!=null) _hMct_2.recordValue(read22);

            if (fragmentsRead == 0) {
                if (_useIpcLoopback) {
                    int read13 = _subIpc_3.poll(_assemblerIpc_3, _maxRead_3);
                    fragmentsRead += read13;
                    if (_hIpc_3!=null) _hIpc_3.recordValue(read13);
                }

                int read23 = _subMct_3.poll(_assemblerMct_3, _maxRead_3);
                fragmentsRead += read23;
                if (_hMct_3!=null) _hMct_3.recordValue(read23);
            }

            if (fragmentsRead == 0) {
                int read4 = _ringBuffer.read(_loopbackHandler, _maxRead_4);
                fragmentsRead += read4;
            }

            return fragmentsRead;
        }
    }

    private class ClientFragmentHandler implements FragmentHandler {
        private final boolean _accumulate;
        private final int _stream;

        public ClientFragmentHandler(boolean accumulate, int stream) {
            _accumulate = accumulate;
            _stream = stream;
        }

        @Override
        public void onFragment(DirectBuffer buffer, int offset, int length, Header header) {
            AeronCoder cod = _objCoder.decodeHeader(buffer, offset, length, _stream);
            if (cod != null) {
                String subject = cod.getSubject();
                long seqNo = cod.getSeqNo();
                if (seqNo > 0) _seqNo = seqNo;
                _sns.passMsgToAllSubjectSubscribers(subject, subscribers -> decodeAndNotify(cod, _accumulate, subject, subscribers));
                cod.setObj(null);
            }
        }
    }

    private class LoopbackMessageHandler implements MessageHandler {
        public void onMessage(int msgTypeId, MutableDirectBuffer buffer, int offset, int length) {
            AeronCoder cod = _objCoder.decodeHeader(buffer, offset, length, 0);
            if (cod != null) {
                String subject = cod.getSubject();
                _sns.passMsgToAllSubjectSubscribers(subject, subscribers -> decodeAndNotify(cod, false, subject, subscribers));
                cod.setObj(null);
            }
        }
    }

    private void decodeAndNotify(AeronCoder cod, boolean accumulate, String subject, List<SnSHandler> handlers) {
        if (handlers != null && !handlers.isEmpty()) {
            Obj obj = _objCoder.acquireObj(cod);
            if (obj == null) return;
            PubType pubType = cod.getPubType();

            int keysRead = 0;
            int bodyRead = 0;
            boolean reUse = true;
            for (int j = 0; j < handlers.size(); j++) {
                SnSHandler handler = handlers.get(j);
                boolean notify = false;

                if (pubType == PubType.PUB) {
                    WhereNode evalTree = handler.getEvalTree();
                    if (evalTree == null) { // there is no where clause
                        if (keysRead++ == 0) {
                            cod.decodeKeys();
                        }
                        if (bodyRead++ == 0) {
                            cod.decodeBody();
                            cod.decodeAdHocs();
                        }
                        notify = true;
                    } else if (evalTree.whereClauseRequiresOnlyHeaderFields()) {
                        if (log.isDebugEnabled()) log.info("read whereClauseRequiresOnlyHeaderFields {}", obj);
                        if (evalTree.satisfiesWhereClause(obj)) {
                            if (log.isDebugEnabled()) log.info("read satisfiesWhereClause");
                            if (keysRead++ == 0) {
                                cod.decodeKeys();
                            }
                            if (bodyRead++ == 0) {
                                cod.decodeBody();
                                cod.decodeAdHocs();
                            }
                            notify = true;
                        }
                    } else if (evalTree.whereClauseRequiresOnlyHeaderOrKeyFields()) {
                        if (keysRead++ == 0) {
                            cod.decodeKeys();
                        }
                        if (log.isDebugEnabled()) log.info("read whereClauseRequiresOnlyKeyFields {}", obj);
                        if (evalTree.satisfiesWhereClause(obj)) {
                            if (log.isDebugEnabled()) log.info("read satisfiesWhereClause");
                            if (bodyRead++ == 0) {
                                cod.decodeBody();
                                cod.decodeAdHocs();
                            }
                            notify = true;
                        }
                    } else { // where clause requires non key fields
                        if (keysRead++ == 0) {
                            cod.decodeKeys();
                        }
                        if (bodyRead++ == 0) {
                            cod.decodeBody();
                            cod.decodeAdHocs();
                        }
                        if (evalTree.satisfiesWhereClause(obj)) {
                            notify = true;
                        }
                    }
                } else if (pubType == PubType.SNP) {
                    // is it my snap request?
                    long snpReqId = obj.getRequestId();
                    String snpAppId = obj.getRtg().getOriginClient();
                    String myAppId = getAppInfo().getId();
                    if (snpAppId.equals(myAppId) && snpReqId == handler.getSubId()) {
                        if (log.isDebugEnabled()) log.info("Not passing MY snap request back to me => {}", obj);
                        continue;
                    }

                    if (keysRead++ == 0) {
                        cod.decodeKeys();
                    }
                    if (bodyRead++ == 0) {
                        cod.decodeBody();
                        cod.decodeAdHocs();
                    }
                    notify = true;
                } else { // SNP_BEGIN || SNP_END || SNP_MSG || SNP_TIMEOUT || SNP_HWM
                    // this message is guaranteed to be for this component (appId), see
                    // AeronObjCoder.decodeHeader
                    // is this SNP not for this subscription?
                    long reqId = obj.getRequestId();
                    if (handler.getSubId() != reqId) {
                        if (log.isDebugEnabled()) log.info("Not my SNP message {}", reqId);
                        continue;
                    }
                    if (keysRead++ == 0) {
                        cod.decodeKeys();
                    }
                    if (bodyRead++ == 0) {
                        cod.decodeBody();
                        cod.decodeAdHocs();
                    }
                    notify = true;
                }

                if (notify) {
                    if (log.isDebugEnabled()) log.info("decode: read {}", obj);
                    if (accumulate) {
                        _msgAcc.accumulate(handler, obj);
                    } else {
                        try {
                            handler.onMsg(obj);
                        } catch (Exception x) {
                            log.info("", x);
                        }
                    }
                    reUse = false;
                }
            }
            if (reUse) {
                _objCoder.reUseObj(obj);
            } else {
                obj.stopUsing();
            }
        }
    }


    public int publish(Obj obj) throws Exception {
        String subject = obj.getSubject();
        if (subject==null) {
            throw new Exception("Obj has no subject. Dropping... "+obj);
        }
        if (obj instanceof MapObj) {
            ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
            obj.setObjMetaInfo(metaInfo);
        }
        obj.setPubType(PubType.PUB);
        obj.setSerialId(0L);

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        UnsafeBuffer buffer = sharedPubs.getBuffer();
        int len = sharedPubs.getLen();

        Publication pubIpc;
        Publication pubMct;
        ObjPriority pri = obj.getPriority();
        if (pri == ObjPriority.HI_PRI) {
            pubIpc = _pubIpc_0;
            pubMct = _pubMct_0;
        } else if (pri == ObjPriority.CONFL) {
            pubIpc = _pubIpc_1;
            pubMct = _pubMct_1;
        } else {
            pubIpc = _pubIpc_2;
            pubMct = _pubMct_2;
        }
        if (log.isDebugEnabled()) log.info("publish: write stream{} objType{} len={} {}", pubMct.streamId(), obj.getMsgType(), len, obj);

        return offer(pubIpc, pubMct, buffer, len);
    }
    public int serialize(Obj obj) throws Exception {
        String subject = obj.getSubject();
        if (subject==null) {
            throw new Exception("Obj has no subject. Dropping... "+obj);
        }
        if (obj instanceof MapObj) {
            ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
            obj.setObjMetaInfo(metaInfo);
        }
        obj.setPubType(PubType.PUB);
        obj.setSerialId(_idGenerator.nextId());

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        UnsafeBuffer buffer = sharedPubs.getBuffer();
        int len = sharedPubs.getLen();

        Publication pubIpc;
        Publication pubMct;
        ObjPriority pri = obj.getPriority();
        if (pri == ObjPriority.HI_PRI) {
            pubIpc = _pubIpc_4;
            pubMct = _pubMct_4;
        } else if (pri == ObjPriority.CONFL) {
            pubIpc = _pubIpc_5;
            pubMct = _pubMct_5;
        } else {
            pubIpc = _pubIpc_6;
            pubMct = _pubMct_6;
        }
        if (log.isDebugEnabled()) log.info("serialize: write stream{} objType{} len={} {}", pubMct.streamId(), obj.getMsgType(), len, obj);

        return offer(pubIpc, pubMct, buffer, len);
    }
    public int request(SnapRequestObj obj) {
        obj.getRtg().setOriginClient(_myInfo.getId());
        obj.setSerialId(0L);

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        UnsafeBuffer buffer = sharedPubs.getBuffer();
        int len = sharedPubs.getLen();
        if (log.isDebugEnabled()) log.info("request: write len={} {}", len, obj);

        return offer(_pubIpc_3, _pubMct_3, buffer, len);
    }
    public int reply(Obj obj, PubType pubType) {
        if (obj instanceof MapObj) {
            ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(obj.getSubject());
            obj.setObjMetaInfo(metaInfo);
        }
        obj.setPubType(pubType);
        obj.setSerialId(0L);

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        UnsafeBuffer buffer = sharedPubs.getBuffer();
        int len = sharedPubs.getLen();
        if (log.isDebugEnabled()) log.info("reply: write len={} {}", len, obj);

        return offer(_pubIpc_3, _pubMct_3, buffer, len);
    }
    public void loopback(Obj obj) throws Exception {
        obj.setOnLoopback(true);
        obj.setSerialId(0L);
        if (obj instanceof SnapTimeoutObj) {
            obj.getRtg().setOriginClient(_myInfo.getId());
        } else {
            String subject = obj.getSubject();
            if (subject==null) {
                throw new Exception("Obj has no subject. Dropping... "+obj);
            }
            if (obj instanceof MapObj) {
                ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
                obj.setObjMetaInfo(metaInfo);
            }
            obj.setPubType(PubType.PUB);
        }

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        UnsafeBuffer buffer = sharedPubs.getBuffer();
        int len = sharedPubs.getLen();

        _ringBuffer.write(obj.getMsgType(), buffer, 0, len);
    }

    private int offer(Publication pubIpc, Publication pubMct, UnsafeBuffer buffer, int len) {
        if (_useIpcLoopback) { // pubIpc!=null
            if (pubMct.isConnected()) {
                int res = _pubHelper.offer(true, pubIpc, buffer, 0, len);
                return res | _pubHelper.offer(false, pubMct, buffer, 0, len);
            } else {
                return _pubHelper.offer(true, pubIpc, buffer, 0, len);
            }
        } else {
            return _pubHelper.offer(false, pubMct, buffer, 0, len);
        }
    }




    private SimpleHistogram _hIpc_0 = null;
    private SimpleHistogram _hIpc_1 = null;
    private SimpleHistogram _hIpc_2 = null;
    private SimpleHistogram _hIpc_3 = null;
    private SimpleHistogram _hMct_0 = null;
    private SimpleHistogram _hMct_1 = null;
    private SimpleHistogram _hMct_2 = null;
    private SimpleHistogram _hMct_3 = null;

    @Override
    public void setMaxReads(int maxRead0, int maxRead1, int maxRead2, int maxRead3) {
        _maxRead_0 = maxRead0;
        _maxRead_1 = maxRead1;
        _maxRead_2 = maxRead2;
        _maxRead_3 = maxRead3;
    }

    @Override
    public void resetStats() {
        _hIpc_0 = new SimpleHistogram(_maxRead_0);
        _hIpc_1 = new SimpleHistogram(_maxRead_1);
        _hIpc_2 = new SimpleHistogram(_maxRead_2);
        _hIpc_3 = new SimpleHistogram(_maxRead_3);
        _hMct_0 = new SimpleHistogram(_maxRead_0);
        _hMct_1 = new SimpleHistogram(_maxRead_1);
        _hMct_2 = new SimpleHistogram(_maxRead_2);
        _hMct_3 = new SimpleHistogram(_maxRead_3);
    }
    @Override
    public void logStats() {
        log.info("ipc0 {}", _hIpc_0);
        log.info("ipc1 {}", _hIpc_1);
        log.info("ipc2 {}", _hIpc_2);
        log.info("ipc3 {}", _hIpc_3);
        log.info("mct0 {}", _hMct_0);
        log.info("mct1 {}", _hMct_1);
        log.info("mct2 {}", _hMct_2);
        log.info("mct3 {}", _hMct_3);
    }
}
