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

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_MESSAGE;
import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_TIMER_MSG;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataRequestReject;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_NewOrderSingle;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_SecurityList;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_SecurityListRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_UserRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_AggregatedBook;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDReqID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDUpdateType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MarketDepth;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MaxShow;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrigClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Password;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Price;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityListRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityReqID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityRequestResult;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Side;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SubscriptionRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Symbol;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Text;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TimeInForce;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserRequestID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Username;
import static net.a_cappella.cembalo.generated.FixConstants.Val_AggregatedBook_Aggregated;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejReason_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejReason_UnknownOrder;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejResponseTo_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_CxlRejResponseTo_OrderCancelRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Rejected;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDUpdateType_Full;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdRejReason_Other;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdRejReason_UnknownSymbol;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Rejected;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityListRequestType_AllSecurities;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityRequestResult_InvalidRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityRequestResult_ValidRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SubscriptionRequestType_SnapshotAndSubscribe;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserRequestType_LogOffUser;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserRequestType_LogOnUser;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_LoggedIn;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_NotLoggedIn;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserStatus_Other;

import java.io.IOException;
import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import net.a_cappella.cembalo.generator.Dictionary;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.socket.BaseClientPipe;
import net.a_cappella.continuo.socket.BaseServerSink;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;
import net.a_cappella.cembalo.message.TimerMsgs;
import net.a_cappella.cembalo.timer.ITimerEventListener;
import net.a_cappella.cembalo.timer.InternalTimer;
import gnu.trove.map.TObjectIntMap;
import gnu.trove.map.hash.TObjectIntHashMap;

public class ExchangeServer implements ITimerEventListener, IExchangeServer {
    private static final Logger log = LoggerFactory.getLogger(ExchangeServer.class);

    private int _connectionTimeoutMicros = 200;
    public void setConnectionTimeoutMicros(String connectionTimeoutMicros) {
        _connectionTimeoutMicros = Utils.parseAsInt("connectionTimeoutMicros", connectionTimeoutMicros, _connectionTimeoutMicros);
    }

    private int _inBufferSize = 4096;
    public void setInBufferSize(int inBufferSize) {
        _inBufferSize = inBufferSize;
    }
    private int _outBufferSize = 4096;
    public void setOutBufferSize(int outBufferSize) {
        _outBufferSize = outBufferSize;
    }

    protected FixMessage _securityListResultInvalidRequest = new FixMessage(new FixFields());
    {
        _securityListResultInvalidRequest.setFixMsgType(MsgType_SecurityList);
        _securityListResultInvalidRequest.getFields().putInt(Tag_SecurityRequestResult, Val_SecurityRequestResult_InvalidRequest);
    }
    protected FixMessage _marketDataRequestReject = new FixMessage(new FixFields());
    {
        _marketDataRequestReject.setFixMsgType(MsgType_MarketDataRequestReject);
        _marketDataRequestReject.getFields().putString(Tag_Text, "Only SnapshotAndSubscribe request type, Full update type, and Aggregated book are supported.");
    }

    public void setDictionary(Dictionary dictionary) {
        FixFields.setDictionary(dictionary);
    }

    private final ServerSink _sink;
    private final ClientPipe _pipe;

    private final Map<String, Matcher> _matchersBySecurityId = new HashMap<>();
    private final ActiveOrders _activeOrders = new ActiveOrders();

    private final InstrumentsCache _instrumentsCache;
    private final TraderManager _traderManager;

    private final InternalTimer _timer;
    // associates a SelectionKey with the maxDepth received via MDR
    private final TObjectIntMap<SelectionKey> _maxDepthsBySelectionKey = new TObjectIntHashMap<>();

    private final ExchangeServerHelper _helper;

    private final Consumer<Order> _orderCanceler = order -> _matchersBySecurityId.get(order._securityID).cancelOrder(order);

    private final Map<String, List<FixMessage>> _nonDeliveredMessages = new HashMap<>();

    private long _execId = 1_000_000;
    public void setExecId(long execId) {
        _execId = execId;
    }

    private boolean _strictRwt = false;
    public void setStrictRwt(boolean strictRwt) {
        _strictRwt = strictRwt;
    }
    @Override
    public boolean isStrictRwt() {
        return _strictRwt;
    }

