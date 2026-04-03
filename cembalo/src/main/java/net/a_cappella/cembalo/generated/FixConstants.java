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

package net.a_cappella.cembalo.generated;

// File: net.a_cappella.cembalo.generated.FixConstants was machine generated on Sat Aug 09 13:43:16 UTC 2025. Do not modify.

public class FixConstants {

	public static final String MsgType_ExecutionReport = "8";
	public static final String MsgType_OrderCancelReject = "9";
	public static final String MsgType_UserRequest = "BE";
	public static final String MsgType_UserResponse = "BF";
	public static final String MsgType_NewOrderSingle = "D";
	public static final String MsgType_OrderCancelRequest = "F";
	public static final String MsgType_OrderCancelReplaceRequest = "G";
	public static final String MsgType_OrderStatusRequest = "H";
	public static final String MsgType_MarketDataRequest = "V";
	public static final String MsgType_MarketDataSnapshot = "W";
	public static final String MsgType_MarketDataRequestReject = "Y";
	public static final String MsgType_SecurityListRequest = "x";
	public static final String MsgType_SecurityList = "y";

	public static final int Tag_Account = 1;
	public static final int Tag_AvgPx = 6;
	public static final int Tag_ClOrdID = 11;
	public static final int Tag_CumQty = 14;
	public static final int Tag_ExecID = 17;

	public static final int Tag_SecurityIDSource = 22;
	public static final String Val_SecurityIDSource_CUSIP = "1";
	public static final String Val_SecurityIDSource_ISIN = "4";
	public static final String Val_SecurityIDSource_ExchangeSymbol = "8";
	public static final String Val_SecurityIDSource_BloombergSymbol = "A";

	public static final int Tag_LastPx = 31;
	public static final int Tag_LastQty = 32;
	public static final int Tag_OrderID = 37;
	public static final int Tag_OrderQty = 38;

	public static final int Tag_OrdStatus = 39;
	public static final char Val_OrdStatus_New = '0';
	public static final char Val_OrdStatus_PartiallyFilled = '1';
	public static final char Val_OrdStatus_Filled = '2';
	public static final char Val_OrdStatus_DoneForDay = '3';
	public static final char Val_OrdStatus_Canceled = '4';
	public static final char Val_OrdStatus_Replaced = '5';
	public static final char Val_OrdStatus_PendingCancel = '6';
	public static final char Val_OrdStatus_Rejected = '8';


	public static final int Tag_OrdType = 40;
	public static final char Val_OrdType_Unknown = '0';
	public static final char Val_OrdType_Market = '1';
	public static final char Val_OrdType_Limit = '2';
	public static final char Val_OrdType_Pegged = 'P';

	public static final int Tag_OrigClOrdID = 41;
	public static final int Tag_Price = 44;
	public static final int Tag_SecurityID = 48;

	public static final int Tag_Side = 54;
	public static final char Val_Side_Buy = '1';
	public static final char Val_Side_Sell = '2';
	public static final char Val_Side_SellShort = '5';
	public static final char Val_Side_None = 'Z';

	public static final int Tag_Symbol = 55;
	public static final int Tag_Text = 58;

	public static final int Tag_TimeInForce = 59;
	public static final char Val_TimeInForce_DAY = '0';
	public static final char Val_TimeInForce_AtOpen = '2';
	public static final char Val_TimeInForce_IOC = '3';
	public static final char Val_TimeInForce_FOK = '4';
	public static final char Val_TimeInForce_AtClose = '7';
	public static final char Val_TimeInForce_STO = 'C';
	public static final char Val_TimeInForce_Unknown = 'Z';

	public static final int Tag_TransactTime = 60;
	public static final int Tag_SymbolSfx = 65;
	public static final int Tag_TradeDate = 75;
	public static final int Tag_CxlQty = 84;

