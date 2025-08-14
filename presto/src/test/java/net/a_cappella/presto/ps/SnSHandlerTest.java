package net.a_cappella.presto.ps;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.obj.SnapTimeoutObj;
import net.a_cappella.presto.ps.sql.SqlParserResult;

import net.a_cappella.presto.ps.SnSManager.SnSOpType;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.AdditionalAnswers;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

import static org.mockito.Mockito.*;

public class SnSHandlerTest {
    private static final Logger log = LoggerFactory.getLogger(SnSHandlerTest.class);

    private static final long SNS_SUB_ID = 1L;
    private static final long P_SUB_ID = 2L;
    private static final long S_SUB_ID = 3L;

    private static final long FROM_INIT_MILLIS = 200;
    private static final long FROM_LATEST_MILLIS = 200;
    private static final long TOLERANCE_MILLIS = 300;

    public ScheduledExecutorService _scheduler;
    private final SnSManager _sns = mock(SnSManager.class);
    private final SqlParserResult _sqlComps = mock(SqlParserResult.class);
    private final PubSubClient _client = mock(PubSubClient.class);
    private final ISubscriptionListener _listener = mock(ISubscriptionListener.class, withSettings().extraInterfaces(ISnapCompleteListener.class, ISnapRequestListener.class));
    private final SnSHandler _sHandler = new SnSHandler(_client, _sns, _sqlComps, S_SUB_ID, SnSOpType.SUBSCRIBE, _listener);
    private final SnSHandler _pHandler = new SnSHandler(_client, _sns, _sqlComps, P_SUB_ID, SnSOpType.SNAP, _listener);
    private final SnSHandler _snsHandler = new SnSHandler(_client, _sns, _sqlComps, SNS_SUB_ID, SnSOpType.SNAP_SUBSCRIBE, _listener);

    MsgInstantiator _pingInstantiator = null;
    MsgInstantiator _snapRequestInstantiator = null;
    {
        try {
            _pingInstantiator = new MsgInstantiator(PingObj.class.getName(), (String) null, null);
            _snapRequestInstantiator = new MsgInstantiator(SnapRequestObj.class.getName(), (String) null, null);
        } catch (Exception x) {
            log.error("", x);
        }
    }

    private final SnapRequestObj _snapRequestObj = newSnapRequest("ping");
    private final SnapTimeoutObj _snapTimeoutObj = new SnapTimeoutObj();

    private final PingObj _ping1a_RPL = newPing(1, -1, PubType.SNP_MSG);
    private final PingObj _ping1b_RPL = newPing(1, -2, PubType.SNP_MSG);
    private final PingObj _ping1c_RPL = newPing(1, -3, PubType.SNP_MSG);
    private final PingObj _ping10_RPL = newPing(1, 0, PubType.SNP_MSG);
    private final PingObj _ping11_PUB = newPing(1, 1, PubType.PUB);
    private final PingObj _ping12_PUB = newPing(1, 2, PubType.PUB);
    private final PingObj _ping13_PUB = newPing(1, 3, PubType.PUB);

    private final PingObj _ping20_RPL = newPing(2, 0, PubType.SNP_MSG);
    private final PingObj _ping21_PUB = newPing(2, 1, PubType.PUB);
    private final PingObj _ping22_PUB = newPing(2, 2, PubType.PUB);
    private final PingObj _ping23_PUB = newPing(2, 3, PubType.PUB);

    private final PingObj _ping30_RPL = newPing(3, 0, PubType.SNP_MSG);
    private final PingObj _ping31_PUB = newPing(3, 1, PubType.PUB);
    private final PingObj _ping32_PUB = newPing(3, 2, PubType.PUB);
    private final PingObj _ping33_PUB = newPing(3, 3, PubType.PUB);

    private final PingObj _ping_SNP_BEGIN = newPing(0, 0, PubType.SNP_BEGIN);
    private final PingObj _ping_SNP_END = newPing(0, 0, PubType.SNP_END);

    private SnapRequestObj newSnapRequest(String subject) {
        SnapRequestObj ping = _snapRequestInstantiator.newInstance();
        ping.set(subject, "select * from "+subject, 1);
        return ping;
    }

    private PingObj newPing(int id, long payload, PubType pubType) {
        PingObj ping = _pingInstantiator.newInstance();
        ping.setId(id);
        ping.setPayload(payload);
        ping.setPubType(pubType);
        return ping;
    }

    private boolean sameSnp(SnapRequestObj o1, SnapRequestObj o2) {
        return o1.getSubject() == o2.getSubject() && o1.getSql() == o2.getSql() && o1.getPubType() == o2.getPubType();
    }