    public ExchangeServer(String myInfoStr, MsgCoder coder,
                          InstrumentsCache instrumentsCache, TraderManager traderManager, InternalTimer timer) {
        _instrumentsCache = instrumentsCache;
        _traderManager = traderManager;
        _timer = timer;

        int serverPort = new ConnInfo(myInfoStr).getPort();
        _sink = new ServerSink(coder, serverPort);

        _helper = new ExchangeServerHelper(_sink);

        _pipe = new ClientPipe(coder, new AppInfo("internalTimer"), new ConnInfo(Utils._localhost, serverPort), _inBufferSize, _inBufferSize);
    }

    public void start() {
        ShutdownHook.registerShutdownAction(() -> stop());

        _instrumentsCache.forEach((securityID, instrument) -> {
            _matchersBySecurityId.put(securityID, new Matcher(this, _activeOrders, instrument));
        });

        _sink.startSink();

        _pipe.setConnectionTimeoutMicros(_connectionTimeoutMicros);
        _pipe.startPipe();
        while (!_pipe.isConnected()) Utils.sleep(100);

        _timer.setListener(this);
        _timer.start();
    }

    public void stop() {
        _pipe.stopPipe();

        log.info("--------");
        ObjectManager.getInstance().dumpPoolStats();
        log.info("========");
    }

    @Override
    public void onTimerEvent(TimerMsgs msgs) {
        try {
            _pipe.sendMsg(msgs);
        } catch (IOException e) {
            log.error("", e);
        }
    }