	public static final int Tag_CxlRejReason = 102;
	public static final int Val_CxlRejReason_TooLateToCancel = 0;
	public static final int Val_CxlRejReason_UnknownOrder = 1;
	public static final int Val_CxlRejReason_OrderAlreadyInPendingCancelOrPendingReplace = 3;
	public static final int Val_CxlRejReason_InvalidPriceIncrement = 18;
	public static final int Val_CxlRejReason_Other = 99;


	public static final int Tag_OrdRejReason = 103;
	public static final int Val_OrdRejReason_UnknownSymbol = 1;
	public static final int Val_OrdRejReason_ExchangeClosed = 2;
	public static final int Val_OrdRejReason_UnknownOrder = 5;
	public static final int Val_OrdRejReason_DuplicateOrder = 6;
	public static final int Val_OrdRejReason_IncorrectQuantity = 13;
	public static final int Val_OrdRejReason_PriceExceedsCurrentPriceBand = 16;
	public static final int Val_OrdRejReason_InvalidPriceIncrement = 18;
	public static final int Val_OrdRejReason_Other = 99;

	public static final int Tag_SecurityDesc = 107;
	public static final int Tag_MinQty = 110;
	public static final int Tag_NoRelatedSym = 146;

	public static final int Tag_ExecType = 150;
	public static final char Val_ExecType_New = '0';
	public static final char Val_ExecType_DoneForDay = '3';
	public static final char Val_ExecType_Canceled = '4';
	public static final char Val_ExecType_Replaced = '5';
	public static final char Val_ExecType_PendingCancel = '6';
	public static final char Val_ExecType_Rejected = '8';
	public static final char Val_ExecType_PendingNew = 'A';
	public static final char Val_ExecType_PendingReplace = 'E';
	public static final char Val_ExecType_Trade = 'F';
	public static final char Val_ExecType_OrderStatus = 'I';

	public static final int Tag_LeavesQty = 151;

	public static final int Tag_SecurityType = 167;
	public static final String Val_SecurityType_Future = "FUT";
	public static final String Val_SecurityType_Option = "OPT";
	public static final String Val_SecurityType_USTreasuryBill = "TBILL";
	public static final String Val_SecurityType_USTreasuryBond = "TBOND";
	public static final String Val_SecurityType_USTreasuryNote = "TNOTE";

	public static final int Tag_MaxShow = 210;
	public static final int Tag_CouponRate = 223;
	public static final int Tag_ContractMultiplier = 231;
	public static final int Tag_MDReqID = 262;

	public static final int Tag_SubscriptionRequestType = 263;
	public static final char Val_SubscriptionRequestType_Snapshot = '0';
	public static final char Val_SubscriptionRequestType_SnapshotAndSubscribe = '1';
	public static final char Val_SubscriptionRequestType_Disable = '2';

	public static final int Tag_MarketDepth = 264;

	public static final int Tag_MDUpdateType = 265;
	public static final int Val_MDUpdateType_Full = 0;
	public static final int Val_MDUpdateType_Incremental = 1;


	public static final int Tag_AggregatedBook = 266;
	public static final char Val_AggregatedBook_NotAggregated = 'N';
	public static final char Val_AggregatedBook_Aggregated = 'Y';

	public static final int Tag_NoMDEntries = 268;

	public static final int Tag_MDEntryType = 269;
	public static final char Val_MDEntryType_Bid = '0';
	public static final char Val_MDEntryType_Offer = '1';
	public static final char Val_MDEntryType_OpeningPrice = '4';
	public static final char Val_MDEntryType_ClosingPrice = '5';
	public static final char Val_MDEntryType_HighPrice = '7';
	public static final char Val_MDEntryType_LowPrice = '8';
	public static final char Val_MDEntryType_VWAP = '9';
	public static final char Val_MDEntryType_Imbalance = 'A';
	public static final char Val_MDEntryType_TradeVolume = 'B';
	public static final char Val_MDEntryType_Quote = 'q';

	public static final int Tag_MDEntryPx = 270;
	public static final int Tag_MDEntrySize = 271;