    private boolean samePing(PingObj o1, PingObj o2) {
        return o1.getId() == o2.getId() && o1.getPayload() == o2.getPayload() && o1.getPubType() == o2.getPubType();
    }

    @BeforeEach
    public void before() {
        _scheduler = Executors.newSingleThreadScheduledExecutor();
    }

    @AfterEach
    public void after() {
        _scheduler.shutdownNow();
    }

    @Test
    public void snapRequestObjCallsBackOnSnapMessage() {
        _snsHandler.onMsg(_snapRequestObj);
        verify((ISnapRequestListener) _listener).onSnapRequest(argThat((SnapRequestObj q) -> sameSnp(q, _snapRequestObj)), eq(SNS_SUB_ID));
        verify(_listener, never()).onSubscriptionMessage(any(PingObj.class), anyLong());

        _sHandler.onMsg(_snapRequestObj);
        verify((ISnapRequestListener) _listener).onSnapRequest(argThat((SnapRequestObj q) -> sameSnp(q, _snapRequestObj)), eq(S_SUB_ID));
        verify(_listener, never()).onSubscriptionMessage(any(PingObj.class), anyLong());

        _pHandler.onMsg(_snapRequestObj);
        verify((ISnapRequestListener) _listener, never()).onSnapRequest(any(SnapRequestObj.class), eq(P_SUB_ID));
        verify(_listener, never()).onSubscriptionMessage(any(PingObj.class), anyLong());
    }

    @Test
    public void snapServiceUnAvailableUseCases() throws Exception {
        Mockito.when(_sns.getScheduler()).thenReturn(_scheduler);

        Mockito.doAnswer(AdditionalAnswers.answerVoid(invocation -> {
            _snapTimeoutObj.set("", 0, System.nanoTime());
            _snsHandler.onMsg(_snapTimeoutObj);
        })).when(_client).loopback(isA(Obj.class));
        _snsHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, new KeyBasedMergeManager());
        verify((ISnapCompleteListener)_listener, Mockito.timeout(FROM_INIT_MILLIS+TOLERANCE_MILLIS)).onSnapComplete(eq(SNS_SUB_ID));
        _snsHandler.shutdown();

