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

package net.a_cappella.cembalo.fix;

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_FIELDS;
import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_MESSAGE;
import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_REPEATING_GROUP;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_ExecutionReport;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_MarketDataSnapshot;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_NewOrderSingle;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelReject;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelReplaceRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_OrderCancelRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_SecurityListRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_UserRequest;
import static net.a_cappella.cembalo.generated.FixConstants.MsgType_UserResponse;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_AggregatedBook;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_AvgPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CumQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CxlRejReason;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_CxlRejResponseTo;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ExecID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ExecType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_ImbalanceQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LastQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_LeavesQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDBook;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDBookPhase;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntryPx;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntrySize;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDEntryType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDReqID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MDUpdateType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MarketDepth;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MatchedQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_MaxShow;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_NoMDEntries;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdRejReason;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdStatus;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrdType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrderQty;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_OrigClOrdID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Password;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Price;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_QuoteCondition;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityListRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SecurityReqID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Side;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_SubscriptionRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Symbol;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Text;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TimeInForce;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TradeCondition;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_TransactTime;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserRequestID;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserRequestType;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserStatus;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_UserStatusText;
import static net.a_cappella.cembalo.generated.FixConstants.Tag_Username;
import static net.a_cappella.cembalo.generated.FixConstants.Val_AggregatedBook_Aggregated;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Bid;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_ClosingPrice;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Imbalance;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Offer;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_OpeningPrice;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDEntryType_Quote;
import static net.a_cappella.cembalo.generated.FixConstants.Val_MDUpdateType_Full;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SecurityListRequestType_AllSecurities;
import static net.a_cappella.cembalo.generated.FixConstants.Val_SubscriptionRequestType_Disable;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TradeCondition_Balanced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TradeCondition_ImbalanceMoreBuyers;
import static net.a_cappella.cembalo.generated.FixConstants.Val_TradeCondition_ImbalanceMoreSellers;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserRequestType_LogOffUser;
import static net.a_cappella.cembalo.generated.FixConstants.Val_UserRequestType_LogOnUser;

import java.nio.ByteBuffer;
import java.time.Instant;

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.beans.Imbalance;
import net.a_cappella.cembalo.beans.InstrumentStatus;
import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.InstrPhase;
import net.a_cappella.cembalo.constants.InstrStatus;
import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;

public class FixMessage extends Msg {
    private static final Logger log = LoggerFactory.getLogger(FixMessage.class);

    private String _fixMsgType;
    private final FixFields _fields;

    public FixMessage() {
        _fields = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
    }

    public FixMessage(FixFields fields) {
        _fields = fields;
    }