    @Override
    public void sendExecutionReport(final SelectionKey key, String uid,
                                    long orderID, String clOrdID, String origClOrdID, char execType, char ordStatus, int ordRejReason,
                                    String symbol, char side, char ordType, char timeInForce, double price, double qty, double shownQty,
                                    double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text) {
        FixMessage fixMessage = null;
        boolean delivered = true;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.executionReport(uid, ++_execId,
                    orderID, clOrdID, origClOrdID, execType, ordStatus, ordRejReason,
                    symbol, side, ordType, timeInForce, price, qty, shownQty,
                    lastQty, lastPx, leavesQty, cumQty, avgPx, text);

            _sink.sendMsg(key, fixMessage);
        } catch (Exception e) {
            log.error("", e);
            // add the message to the non delivered message list for the user
            _nonDeliveredMessages.computeIfAbsent(uid, u -> new ArrayList<>()).add(fixMessage);
            delivered = false;
        } finally {
            if (fixMessage!=null && delivered) fixMessage.stopUsing();
        }
    }

    @Override
    public void sendOrderCancelReject(final SelectionKey key, String uid,
                                      long orderID, String clOrdID, String origClOrdID, char ordStatus,
                                      char cxlRejResponseTo, int cxlRejReason, String text) {
        FixMessage fixMessage = null;
        boolean delivered = true;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.orderCancelReject(uid, ++_execId, orderID, clOrdID, origClOrdID, ordStatus, cxlRejResponseTo, cxlRejReason, text);

            _sink.sendMsg(key, fixMessage);
        } catch (Exception e) {
            log.error("", e);
            // add the message to the non delivered message list for the user
            _nonDeliveredMessages.computeIfAbsent(uid, u -> new ArrayList<>()).add(fixMessage);
            delivered = false;
        } finally {
            if (fixMessage!=null && delivered) fixMessage.stopUsing();
        }
    }

    private boolean isLoggedIn(final String uid, final SelectionKey key) {
        return _traderManager.isLoggedIn(uid, key);
    }



    public class ServerSink extends BaseServerSink {
        public ServerSink(MsgCoder coder, int port) {
            super(coder, port, null);
            setInBufSize(_inBufferSize);
            setOutBufSize(_outBufferSize);
        }

        public void sendMsg(SelectionKey key, FixMessage fix) {
            super.sendMsg(key, fix);
            if (log.isDebugEnabled()) log.debug("sent "+fix);
        }

        @Override
        public void onClientDisconnect(SelectionKey key) {
            super.onClientDisconnect(key);
            ExchangeServer.this.onClientDisconnect(key);
            _traderManager.disconnect(key);
        }
        @Override
        public void onMsg(SelectionKey key, Msg msg) {
            if (msg.getMsgType() == TYPE_FIX_MESSAGE) {
                FixMessage fix = (FixMessage) msg;
                String fixMsgType = fix.getFixMsgType();
                if (log.isDebugEnabled()) log.debug("received "+fix);
                if (MsgType_SecurityListRequest.equals(fixMsgType)) {
                    handleSecurityListRequest(key, fix);
                } else if (MsgType_MarketDataRequest.equals(fixMsgType)) {
                    handleMarketDataRequest(key, fix);
                } else if (MsgType_UserRequest.equals(fixMsgType)) {
                    handleUserRequest(key, fix);
                } else if (MsgType_NewOrderSingle.equals(fixMsgType)) {
                    handleNewOrderSingle(key, fix);
                } else if (MsgType_OrderCancelRequest.equals(fixMsgType)) {
                    handleOrderCancelRequest(key, fix);
                } else if (MsgType_OrderCancelReplaceRequest.equals(fixMsgType)) {
                    handleOrderCancelReplaceRequest(key, fix);
                } else {
                    log.error("Fix message not handled yet... "+fix);
                }
            } else if (msg.getMsgType() == TYPE_TIMER_MSG) {
                handleTimerMessage((TimerMsgs) msg);
            }
        }

        private void handleSecurityListRequest(final SelectionKey key, final FixMessage req) {
            FixFields reqFields = req.getFields();
            long reqType = reqFields.getInt(Tag_SecurityListRequestType);
            if (reqType==Val_SecurityListRequestType_AllSecurities) {
                _instrumentsCache.forEach(securityList -> {
                    FixFields secFields = securityList.getFields();
                    secFields.putInt(Tag_SecurityRequestResult, Val_SecurityRequestResult_ValidRequest);
                    secFields.putString(Tag_SecurityReqID, reqFields.getString(Tag_SecurityReqID));
                    sendMsg(key, securityList);
                });
            } else {
                _securityListResultInvalidRequest.getFields().putString(Tag_SecurityReqID, reqFields.getString(Tag_SecurityReqID));
                sendMsg(key, _securityListResultInvalidRequest);
            }
        }

        private void handleMarketDataRequest(final SelectionKey key, final FixMessage req) {
            FixFields reqFields = req.getFields();
            String mdReqID = reqFields.getString(Tag_MDReqID);
            char subscriptionRequestType = reqFields.getChar(Tag_SubscriptionRequestType);
            int mdUpdateType = (int) reqFields.getInt(Tag_MDUpdateType);
            char aggregatedBook = reqFields.getChar(Tag_AggregatedBook);
            // TODO may wish to handle un-subscriptions as well
            if (subscriptionRequestType==Val_SubscriptionRequestType_SnapshotAndSubscribe &&
                    mdUpdateType==Val_MDUpdateType_Full &&
                    aggregatedBook==Val_AggregatedBook_Aggregated) {
                int marketDepth = (int) reqFields.getInt(Tag_MarketDepth);
                ExchangeServer.this.setMarketDepth(key, marketDepth);
                ExchangeServer.this.sendInitialMessagesToSubscriber(key, marketDepth);
            } else {
                _marketDataRequestReject.getFields().putString(Tag_MDReqID, mdReqID);
                sendMsg(key, _marketDataRequestReject);
            }
        }

        private void sendUserResponse(final SelectionKey key, String userRequestID, String uid, int userStatus, String text) {
            FixMessage fixMessage = null;
            try {
                fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
                fixMessage.userResponse(userRequestID, uid, userStatus, text);
                sendMsg(key, fixMessage);
            } catch (Exception e) {
                log.error("", e);
            } finally {
                if (fixMessage!=null) fixMessage.stopUsing();
            }
        }

        private void handleUserRequest(final SelectionKey key, final FixMessage req) {
            FixFields reqFields = req.getFields();
            String userRequestID = reqFields.getString(Tag_UserRequestID);
            int userRequestType = (int) reqFields.getInt(Tag_UserRequestType);
            String uid = reqFields.getString(Tag_Username);
            String pwd = reqFields.getString(Tag_Password);

            if (userRequestType==Val_UserRequestType_LogOnUser) {
                LogInOutStatus status = _traderManager.login(uid, pwd, key);
                if (status==LogInOutStatus.LOGIN_INVALID_CREDENTIALS) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_NotLoggedIn, "Invalid credentials");
                } else if (status==LogInOutStatus.LOGIN_NO_ALREADY) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_NotLoggedIn, "Already logged in on a different session");
                } else if (status==LogInOutStatus.LOGIN_YES_ALREADY) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_LoggedIn, "Already logged in");
                } else if (status==LogInOutStatus.LOGIN_YES) {
                    // send all orders from a previous session for this user
                    List<FixMessage> nonDeliveredMessages = _nonDeliveredMessages.remove(uid);
                    if (nonDeliveredMessages != null && !nonDeliveredMessages.isEmpty()) {
                        log.info("re-sending the non delivered messages");
                        nonDeliveredMessages.forEach(fixMessage -> {
                            boolean delivered = true;
                            try {
                                sendMsg(key, fixMessage);
                            } catch (Exception e) {
                                log.error("", e);
                                _nonDeliveredMessages.computeIfAbsent(uid, u -> new ArrayList<>()).add(fixMessage);
                                delivered = false;
                            } finally {
                                if (fixMessage!=null && delivered) fixMessage.stopUsing();
                            }
                        });
                        log.info("done re-sending the non delivered messages");
                    }

                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_LoggedIn, null);
                } else {
                    log.error("Unexpected result "+status);
                }
            } else if (userRequestType==Val_UserRequestType_LogOffUser) {
                LogInOutStatus status = _traderManager.logout(uid, key);
                if (status==LogInOutStatus.LOGOUT_ALREADY) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_NotLoggedIn, "Already logged out");
                } else if (status==LogInOutStatus.LOGOUT_NO_DIFFERENT_CONNECTION) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_NotLoggedIn, "Logged in on a different connection");
                } else if (status==LogInOutStatus.LOGOUT_YES) {
                    sendUserResponse(key, userRequestID, uid, Val_UserStatus_NotLoggedIn, null);
                    ExchangeServer.this.handleUserLogoff(key, uid);
                } else {
                    log.error("Unexpected result "+status);
                }
            } else {
                sendUserResponse(key, userRequestID, uid, Val_UserStatus_Other, "Request NOT handled");
                log.error("Unhandled UserRequest "+req);
            }
        }

        private void handleNewOrderSingle(final SelectionKey key, final FixMessage nos) {
            FixFields nosFields = nos.getFields();
            String uid = nosFields.getString(Tag_Username);
            String clOrdID = nosFields.getString(Tag_ClOrdID);
            String symbol = nosFields.getString(Tag_Symbol);
            char ordType = nosFields.getChar(Tag_OrdType);
            char tif = nosFields.getChar(Tag_TimeInForce);
            char side = nosFields.getChar(Tag_Side);
            double px = nosFields.getFloat(Tag_Price);
            double qtyShown = nosFields.getFloat(Tag_MaxShow);
            double qty = nosFields.getFloat(Tag_OrderQty);
            ExchangeServer.this.handleNewOrderSingle(key, uid, clOrdID, symbol, ordType, tif, side, px, qtyShown, qty);
        }

        private void handleOrderCancelRequest(final SelectionKey key, final FixMessage ocr) {
            FixFields ocrFields = ocr.getFields();
            String uid = ocrFields.getString(Tag_Username);
            String origClOrdID = ocrFields.getString(Tag_OrigClOrdID);
            long orderID = ocrFields.getInt(Tag_OrderID);
            String clOrdID = ocrFields.getString(Tag_ClOrdID);
            String symbol = ocrFields.getString(Tag_Symbol);
            char side = ocrFields.getChar(Tag_Side);
            double qty = ocrFields.getFloat(Tag_OrderQty);
            ExchangeServer.this.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, symbol, side, qty);
        }

        private void handleOrderCancelReplaceRequest(final SelectionKey key, final FixMessage ocrr) {
            FixFields ocrrFields = ocrr.getFields();
            String uid = ocrrFields.getString(Tag_Username);
            String origClOrdID = ocrrFields.getString(Tag_OrigClOrdID);
            long orderID = ocrrFields.getInt(Tag_OrderID);
            String clOrdID = ocrrFields.getString(Tag_ClOrdID);
            String symbol = ocrrFields.getString(Tag_Symbol);
            char ordType = ocrrFields.getChar(Tag_OrdType);
            char side = ocrrFields.getChar(Tag_Side);
            char tif = ocrrFields.getChar(Tag_TimeInForce);
            double px = ocrrFields.getFloat(Tag_Price);
            double qtyShown = ocrrFields.getFloat(Tag_MaxShow);
            double qty = ocrrFields.getFloat(Tag_OrderQty);
            ExchangeServer.this.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, symbol, px, qtyShown, qty, ordType, side, tif);
        }

        private void handleTimerMessage(TimerMsgs msg) {
            ExchangeServer.this.handleTimerMessage(msg);
        }
    }

    private static class ClientPipe extends BaseClientPipe {
        public ClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, int inBufferSize, int outBufferSize) {
            super(coder, myInfo, sinkInfo, inBufferSize, outBufferSize, null, "ExchangeServer");
        }
    }


    public static void main(String args[]) {
        String springFile = "app-spring.xml";
        if (args.length>=1) {
            springFile = args[0];
        }
        try (ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext(springFile)) {
        } catch (Exception x) {
            x.printStackTrace();
        }
    }







    public void onClientDisconnect(SelectionKey key) { // called on the read thread
        _activeOrders.handleClientDisconnect(key, _orderCanceler);
        _maxDepthsBySelectionKey.remove(key);
    }

    public void handleUserLogoff(final SelectionKey key, final String uid) {
        _activeOrders.handleUserLogoff(key, uid, _orderCanceler);
    }

    public void setMarketDepth(SelectionKey key, int marketDepth) {
        _maxDepthsBySelectionKey.put(key, marketDepth);
    }

    public void sendInitialMessagesToSubscriber(SelectionKey key, int marketDepth) {
        _matchersBySecurityId.forEach(_helper.getSendInitialMessages(key, marketDepth));
    }

    public void sendMdsToAllSubscribers(MarketDataSnapshot mds) {
        FixMessage fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
        _maxDepthsBySelectionKey.forEachEntry(_helper.getSendMarketDataSnapshot(fixMessage, mds));
        fixMessage.stopUsing();
    }
    public void sendInstrStatusToAllSubscribers(InstrumentStatus status) {
        FixMessage fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
        _maxDepthsBySelectionKey.forEachEntry(_helper.getSendInstrumentStatus(fixMessage, status));
        fixMessage.stopUsing();
    }
    public void sendImbalanceToAllSubscribers(Imbalance imbalance) {
        FixMessage fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
        _maxDepthsBySelectionKey.forEachEntry(_helper.getSendImbalance(fixMessage, imbalance));
        fixMessage.stopUsing();
    }




    public void handleNewOrderSingle(final SelectionKey key, String uid, String clOrdID, String securityID, char ordType, char tif, char side, double px, double qtyShown, double qty) {
        if (!isLoggedIn(uid, key)) {
            sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_Other,
                    securityID, side, ordType, tif, px, qty, qtyShown, Double.NaN, Double.NaN, qty, 0.0, Double.NaN, "Trader not logged in");
            return;
        }
        Matcher matcher = _matchersBySecurityId.get(securityID);
        if (matcher==null) {
            sendExecutionReport(key, uid, 0, clOrdID, null, Val_ExecType_Rejected, Val_OrdStatus_Rejected, Val_OrdRejReason_UnknownSymbol,
                    securityID, side, ordType, tif, px, qty, qtyShown, Double.NaN, Double.NaN, qty, 0.0, Double.NaN, "Unknown Symbol");
            return;
        }

        matcher.handleNewOrderSingle(key, uid, clOrdID, securityID, ordType, tif, side, px, qtyShown, qty);
    }

    public void handleOrderCancelRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, char side, double qty) {
        if (!isLoggedIn(uid, key)) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelRequest, Val_CxlRejReason_Other,
                    "Trader not logged in");
            return;
        }
        Order order = _activeOrders.get(orderID);
        if (order==null || !uid.equals(order._user)) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelRequest, Val_CxlRejReason_UnknownOrder,
                    (order==null)?"Order not in OrderBook":"Trader order not in OrderBook");
            return;
        }
        String invalidErr = order.validate(securityID, side);
        if (invalidErr != null) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelRequest, Val_CxlRejReason_Other,
                    invalidErr);
            return;
        }

        Matcher matcher = _matchersBySecurityId.get(securityID);
        matcher.handleOrderCancelRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, side, qty, order);
    }

    public void handleOrderCancelReplaceRequest(final SelectionKey key, String uid, String origClOrdID, long orderID, String clOrdID, String securityID, double px, double qtyShown, double qty, char ordType, char side, char tif) {
        if (!isLoggedIn(uid, key)) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_Other,
                    "Trader not logged in");
            return;
        }
        Order order = _activeOrders.get(orderID);
        if (order==null || !uid.equals(order._user)) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_UnknownOrder,
                    (order==null)?"Order not in OrderBook":"Trader order not in OrderBook");
            return;
        }
        String invalidErr = order.validate(securityID, side);
        if (invalidErr != null) {
            sendOrderCancelReject(key, uid, orderID, clOrdID, origClOrdID,
                    Val_OrdStatus_Rejected, Val_CxlRejResponseTo_OrderCancelReplaceRequest, Val_CxlRejReason_Other,
                    invalidErr);
            return;
        }

        Matcher matcher = _matchersBySecurityId.get(securityID);
        matcher.handleOrderCancelReplaceRequest(key, uid, origClOrdID, orderID, clOrdID, securityID, px, qtyShown, qty, ordType, side, tif, order);

    }

    public void handleTimerMessage(TimerMsgs msg) {
        _matchersBySecurityId.forEach((securityID, matcher) -> {
            matcher.handleTimerMessage(msg);
        });
    }

}
