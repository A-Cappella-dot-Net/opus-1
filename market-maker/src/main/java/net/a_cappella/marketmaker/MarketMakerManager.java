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

package net.a_cappella.marketmaker;

import net.a_cappella.continuo.utils.Delayer;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.interfaces.IIdGenerator;
import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.madrigal.om.OrderManagerClient;
import net.a_cappella.madrigal.user.UserManagerClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MarketMakerManager {
    private static final Logger log = LoggerFactory.getLogger(MarketMakerManager.class);

    private PrestoClient _client;

    private final OrderManagerClient _omClient;
    private final UserManagerClient _userMgr;
    private final IIdGenerator _idGen;

    private final String _ecn;
    private final String _uid;
    private final String _pwd;
    private boolean _loggedIn;

    private final String _ecnInstrumentSql = "select * from ecn.instrument where ecn='%s'";
    private final String _ecnInstrStatusSql = "select * from ecn.instr.status where ecn='%s'";
    private final String _ecnPriceSql = "select * from ecn.price where ecn='%s'";
    private final String _midFeedSql = "select * from mid.feed";

    /**
     * Different market maker instances will respond to mid feed signals with different delays.
     */
    private final int _midFeedFixedDelay;
    private final int _midFeedRandomRangeDelay;
	private final Delayer<MidFeedObj> _midFeedDelayer = new Delayer<>("MidFeed",
			midFeed -> {
				try {
					_client.loopback(midFeed);
					midFeed.stopUsing();
				} catch (Exception x) {
					log.error("", x);
				}
			});

    private final Map<String, MarketMaker> _mmsByInstrId = new HashMap<>();

    public MarketMakerManager(PrestoClient client, IIdGenerator idGen,
    						  String ecn, String uid, String usrPwd, List<String> instruments,
    						  int midFeedFixedDelay, int midFeedRandomRangeDelay) {
    	_client = client;
    	_idGen = idGen;

    	_ecn = ecn;
    	_uid = uid;
    	_pwd = usrPwd;

        short mmId = 0;
    	for (String instrument : instruments) {
    		InstrumentConfig ic = new InstrumentConfig(instrument);
    		MarketMaker mm = new MarketMaker(this, ic._instrId, ic._normalSpreadTicks, ic._wideSpreadTicks, ic._whenHitInterval, ic._pullOrderWhenHit, ic._bidSize, ic._askSize);
    		if (ic._sniperInterval > 0) {
        		mm.scheduleSniper(++mmId, ic._sniperInterval, ic._tobFraction);
    		}
    		_mmsByInstrId.put(ic._instrId, mm);
    	}

    	_midFeedFixedDelay = midFeedFixedDelay;
    	_midFeedRandomRangeDelay = midFeedRandomRangeDelay;

        _userMgr = new MyUserManagerClient(_client);
        _omClient = new MyOMClient(_uid, _client);
    }

    public void start() {
    	_client.addSnippet(() -> {
    		runOnTLT();
    		return -1; // run only once
    	});
    }

    private void runOnTLT() {
        _midFeedDelayer.start();

        _client.waitUntilInitialized();

        _userMgr.start();
        _userMgr.login(_uid, _pwd, false);

        _omClient.start();

        try {
            // 1. subscribe to static data for the mm'd instruments
        	_client.snapSubscribe(String.format(_ecnInstrumentSql, _ecn), (obj, subsId) -> { // ecn.instrument
                handleEcnInstrument((EcnInstrumentObj) obj);
        	});

            // 2. subscribe to instrument status
        	_client.snapSubscribe(String.format(_ecnInstrStatusSql, _ecn), (obj, subsId) -> { // ecn.instr.status
                handleInstrStatus((EcnInstrStatusObj) obj);
        	});

        	// 3. subscribe to mid feed
        	_client.snapSubscribe(_midFeedSql, (obj, subsId) -> { // mid.feed
                handleMidFeed((MidFeedObj) obj);
        	});
        	// 4. subscribe to market data
        	_client.snapSubscribe(String.format(_ecnPriceSql, _ecn), (obj, subsId) -> { // ecn.price
                handleEcnPrice((EcnPriceObj) obj);
        	});
		} catch (Exception e) {
			log.error("", e);
		}
    }

	private void handleEcnInstrument(EcnInstrumentObj ecnInstrument) {
    	String instrId = ecnInstrument.getSecurityID();
    	MarketMaker marketMaker = _mmsByInstrId.get(instrId);
    	if (marketMaker!=null) {
    		marketMaker.handleEcnInstrument(ecnInstrument);
    	}
	}
	private void handleInstrStatus(EcnInstrStatusObj ecnInstrStatus) {
    	String instrId = ecnInstrStatus.getSecurityID();
    	MarketMaker marketMaker = _mmsByInstrId.get(instrId);
    	if (marketMaker!=null) {
    		marketMaker.handleEcnInstrStatus(ecnInstrStatus);
    	}
	}
	private void handleMidFeed(MidFeedObj midFeed) {
		long delay = _midFeedFixedDelay + (long) (Math.random() * _midFeedRandomRangeDelay);
        if (log.isDebugEnabled()) log.info("delay={} onLoopback={} handleMidFeed({})", delay, midFeed.isOnLoopback(), midFeed);
    	if (!midFeed.isOnLoopback() && delay != 0) {
    		midFeed.startUsing();
    		_midFeedDelayer.add(delay, midFeed);
    	} else {
            if (_userMgr.isLoggedIn(_uid, _ecn)) {
            	String instrId = midFeed.getInstrId();
            	MarketMaker marketMaker = _mmsByInstrId.get(instrId);
            	if (marketMaker!=null) {
            		marketMaker.handleMidFeed(midFeed);
            	}
        	}
    	}
	}
	private void handleEcnPrice(EcnPriceObj ecnPrice) {
    	if (_userMgr.isLoggedIn(_uid, _ecn)) {
        	String instrId = ecnPrice.getInstrId();
        	MarketMaker marketMaker = _mmsByInstrId.get(instrId);
        	if (marketMaker!=null) {
        		marketMaker.handleEcnPrice(ecnPrice);
        	}
    	}
	}

	// ------------------------------------------------------
    private class MyOMClient extends OrderManagerClient {
    	private final String _uid;

    	public MyOMClient(String uid, PrestoClient client) {
            super(client, _ecn);
            _uid = uid;
        }

        @Override
        public void start() {
            addUser(_uid);
        	super.start();
        }

        @Override
        public void onOrderResponse(OrderObj er) {
        	handleOrderResponse(er);
        }
    }

    // ------------------------------------------------------
    private class MyUserManagerClient extends UserManagerClient {
        public MyUserManagerClient(PrestoClient client) {
            super(client, _ecn);
        }

        @Override
        public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatus) {
        	handleEcnUserStatus(ecnUserStatus, this);
        }
    }

    private void handleOrderResponse(OrderObj response) {
    	String instrId = response.getInstrId();
    	MarketMaker marketMaker = _mmsByInstrId.get(instrId);
    	if (marketMaker!=null) {
    		marketMaker.handleOrderResponse(response);
    	}
	}
	private void handleEcnUserStatus(EcnUserStatusObj ecnUserStatus, UserManagerClient userManagerClient) {
    	String uid = ecnUserStatus.getUid();
    	if (_uid.equals(uid)) {
        	String ecn = ecnUserStatus.getEcn();
        	boolean loggedIn = userManagerClient.isLoggedIn(uid, ecn);
        	_loggedIn = loggedIn;
        	for (MarketMaker marketMaker : _mmsByInstrId.values()) {
        		marketMaker.handleUserStatus(loggedIn);
        	}
    	}
	}




    public PrestoClient getClient() {
    	return _client;
    }

    public boolean isLoggedIn() {
		return _loggedIn;
	}

	public String addOrder(String ordId, String instrId, MadrigalSide side, MadrigalOrdType ordType, MadrigalTimeInForce tif, double price, double orderQty, double shownQty) {
		return _omClient.addOrder(_uid, _ecn, ordId, instrId, side, ordType, tif, price, orderQty, shownQty, 0, true);
	}
	public String rwtOrder(String ordId, double qtyShown, double qtyTot, double price) {
	    return _omClient.rwtOrder(ordId, qtyShown, qtyTot, 0, price);
	}
	public String delOrder(String ordId) {
		return _omClient.delOrder(ordId);
	}

	public String nextOrderId() {
		return _idGen.nextId();
	}
}