        Mockito.doAnswer(AdditionalAnswers.answerVoid(invocation -> {
            _snapTimeoutObj.set("", 0, System.nanoTime());
            _pHandler.onMsg(_snapTimeoutObj);
        })).when(_client).loopback(isA(Obj.class));
        _pHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, null);
        verify((ISnapCompleteListener)_listener, Mockito.timeout(FROM_INIT_MILLIS+TOLERANCE_MILLIS)).onSnapComplete(eq(P_SUB_ID));
        _pHandler.shutdown();
    }

    @Test
    public void snapServiceSendsIncompleteSequence() throws Exception {
        Mockito.when(_sns.getScheduler()).thenReturn(_scheduler);

        Mockito.doAnswer(AdditionalAnswers.answerVoid(invocation -> {
            _snapTimeoutObj.set("", 0, System.nanoTime());
            _snsHandler.onMsg(_snapTimeoutObj);
        })).when(_client).loopback(isA(Obj.class));
        _snsHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, new KeyBasedMergeManager());
        _snsHandler.onMsg(_ping10_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping10_RPL)), eq(SNS_SUB_ID));
        verify((ISnapCompleteListener)_listener, Mockito.timeout(FROM_LATEST_MILLIS+TOLERANCE_MILLIS)).onSnapComplete(eq(SNS_SUB_ID));
        _snsHandler.shutdown();

        Mockito.doAnswer(AdditionalAnswers.answerVoid(invocation -> {
            _snapTimeoutObj.set("", 0, System.nanoTime());
            _pHandler.onMsg(_snapTimeoutObj);
        })).when(_client).loopback(isA(Obj.class));
        _pHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, null);
        _pHandler.onMsg(_ping10_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping10_RPL)), eq(P_SUB_ID));
        verify((ISnapCompleteListener)_listener, Mockito.timeout(FROM_LATEST_MILLIS+TOLERANCE_MILLIS)).onSnapComplete(eq(P_SUB_ID));
        _pHandler.shutdown();
    }

    @Test
    public void snapServiceAvailableUseCases() {
        Mockito.when(_sns.getScheduler()).thenReturn(_scheduler);
        _snsHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, new KeyBasedMergeManager());

        _snsHandler.onMsg(_ping_SNP_BEGIN);
        verify(_listener, never()).onSubscriptionMessage(any(SnapRequestObj.class), anyLong());

        // RPL is received first and is passed on
        _snsHandler.onMsg(_ping10_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping10_RPL)), eq(SNS_SUB_ID));
        // all PUBs received after a RPL will be passed on
        _snsHandler.onMsg(_ping11_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping11_PUB)), eq(SNS_SUB_ID));
        _snsHandler.onMsg(_ping12_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping12_PUB)), eq(SNS_SUB_ID));
        _snsHandler.onMsg(_ping13_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping13_PUB)), eq(SNS_SUB_ID));

        // PUB is received first and is passed on
        _snsHandler.onMsg(_ping21_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping21_PUB)), eq(SNS_SUB_ID));
        // but a RPL received after a PUB will be dropped
        _snsHandler.onMsg(_ping20_RPL);
        verify(_listener, never()).onSubscriptionMessage(any(SnapRequestObj.class), eq(SNS_SUB_ID));
        // all subsequent PUBs will be passed on
        _snsHandler.onMsg(_ping22_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping22_PUB)), eq(SNS_SUB_ID));
        _snsHandler.onMsg(_ping23_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping23_PUB)), eq(SNS_SUB_ID));

        // two PUBs are received first and both are passed on
        _snsHandler.onMsg(_ping31_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping31_PUB)), eq(SNS_SUB_ID));
        _snsHandler.onMsg(_ping32_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping32_PUB)), eq(SNS_SUB_ID));
        // but a RPL received after will be dropped
        _snsHandler.onMsg(_ping30_RPL);
        verify(_listener, never()).onSubscriptionMessage(any(SnapRequestObj.class), eq(SNS_SUB_ID));
        // all subsequent PUBs will be passed on
        _snsHandler.onMsg(_ping33_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping33_PUB)), eq(SNS_SUB_ID));

        _snsHandler.onMsg(_ping_SNP_END);
        verify((ISnapCompleteListener)_listener).onSnapComplete(anyLong());

        _snsHandler.shutdown();
    }

    @Test
    public void cornerCases() {
        // TODO test corner case when object has a null key. Is this even possible?

        Mockito.when(_sns.getScheduler()).thenReturn(_scheduler);
        _snsHandler.initiateSnap(FROM_INIT_MILLIS, FROM_LATEST_MILLIS, new KeyBasedMergeManager());

        _snsHandler.onMsg(_ping_SNP_BEGIN);
        verify(_listener, never()).onSubscriptionMessage(any(SnapRequestObj.class), anyLong());

        // snap service should return only one record for a key
        _snsHandler.onMsg(_ping1a_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping1a_RPL)), eq(SNS_SUB_ID));
        // but if it does not, 'correctOrder' will allow the second record as well
        _snsHandler.onMsg(_ping1b_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping1b_RPL)), eq(SNS_SUB_ID));
        // and the third record as well
        _snsHandler.onMsg(_ping1c_RPL);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping1c_RPL)), eq(SNS_SUB_ID));
        // a PUB received after all these RPL will be passed on
        _snsHandler.onMsg(_ping11_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping11_PUB)), eq(SNS_SUB_ID));
        // but another RPL is not passed after the PUB
        _snsHandler.onMsg(_ping10_RPL);
        verify(_listener, never()).onSubscriptionMessage(any(SnapRequestObj.class), eq(SNS_SUB_ID));

        _snsHandler.onMsg(_ping_SNP_END);
        verify((ISnapCompleteListener)_listener).onSnapComplete(anyLong());

        _snsHandler.shutdown();
    }

    @Test
    public void pubMsgCallsBackOnSubscriptionMessageQnS() {
        _snsHandler.onMsg(_ping11_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping11_PUB)), eq(SNS_SUB_ID));
        verify((ISnapRequestListener) _listener, never()).onSnapRequest(any(SnapRequestObj.class), anyLong());
    }

    @Test
    public void pubMsgCallsBackOnSubscriptionMessageS() {
        _sHandler.onMsg(_ping11_PUB);
        verify(_listener).onSubscriptionMessage(argThat((PingObj p) -> samePing(p, _ping11_PUB)), eq(S_SUB_ID));
        verify((ISnapRequestListener) _listener, never()).onSnapRequest(any(SnapRequestObj.class), anyLong());
    }

    @Test
    public void pubMsgIsDroppedForSnapOnly() {
        _pHandler.onMsg(_ping11_PUB);
        verify(_listener, never()).onSubscriptionMessage(any(PingObj.class), anyLong());
        verify((ISnapRequestListener) _listener, never()).onSnapRequest(any(SnapRequestObj.class), anyLong());
    }
}
