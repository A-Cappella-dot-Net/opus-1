package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_MESSAGE;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_ExecutionReport;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataRequestReject;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataSnapshot;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelReject;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_SecurityList;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_UserResponse;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_AvgPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ContractMultiplier;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CouponRate;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CumQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CxlRejReason;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CxlRejResponseTo;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ExecID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ExecType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ImbalanceQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastFragment;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LeavesQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDBook;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDBookPhase;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntryPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntrySize;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntryType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MatchedQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MaturityDate;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinPriceIncrement;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MinQtyIncrement;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_NoMDEntries;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_NoRelatedSym;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdRejReason;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdStatus;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrigClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Price;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_QuoteCondition;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityRequestResult;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Side;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Symbol;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Text;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TimeInForce;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TradeCondition;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TransactTime;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserStatus;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserStatusText;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Username;
import static net.a_cappella.cembalo.generated.FixConstants.Val_LastFragment_Last;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Bid;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_ClosingPrice;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Imbalance;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Offer;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_OpeningPrice;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Quote;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityRequestResult_ValidRequest;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SubscriptionRequestType_SnapshotAndSubscribe;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TradeCondition_ImbalanceMoreBuyers;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TradeCondition_ImbalanceMoreSellers;
import static net.a_cappella.cembalo.constants.MktStatus.CLOSED;
import static net.a_cappella.cembalo.constants.MktStatus.OPEN;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.msg.MsgCoder;
import net.a_cappella.continuo.socket.BaseClientPipe;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.InstrPhase;
import net.a_cappella.cembalo.constants.InstrStatus;
import net.a_cappella.cembalo.constants.MktStatus;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;
import net.a_cappella.cembalo.constants.UserStatus;
import net.a_cappella.cembalo.fix.FixFields;
import net.a_cappella.cembalo.fix.FixMessage;
import net.a_cappella.cembalo.fix.FixRepeatingGroup;
import net.a_cappella.cembalo.generator.Dictionary;

public class ExchangeClient {
    private static final Logger log = LoggerFactory.getLogger(ExchangeClient.class);

    public AppInfo _myInfo;
    public ConnInfo _sinkInfo;

    protected MsgCoder _coder;
    protected ClientPipe _pipe;

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
    private int _maxLevels = 5;
    public void setMaxLevels(int maxLevels) {
        _maxLevels = maxLevels;
    }
    private long _requestID = 0L;
    private String nextRequestID() {
        return _myInfo.getId()+"-"+(_requestID++);
    }

    private volatile boolean _handleMarketData;
    public void setHandleMarketData(boolean handleMarketData) {
        _handleMarketData = handleMarketData;
    }

    private IExchangeClientListener _listener;
    public void setListener(IExchangeClientListener listener) {
        _listener = listener;
    }


    public ExchangeClient(MsgCoder coder, String connInfoStr, Dictionary dictionary) {
        _coder = coder;
        _myInfo = new AppInfo(connInfoStr);
        _sinkInfo = new ConnInfo(connInfoStr);
        FixFields.setDictionary(dictionary);
    }

    public void start() {
        _pipe = new ClientPipe(_coder, _myInfo, _sinkInfo, _inBufferSize, _outBufferSize);
        _pipe.setConnectionTimeoutMicros(_connectionTimeoutMicros);
        _pipe.startPipe();
        ShutdownHook.registerShutdownAction(() -> stop());
    }

    public void stop() {
        if (_pipe != null) _pipe.stopPipe();

        log.info("--------");
        ObjectManager.getInstance().dumpPoolStats();
        log.info("========");
    }

    public void onConnect() {
        if (_handleMarketData) {
            sendSecurityListRequest();
        } else {
            marketStatus(OPEN);
        }
    }
    private void sendSecurityListRequest() {
//		log.info("sending SecurityListRequest");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.securityListRequest(nextRequestID());
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }


    public void onDisconnect() {
        marketStatus(CLOSED);
    }