	public static final int Tag_QuoteCondition = 276;
	public static final String Val_QuoteCondition_Open = "A";
	public static final String Val_QuoteCondition_Closed = "B";


	public static final int Tag_TradeCondition = 277;
	public static final String Val_TradeCondition_ImbalanceMoreBuyers = "P";
	public static final String Val_TradeCondition_Balanced = "PQ";
	public static final String Val_TradeCondition_ImbalanceMoreSellers = "Q";


	public static final int Tag_MDReqRejReason = 281;
	public static final char Val_MDReqRejReason_UnknownSymbol = '0';
	public static final char Val_MDReqRejReason_DuplicateMDReqID = '1';
	public static final char Val_MDReqRejReason_UnsupportedMarketDepth = '5';

	public static final int Tag_SecurityReqID = 320;
	public static final int Tag_TotNoRelatedSym = 393;

	public static final int Tag_CxlRejResponseTo = 434;
	public static final char Val_CxlRejResponseTo_OrderCancelRequest = '1';
	public static final char Val_CxlRejResponseTo_OrderCancelReplaceRequest = '2';

	public static final int Tag_MaturityDate = 541;
	public static final int Tag_Username = 553;
	public static final int Tag_Password = 554;

	public static final int Tag_SecurityListRequestType = 559;
	public static final int Val_SecurityListRequestType_Symbol = 0;
	public static final int Val_SecurityListRequestType_AllSecurities = 4;


	public static final int Tag_SecurityRequestResult = 560;
	public static final int Val_SecurityRequestResult_ValidRequest = 0;
	public static final int Val_SecurityRequestResult_InvalidRequest = 1;
	public static final int Val_SecurityRequestResult_NoInstrumentsFound = 2;
	public static final int Val_SecurityRequestResult_NotAuthorized = 3;
	public static final int Val_SecurityRequestResult_TemporarilyUnavailable = 4;
	public static final int Val_SecurityRequestResult_NotSupported = 5;

	public static final int Tag_ClearingBusinessDate = 715;

	public static final int Tag_LastFragment = 893;
	public static final char Val_LastFragment_NotLast = 'N';
	public static final char Val_LastFragment_Last = 'Y';

	public static final int Tag_UserRequestID = 923;

	public static final int Tag_UserRequestType = 924;
	public static final int Val_UserRequestType_LogOnUser = 1;
	public static final int Val_UserRequestType_LogOffUser = 2;


	public static final int Tag_UserStatus = 926;
	public static final int Val_UserStatus_LoggedIn = 1;
	public static final int Val_UserStatus_NotLoggedIn = 2;
	public static final int Val_UserStatus_UserNotRecognized = 3;
	public static final int Val_UserStatus_PasswordIncorrect = 4;
	public static final int Val_UserStatus_Other = 6;

	public static final int Tag_UserStatusText = 927;
	public static final int Tag_MinPriceIncrement = 969;

	public static final int Tag_SecurityRejectReason = 1607;
	public static final int Val_SecurityRejectReason_InvalidInstrument = 1;
	public static final int Val_SecurityRejectReason_AlreadyExists = 2;
	public static final int Val_SecurityRejectReason_NotSupported = 3;


	public static final int Tag_MDBook = 5147;
	public static final char Val_MDBook_Open = 'A';
	public static final char Val_MDBook_Close = 'B';
	public static final char Val_MDBook_Continuous = 'C';


	public static final int Tag_MDBookPhase = 5148;
	public static final char Val_MDBookPhase_Closed = 'A';
	public static final char Val_MDBookPhase_All = 'B';
	public static final char Val_MDBookPhase_OnlyNew = 'C';
	public static final char Val_MDBookPhase_NonMatching = 'D';
	public static final char Val_MDBookPhase_Matching = 'E';

	public static final int Tag_MatchedQty = 5385;
	public static final int Tag_ImbalanceQty = 5386;
	public static final int Tag_MinQtyIncrement = 5388;

}