    @Override
    public int getMsgType() {
        return TYPE_FIX_MESSAGE;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        putString(buffer, _fixMsgType);
        _fields.encode(buffer);
    }
    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _fixMsgType = getInternedString(buffer);
        _fields.decode(buffer, 0);
        return this;
    }

    @Override
    public void reset() {
        _fixMsgType = null;
        _fields.reset();
    }

    public String getFixMsgType() {
        return _fixMsgType;
    }
    public void setFixMsgType(String fixMsgType) {
        _fixMsgType = fixMsgType;
    }

    public FixFields getFields() {
        return _fields;
    }

    public static final char SOH = 0x01;
    public static final char PIPE = '|';

    @Override
    public String toString() {
        StringBuilder sb = Utils.getThreadLocalStringBuilder();

        sb.append("8=FIX.4.4").append(SOH);
        sb.append("9=");
        int bodyLengthPos = sb.length();
        sb.append(SOH);

        int bodyStart = sb.length();
        sb.append("35=").append(_fixMsgType).append(SOH);
        sb.append("52=").append(Utils.formatMillis(Instant.now().toEpochMilli())).append(SOH);
        _fields.toString(sb);
        int bodyLength = sb.length() - bodyStart;
        sb.insert(bodyLengthPos, bodyLength);
        bodyLength = sb.length();

        int sum = 0;
        for (int i = 0; i<bodyLength; i++) {
            sum += sb.charAt(i);
            if (sb.charAt(i) == SOH) sb.setCharAt(i, PIPE);
        }
        sb.append("10=").append(String.format("%03d", sum % 256)).append(PIPE);

        return sb.toString();
    }

    public void marketDataSnapshot(MarketDataSnapshot mds, int marketDepth) {
        int numBids = Math.min(mds._bidDepth, marketDepth);
        int numOffers = Math.min(mds._offerDepth, marketDepth);
        _fixMsgType = MsgType_MarketDataSnapshot;
        _fields.putString(Tag_Symbol, mds._securityID);
        FixRepeatingGroup fixRepeatingGroup = ObjectManager.getInstance().acquire(TYPE_FIX_REPEATING_GROUP);
        _fields._repeatingGroups.put(Tag_NoMDEntries, fixRepeatingGroup);
        for (int i=0; i<numBids; i++) {
            FixFields fields = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
            fields.putChar(Tag_MDEntryType, Val_MDEntryType_Bid);
            fields.putFloat(Tag_MDEntryPx, mds._bidEntries[i]._price);
            fields.putFloat(Tag_MDEntrySize, mds._bidEntries[i]._size);
            fixRepeatingGroup._elements.add(fields);
        }
        for (int i=0; i<numOffers; i++) {
            FixFields fields = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
            fields.putChar(Tag_MDEntryType, Val_MDEntryType_Offer);
            fields.putFloat(Tag_MDEntryPx, mds._offerEntries[i]._price);
            fields.putFloat(Tag_MDEntrySize, mds._offerEntries[i]._size);
            fixRepeatingGroup._elements.add(fields);
        }
        fixRepeatingGroup._numElements = numBids + numOffers;
        fixRepeatingGroup._tag = Tag_NoMDEntries;
        _fields.putString(Tag_TransactTime, Utils.formatMillis(Instant.now().toEpochMilli()));
    }

    public void instrumentStatus(InstrumentStatus is) {
        _fixMsgType = MsgType_MarketDataSnapshot;
        _fields.putString(Tag_Symbol, is._securityID);
        FixRepeatingGroup fixRepeatingGroup = ObjectManager.getInstance().acquire(TYPE_FIX_REPEATING_GROUP);
        _fields._repeatingGroups.put(Tag_NoMDEntries, fixRepeatingGroup);

        FixFields element = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
        element.putChar(Tag_MDEntryType, Val_MDEntryType_Quote);
        element.putString(Tag_QuoteCondition, InstrStatus.toFix(is._status));
        element.putChar(Tag_MDBook, Book.toFix(is._book));
        element.putChar(Tag_MDBookPhase, InstrPhase.toFix(is._phase));

        fixRepeatingGroup._elements.add(element);
        fixRepeatingGroup._numElements = 1;
        fixRepeatingGroup._tag = Tag_NoMDEntries;

        _fields.putString(Tag_TransactTime, Utils.formatMillis(Instant.now().toEpochMilli()));
    }

    public void imbalance(Imbalance imbalance) {
        _fixMsgType = MsgType_MarketDataSnapshot;
        _fields.putString(Tag_Symbol, imbalance.getSymbol());
        FixRepeatingGroup fixRepeatingGroup = ObjectManager.getInstance().acquire(TYPE_FIX_REPEATING_GROUP);
        _fields._repeatingGroups.put(Tag_NoMDEntries, fixRepeatingGroup);

        FixFields element = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
        element.putChar(Tag_MDEntryType,
                !imbalance.isAuction() ? Val_MDEntryType_Imbalance :
                        imbalance.getBook()==Book.OPEN_BK ? Val_MDEntryType_OpeningPrice : Val_MDEntryType_ClosingPrice);
        element.putString(Tag_TradeCondition,
                imbalance.getSide()==Side.Buy ? Val_TradeCondition_ImbalanceMoreBuyers :
                        imbalance.getSide()==Side.Sell ? Val_TradeCondition_ImbalanceMoreSellers : Val_TradeCondition_Balanced);
        element.putChar(Tag_MDBook, Book.toFix(imbalance.getBook()));
        element.putFloat(Tag_MDEntryPx, imbalance.getPrice());
        element.putFloat(Tag_MatchedQty, imbalance.getMatched());
        element.putFloat(Tag_ImbalanceQty, imbalance.getSurplus());

        fixRepeatingGroup._elements.add(element);
        fixRepeatingGroup._numElements = 1;
        fixRepeatingGroup._tag = Tag_NoMDEntries;

        _fields.putString(Tag_TransactTime, Utils.formatMillis(Instant.now().toEpochMilli()));
    }

    public void executionReport(String uid, long execId,
                                long orderID, String clOrdID, String origClOrdID, char execType, char ordStatus, int ordRejReason,
                                String symbol, char side, char ordType, char timeInForce, double price, double qty, double shownQty,
                                double lastQty, double lastPx, double leavesQty, double cumQty, double avgPx, String text) {
        setFixMsgType(MsgType_ExecutionReport);
        FixFields fields = getFields();
        if (uid!=null) fields.putString(Tag_Username, uid);
        fields.putString(Tag_ExecID, Long.toString(execId));
        if (orderID!=0) fields.putInt(Tag_OrderID, orderID);
        if (clOrdID!=null) fields.putString(Tag_ClOrdID, clOrdID);
        if (origClOrdID!=null) fields.putString(Tag_OrigClOrdID, origClOrdID);
        fields.putChar(Tag_ExecType, execType);
        fields.putChar(Tag_OrdStatus, ordStatus);
        if (ordRejReason!=0) fields.putInt(Tag_OrdRejReason, ordRejReason);
        fields.putString(Tag_Symbol, symbol);
        fields.putChar(Tag_Side, side);
        fields.putFloat(Tag_Price, price);
        fields.putChar(Tag_OrdType, ordType);
        fields.putChar(Tag_TimeInForce, timeInForce);
        if (!Double.isNaN(lastQty)) fields.putFloat(Tag_LastQty, lastQty);
        if (!Double.isNaN(lastPx)) fields.putFloat(Tag_LastPx, lastPx);
        if (!Double.isNaN(leavesQty)) fields.putFloat(Tag_LeavesQty, leavesQty);
        if (!Double.isNaN(cumQty)) fields.putFloat(Tag_CumQty, cumQty);
        if (!Double.isNaN(avgPx)) fields.putFloat(Tag_AvgPx, avgPx);
        fields.putString(Tag_TransactTime, Utils.formatMillis(Instant.now().toEpochMilli()));
        if (text!=null) fields.putString(Tag_Text, text);

        if (!Double.isNaN(qty)) fields.putFloat(Tag_OrderQty, qty);
        if (!Double.isNaN(shownQty)) fields.putFloat(Tag_MaxShow, shownQty);
    }

    public void orderCancelReject(String uid, long execId, long orderID, String clOrdID, String origClOrdID, char ordStatus, char cxlRejResponseTo, int cxlRejReason, String text) {
        setFixMsgType(MsgType_OrderCancelReject);
        FixFields fields = getFields();
        if (uid!=null) fields.putString(Tag_Username, uid);
        fields.putString(Tag_ExecID, Long.toString(execId));
        if (orderID!=0) fields.putInt(Tag_OrderID, orderID);
        if (clOrdID!=null) fields.putString(Tag_ClOrdID, clOrdID);
        if (origClOrdID!=null) fields.putString(Tag_OrigClOrdID, origClOrdID);
        fields.putChar(Tag_OrdStatus, ordStatus);
        fields.putChar(Tag_CxlRejResponseTo, cxlRejResponseTo);
        if (cxlRejReason!=0) fields.putInt(Tag_CxlRejReason, cxlRejReason);
        fields.putString(Tag_TransactTime, Utils.formatMillis(Instant.now().toEpochMilli()));
        if (text!=null) fields.putString(Tag_Text, text);
    }

    public void securityListRequest(String requestId) {
        setFixMsgType(MsgType_SecurityListRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_SecurityReqID, requestId);
        fixFields.putInt(Tag_SecurityListRequestType, Val_SecurityListRequestType_AllSecurities);
    }

    public void marketDataRequest(String requestId, char subscriptionRequestType, int maxLevels) {
        setFixMsgType(MsgType_MarketDataRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_MDReqID, requestId);
        fixFields.putChar(Tag_SubscriptionRequestType, subscriptionRequestType);
        if (subscriptionRequestType!=Val_SubscriptionRequestType_Disable) {
            fixFields.putInt(Tag_MarketDepth, maxLevels);
            fixFields.putInt(Tag_MDUpdateType, Val_MDUpdateType_Full);
            fixFields.putChar(Tag_AggregatedBook, Val_AggregatedBook_Aggregated);
        }
    }

    public void loginRequest(String requestId, String uid, String pwd) {
        setFixMsgType(MsgType_UserRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_UserRequestID, requestId);
        fixFields.putString(Tag_Username, uid);
        fixFields.putString(Tag_Password, pwd);
        fixFields.putInt(Tag_UserRequestType, Val_UserRequestType_LogOnUser);
    }

    public void logoutRequest(String requestId, String uid, String pwd) {
        setFixMsgType(MsgType_UserRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_UserRequestID, requestId);
        fixFields.putString(Tag_Username, uid);
        fixFields.putString(Tag_Password, pwd);
        fixFields.putInt(Tag_UserRequestType, Val_UserRequestType_LogOffUser);
    }

    public void newOrderSingle(String uid, String clOrdID, String symbol, OrdType ordType, TimeInForce tif, Side side, double px, double qtyShown, double qty) {
        setFixMsgType(MsgType_NewOrderSingle);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_Username, uid); // TODO shall I use the Component Block <Parties> instead?
        fixFields.putString(Tag_ClOrdID, clOrdID);
        fixFields.putString(Tag_Symbol, symbol);
        fixFields.putChar(Tag_Side, Side.toFix(side));
        fixFields.putFloat(Tag_Price, px);
        fixFields.putChar(Tag_OrdType, OrdType.toFix(ordType));
        fixFields.putChar(Tag_TimeInForce, TimeInForce.toFix(tif));
        fixFields.putFloat(Tag_MaxShow, qtyShown);
        fixFields.putFloat(Tag_OrderQty, qty);
    }

    public void orderCancelRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, Side side, double qty) {
        setFixMsgType(MsgType_OrderCancelRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_Username, uid); // TODO shall I use the Component Block <Parties> instead?
        fixFields.putString(Tag_OrigClOrdID, origClOrdId);
        fixFields.putString(Tag_OrderID, ecnOrdId);
        fixFields.putString(Tag_ClOrdID, clOrdId);
        fixFields.putString(Tag_Symbol, symbol);
        fixFields.putChar(Tag_Side, Side.toFix(side));
        fixFields.putFloat(Tag_OrderQty, qty);
    }

    public void orderCancelReplaceRequest(String uid, String ecnOrdId, String clOrdId, String origClOrdId, String symbol, double px, double qtyShown, double qty,  OrdType ordType, TimeInForce tif, Side side) {
        setFixMsgType(MsgType_OrderCancelReplaceRequest);
        FixFields fixFields = getFields();
        fixFields.putString(Tag_Username, uid); // TODO shall I use the Component Block <Parties> instead?
        fixFields.putString(Tag_OrigClOrdID, origClOrdId);
        fixFields.putString(Tag_OrderID, ecnOrdId);
        fixFields.putString(Tag_ClOrdID, clOrdId);
        fixFields.putString(Tag_Symbol, symbol);
        fixFields.putFloat(Tag_Price, px);
        fixFields.putFloat(Tag_OrderQty, qty);
        fixFields.putFloat(Tag_MaxShow, qtyShown);
        fixFields.putChar(Tag_OrdType, OrdType.toFix(ordType));
        fixFields.putChar(Tag_TimeInForce, TimeInForce.toFix(tif));
        fixFields.putChar(Tag_Side, Side.toFix(side));
    }

    public void userResponse(String userRequestID, String uid, int userStatus, String text) {
        setFixMsgType(MsgType_UserResponse);
        FixFields fields = getFields();
        fields.putString(Tag_UserRequestID, userRequestID);
        fields.putString(Tag_Username, uid);
        if (text!=null) fields.putString(Tag_UserStatusText, text);
        fields.putInt(Tag_UserStatus, userStatus);
    }
}
