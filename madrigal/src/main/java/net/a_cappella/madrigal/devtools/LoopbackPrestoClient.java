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

package net.a_cappella.madrigal.devtools;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.ft.collective.IFtMemberListener;
import net.a_cappella.presto.ft.collective.IFtMonitorListener;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.obj.SnapTimeoutObj;
import net.a_cappella.presto.ps.*;
import net.a_cappella.presto.ps.sql.SqlParserResult;

import net.a_cappella.presto.ps.sql.WhereNode;
import org.agrona.MutableDirectBuffer;
import org.agrona.concurrent.MessageHandler;
import org.agrona.concurrent.UnsafeBuffer;
import org.agrona.concurrent.ringbuffer.OneToOneRingBuffer;
import org.agrona.concurrent.ringbuffer.RingBuffer;
import org.agrona.concurrent.ringbuffer.RingBufferDescriptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class LoopbackPrestoClient implements PrestoClient {
    private static final Logger log = LoggerFactory.getLogger(LoopbackPrestoClient.class);

    private final AppInfo _myInfo;

    private int _maxRead_4 = Integer.MAX_VALUE;
    public void setMaxRead4(int maxRead) {
        _maxRead_4 = maxRead;
    }

    private final TightLoopThread _tightLoopThread;
    private final SnSManager _sns;
    private final MsgAccumulator _msgAcc = new MsgAccumulator();
    private final AeronObjCoder _objCoder;
    public final PublicationHelper _pubHelper;

    private final MessageHandler _loopbackHandler = new LoopbackMessageHandler();

    private int _ringBufferSizePowerOf2Exponent = 20;
    public void setRingBufferSizePowerOf2Exponent(String ringBufferSizePowerOf2Exponent) {
        _ringBufferSizePowerOf2Exponent = Utils.parseAsInt("ringBufferSizePowerOf2Exponent", ringBufferSizePowerOf2Exponent, _ringBufferSizePowerOf2Exponent);
    }
    private RingBuffer _ringBuffer;

    private Map<Long, ObjGenerator> _generatorsBySubId = new HashMap<>();
    private ObjGenerator _gen;


    public LoopbackPrestoClient(String connInfoStr, TightLoopThread tightLoopThread, PublicationHelper pubHelper, Map<String, String> params) {
        _myInfo = new AppInfo(connInfoStr);

        _tightLoopThread = tightLoopThread;
        _pubHelper = pubHelper;
        _sns = new SnSManager(this, params);
        _objCoder = new AeronObjCoder(_myInfo.getId());
    }

    @Override
    public void waitUntilInitialized() {

    }

    public void start() {
        ShutdownHook.registerShutdownAction(() -> stop());

        int ringBufferSize = (1 << _ringBufferSizePowerOf2Exponent) + RingBufferDescriptor.TRAILER_LENGTH;
        log.info("ringBufferSize=" + ringBufferSize);
        _ringBuffer = new OneToOneRingBuffer(new UnsafeBuffer(ByteBuffer.allocateDirect(ringBufferSize)));
        log.info("ringBuffer capacity=" + _ringBuffer.capacity() + ", maxMsgLength=" + _ringBuffer.maxMsgLength());

        TightLoopSnippet op = new SubscriptionDispatcher();
        _tightLoopThread.add(op);

        _gen = new ObjGenerator(this, 5, 10_000);
    }

    @Override
    public void stop() {
        log.info("Stopping AeronClient");
        _gen.stop();
        _sns.stop();
    }

    @Override
    public AppInfo getAppInfo() {
        return _myInfo;
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
        long subId = _sns.snapSubscribe(sqlComps, subListener);
        _gen.onSubscriptionRequest(sqlComps, subId);
        return subId;
    }

    @Override
    public long snap(String sql, ISubscriptionListener subListener) throws Exception {
        return _sns.snap(sql, subListener);
    }

    @Override
    public long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = _sns.snap(sqlComps, subListener);
        return subId;
    }

    @Override
    public long subscribe(String sql, ISubscriptionListener subListener) throws Exception {
        return _sns.subscribe(sql, subListener);
    }

    @Override
    public long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
        long subId = _sns.subscribe(sqlComps, subListener);
        _gen.onSubscriptionRequest(sqlComps, subId);
        return subId;
    }

    @Override
    public void unsubscribe(long subId) {
        _gen.stop(subId);
        _sns.unsubscribe(subId);
    }

    @Override
    public int publish(Obj obj) throws Exception {
        loopback(obj);
        return 0;
    }

    @Override
    public int serialize(Obj obj) throws Exception {
        loopback(obj);
        return 0;
    }

    @Override
    public int request(SnapRequestObj obj) throws Exception {
        obj.getRtg().setOriginClient(_myInfo.getId());
        obj.setSerialId(0L);

        _gen.onSnapRequest(obj);
        return 0;
    }

    @Override
    public int reply(Obj obj, PubType pubType) throws Exception {
        if (obj instanceof MapObj) {
            ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(obj.getSubject());
            obj.setObjMetaInfo(metaInfo);
        }
        obj.setPubType(pubType);
        obj.setSerialId(0L);

        SharedAeronCoders sharedPubs = _objCoder.encode(obj);
        if (sharedPubs != null) {
            UnsafeBuffer buffer = sharedPubs.getBuffer();
            int len = sharedPubs.getLen();
            if (log.isDebugEnabled()) log.info("reply: write len={} {} {}", len, obj, pubType);

            _ringBuffer.write(obj.getMsgType(), buffer, 0, len);
        }
        return 0;
    }

    @Override
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
        if (sharedPubs != null) {
            UnsafeBuffer buffer = sharedPubs.getBuffer();
            int len = sharedPubs.getLen();

            _ringBuffer.write(obj.getMsgType(), buffer, 0, len);
        }
    }

    @Override
    public long getSeqNo() {
        return 0;
    }

    @Override
    public void setSeqNo(long seqNo) {

    }

    @Override
    public void addSnippet(TightLoopSnippet snippet) {
        _tightLoopThread.add(snippet);
    }

    @Override
    public boolean onTLT() {
        return _tightLoopThread.isCurrentThread();
    }

    @Override
    public void registerFtMemberListener(IFtMemberListener listener) {

    }

    @Override
    public void unregisterFtMemberListener(IFtMemberListener listener) {

    }

    @Override
    public void registerFtMember(String groupName, int instance, int activeGoal) {

    }

    @Override
    public void unregisterFtMember(String groupName, int instance) {

    }

    @Override
    public void registerFtMonitorListener(IFtMonitorListener listener) {

    }

    @Override
    public void unregisterFtMonitorListener(IFtMonitorListener listener) {

    }

    @Override
    public void registerFtMonitor(String groupName) {

    }

    @Override
    public void unregisterFtMonitor(String groupName) {

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

    private class SubscriptionDispatcher implements TightLoopSnippet {

        @Override // TightLoopSnippet
        public int executeSnippet() {

            int fragmentsRead = 0;

            _msgAcc.notifyAndReset();

            if (fragmentsRead == 0) {
                int read4 = _ringBuffer.read(_loopbackHandler, _maxRead_4);
                fragmentsRead += read4;
            }

            return fragmentsRead;
        }
    }

}