    public void marketStatus(MktStatus marketStatus) {
        log.info("marketStatus => "+marketStatus);
    }

    public void onCompleteSecurityList() {
        marketStatus(OPEN);
        sendMarketDataRequest(Val_SubscriptionRequestType_SnapshotAndSubscribe);
    }
    private void sendMarketDataRequest(char subscriptionRequestType) {
//		log.info("sending MarketDataRequest");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.marketDataRequest(nextRequestID(), subscriptionRequestType, _maxLevels);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }




    public void login(String uid, String pwd) {
//		log.info("logging in as '"+uid+"'");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.loginRequest(nextRequestID(), uid, pwd);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }

    public void logout(String uid, String pwd) {
//		log.info("logging out as '"+uid+"'");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.logoutRequest(nextRequestID(), uid, pwd);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }

    public void sendNewOrderSingle(String uid, String clOrdID, String symbol, OrdType ordType, TimeInForce tif, Side side, double px, double qtyShown, double qty) {
//		log.info("sending NOS("+uid+","+clOrdID+","+symbol+","+tif+","+side+","+px+","+qtyShown+","+qty+")");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.newOrderSingle(uid, clOrdID, symbol, ordType, tif, side, px, qtyShown, qty);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }

    public void sendOrderCancelRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, Side side, double qty) {
//		log.info("sending OCR("+uid+","+ecnOrdId+","+clOrdId+","+origClOrdId+","+symbol+","+side+","+qty+")");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.orderCancelRequest(uid, ecnOrdId, clOrdId, origClOrdId, symbol, side, qty);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }

    public void sendOrderCancelReplaceRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, double px, double qtyShown, double qty, OrdType ordType, TimeInForce tif, Side side) {
//		log.info("sending OCRR("+uid+","+ecnOrdId+","+clOrdId+","+origClOrdId+","+symbol+","+px+","+qtyShown+","+qty+","+tif+","+side+")");
        FixMessage fixMessage = null;
        try {
            fixMessage = ObjectManager.getInstance().acquire(TYPE_FIX_MESSAGE);
            fixMessage.orderCancelReplaceRequest(uid, ecnOrdId, clOrdId, origClOrdId, symbol, px, qtyShown, qty, ordType, tif, side);
            if (log.isDebugEnabled()) log.info("sending "+fixMessage);
            _pipe.sendMsg(fixMessage);
        } catch (Exception e) {
            log.error("", e);
        } finally {
            if (fixMessage!=null) fixMessage.stopUsing();
        }
    }







    public class ClientPipe extends BaseClientPipe {
        private final MarketDataSnapshot _mds = new MarketDataSnapshot(_maxLevels);
        private final InstrumentStatus _is = new InstrumentStatus();
        private final Imbalance _imb = new Imbalance();

        public ClientPipe(MsgCoder coder, AppInfo myInfo, ConnInfo sinkInfo, int inBufferSize, int outBufferSize) {
            super(coder, myInfo, sinkInfo, inBufferSize, outBufferSize, null, "ExchangeClient");
        }

        @Override
        public void onDisconnect() {
            ExchangeClient.this.onDisconnect();
        }

        @Override
        public void onRegistrationResponse() {
            ExchangeClient.this.onConnect();
        }

        @Override
        public void onMsg(Msg msg) {
            if (msg.getMsgType() == TYPE_FIX_MESSAGE) {
                FixMessage fixMessage = (FixMessage) msg;
                if (log.isDebugEnabled()) log.info("received "+fixMessage);

                String fixMsgType = fixMessage.getFixMsgType();
                switch (fixMsgType) {
                    case MsgType_SecurityList:
                        onSecurityList(fixMessage);
                        break;
                    case MsgType_MarketDataRequestReject:
                        onMarketDataRequestReject(fixMessage);
                        break;
                    case MsgType_MarketDataSnapshot:
                        onMarketDataSnapshot(fixMessage);
                        break;
                    case MsgType_UserResponse:
                        onUserResponse(fixMessage);
                        break;
                    case MsgType_ExecutionReport:
                        onExecutionReport(fixMessage);
                        break;
                    case MsgType_OrderCancelReject:
                        onOrderCancelReject(fixMessage);
                        break;
                    default:
                        log.warn("Not handling FIX message "+fixMessage);
                        break;
                }
            } else {
                log.warn("Not handling unexpected message "+msg);
            }
        }

        private void onSecurityList(FixMessage fixMessage) {
            FixFields fields = fixMessage.getFields();
            if (fields.getInt(Tag_SecurityRequestResult)==Val_SecurityRequestResult_ValidRequest) {
                onInstruments(fields._repeatingGroups.get(Tag_NoRelatedSym));
                if (fields.getChar(Tag_LastFragment)==Val_LastFragment_Last) {
                    ExchangeClient.this.onCompleteSecurityList();
                }
            } else {
                log.error("SecurityRequestResult => InvalidRequest");
            }
        }
        private void onInstruments(FixRepeatingGroup fixRepeatingGroup) {
            for (int i=0; i<fixRepeatingGroup._elements.size(); i++) {
                FixFields instrument = fixRepeatingGroup._elements.get(i);
                String securityID = instrument.getString(Tag_SecurityID);
                String symbol = instrument.getString(Tag_Symbol);
                int maturityDate = (int) instrument.getInt(Tag_MaturityDate);
                double couponRate = instrument.getFloat(Tag_CouponRate);
                double contractMultiplier = instrument.getFloat(Tag_ContractMultiplier);
                double minPriceIncrement = instrument.getFloat(Tag_MinPriceIncrement);
                double minQty = instrument.getFloat(Tag_MinQty);
                double minQtyIncrement = instrument.getFloat(Tag_MinQtyIncrement);

                _listener.onInstrument(securityID, symbol, maturityDate, couponRate,
                        contractMultiplier, minPriceIncrement, minQty, minQtyIncrement);
            }
        }

        private void onMarketDataRequestReject(FixMessage fixMessage) {
            String marketDataRequestRejectReason = fixMessage.getFields().getString(Tag_Text);
            _listener.onMarketDataRequestReject(marketDataRequestRejectReason);
        }

        private void onMarketDataSnapshot(FixMessage fixMessage) {
            FixFields fields = fixMessage.getFields();

            String securityID = fields.getString(Tag_Symbol);
            long transactTime = Utils.parseMillis(fields.getString(Tag_TransactTime));
            _mds.reset(securityID, transactTime);
            _is.reset(securityID, transactTime);
            _imb.reset(securityID, transactTime);

            int iB = 0;
            int iO = 0;
            FixRepeatingGroup fixRepeatingGroup = fields._repeatingGroups.get(Tag_NoMDEntries);
            int numEntries = fixRepeatingGroup._numElements;
            for (int i=0; i<numEntries; i++) {
                FixFields element = fixRepeatingGroup._elements.get(i);
                char mdEntryType = element.getChar(Tag_MDEntryType);
                switch (mdEntryType) {
                    case Val_MDEntryType_Bid:
                        _mds.setBid(iB, element.getFloat(Tag_MDEntryPx), element.getFloat(Tag_MDEntrySize));
                        iB++;
                        break;
                    case Val_MDEntryType_Offer:
                        _mds.setOffer(iO, element.getFloat(Tag_MDEntryPx), element.getFloat(Tag_MDEntrySize));
                        iO++;
                        break;
                    case Val_MDEntryType_Quote:
                        _is._book = Book.fromFix(element.getChar(Tag_MDBook));
                        _is._status = InstrStatus.fromFix(element.getString(Tag_QuoteCondition));
                        _is._phase = InstrPhase.fromFix(element.getChar(Tag_MDBookPhase));
                        break;
                    case Val_MDEntryType_Imbalance:
                    case Val_MDEntryType_OpeningPrice:
                    case Val_MDEntryType_ClosingPrice:
                        String tradeCondition = element.getString(Tag_TradeCondition);
                        Side side = Val_TradeCondition_ImbalanceMoreBuyers.equals(tradeCondition) ? Side.Buy :
                                Val_TradeCondition_ImbalanceMoreSellers.equals(tradeCondition) ? Side.Sell : Side.None;
                        Book book = Book.fromFix(element.getChar(Tag_MDBook));
                        boolean auction = mdEntryType != Val_MDEntryType_Imbalance;
                        _imb.set(book, auction, side, element.getFloat(Tag_MatchedQty), element.getFloat(Tag_ImbalanceQty), element.getFloat(Tag_MDEntryPx));
                        break;
                }
            }

            if (iB > 0 || iO > 0) {
                _listener.onMarketDataSnapshot(securityID, _mds);
            }
            if (_is.isSet()) {
                _listener.onInstrumentStatus(securityID, _is);
            }
            if (_imb.isPublishable()) {
                _listener.onImbalance(securityID, _imb);
            }
        }

        private void onUserResponse(FixMessage fixMessage) {
            FixFields fields = fixMessage.getFields();
            int userStatus = (int) fields.getInt(Tag_UserStatus);
            String userStatusText = fields.getString(Tag_UserStatusText);
            String username = fields.getString(Tag_Username);
            _listener.onUserResponse(username, UserStatus.fromFix(userStatus), userStatusText);
        }

        private void onExecutionReport(FixMessage fixMessage) {
            FixFields fields = fixMessage.getFields();
            String execId = fields.getString(Tag_ExecID);
            String ecnOrdId = fields.getString(Tag_OrderID);
            String clOrdId = fields.getString(Tag_ClOrdID);
            String origClOrdId = fields.getString(Tag_OrigClOrdID);
            char execType = fields.getChar(Tag_ExecType);
            char ordStatus = fields.getChar(Tag_OrdStatus);
            int ordRejReason = (int) fields.getInt(Tag_OrdRejReason);
            String symbol = fields.getString(Tag_Symbol);
            char side = fields.getChar(Tag_Side);
            double price = fields.getFloat(Tag_Price);
            char ordType = fields.getChar(Tag_OrdType);
            char timeInForce = fields.getChar(Tag_TimeInForce);
            double lastQty = fields.getFloat(Tag_LastQty);
            double lastPx = fields.getFloat(Tag_LastPx);
            double leavesQty = fields.getFloat(Tag_LeavesQty);
            double cumQty = fields.getFloat(Tag_CumQty);
            double avgPx = fields.getFloat(Tag_AvgPx);
            long transactTime = Utils.parseMillis(fields.getString(Tag_TransactTime));
            String text = fields.getString(Tag_Text);

            _listener.onExecutionReport(
                    execId, ecnOrdId, clOrdId, origClOrdId,
                    execType, ordStatus, ordRejReason,
                    symbol, side, price, ordType, timeInForce,
                    lastQty, lastPx, leavesQty, cumQty, avgPx, text,
                    transactTime);
        }

        private void onOrderCancelReject(FixMessage fixMessage) {
            FixFields fields = fixMessage.getFields();
            String execId = fields.getString(Tag_ExecID);
            String ecnOrdId = fields.getString(Tag_OrderID);
            String clOrdId = fields.getString(Tag_ClOrdID);
            String origClOrdId = fields.getString(Tag_OrigClOrdID);
            char ordStatus = fields.getChar(Tag_OrdStatus);
            char cxlRejResponseTo = fields.getChar(Tag_CxlRejResponseTo);
            int cxlRejReason = (int) fields.getInt(Tag_CxlRejReason);
            long transactTime = Utils.parseMillis(fields.getString(Tag_TransactTime));
            String text = fields.getString(Tag_Text);

            _listener.onOrderCancelReject(
                    execId, ecnOrdId, clOrdId, origClOrdId,
                    ordStatus, cxlRejResponseTo, cxlRejReason, text,
                    transactTime);
        }
    }
}
