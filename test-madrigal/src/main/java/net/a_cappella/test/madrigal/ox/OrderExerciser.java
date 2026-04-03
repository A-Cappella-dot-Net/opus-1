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

package net.a_cappella.test.madrigal.ox;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import gnu.trove.impl.Constants;
import gnu.trove.map.TObjectDoubleMap;
import gnu.trove.map.hash.TObjectDoubleHashMap;
import net.a_cappella.continuo.utils.DelayQueue;
import net.a_cappella.continuo.utils.DelayedObj;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.interfaces.IIdGenerator;
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderManagerClient;
import net.a_cappella.madrigal.user.UserManagerClient;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class OrderExerciser {
    private static final Logger log = LoggerFactory.getLogger(OrderExerciser.class);

    private final String _rdSubSql = "select * from ecn.instrument where ecn='%s'";
    private final String _priceSubSql = "select * from ecn.price where ecn='%s' and instrId='%s'";

    private final String _ecn;
    private final String _uid;
    private final String _pwd;
    private final boolean _whenEmptyStackUseLastCached;

    private final IFeatureExerciser _featureExerciser;

    private final PrestoClient _client;
    private final IIdGenerator _idGen;

    private final Map<String, MDSnapshot> _mdCache = new HashMap<>();
    private final FrequencyMap _frequencyMap = new FrequencyMap();
    private final TObjectDoubleMap<String> _minPriceTickMap = new TObjectDoubleHashMap<>();

    private OrderManagerClient _omClient;
    private UserManagerClient _userMgr;

    public OrderExerciser(String ecn, String uid, String usrPwd, PrestoClient client, IIdGenerator idGen,
    		boolean whenEmptyStackUseLastCached,
    		IFeatureExerciser featureExerciser) {
        _ecn = ecn;
        _uid = uid;
    	_pwd = usrPwd;
        _client = client;
        _idGen = idGen;
        _whenEmptyStackUseLastCached = whenEmptyStackUseLastCached;
        _featureExerciser = featureExerciser;
    }

    public void init() {
    	_client.addSnippet(() -> {
    		runOnTLT();
    		return -1; // run only once
    	});
    }

    public void runOnTLT() {
    	_featureExerciser.setOx(this);

    	_client.waitUntilInitialized();

        _omClient = new MyOMClient(_uid, _client);
        _omClient.start();
        _userMgr = new UserManagerClient(_client, _ecn);
        _userMgr.start();
        _userMgr.login(_uid, _pwd, false);

        try {
            _client.snapSubscribe(String.format(_rdSubSql, _ecn), (instrObj, instrSubscriber) -> { // ecn.instrument
            	EcnInstrumentObj instr = (EcnInstrumentObj) instrObj;
                String instrId = instr.getSecurityID();
                double minPriceTick = instr.getMinPriceIncrement();
                if (_minPriceTickMap.put(instrId, minPriceTick) == Constants.DEFAULT_DOUBLE_NO_ENTRY_VALUE) {
                    try {
                    	String sql = String.format(_priceSubSql, _ecn, instrId);
                    	log.info("subscribing to {}", sql);

                    	_client.snapSubscribe(sql, (priceObj, priceSubscriber) -> { // ecn.price
                        	EcnPriceObj price = (EcnPriceObj) priceObj;
                        	if (log.isDebugEnabled()) log.debug(price.toString());
                            // collect frequencies & latest price
                            String priceInstrId = price.getInstrId();
                            double bid = price.getBid0();
                            double bidSizeO = price.getBidSize0();
                            int bidSize = (Double.isNaN(bidSizeO))?-1:(int)bidSizeO;
                            double ask = price.getOffer0();
                            double askSizeO = price.getOfferSize0();
                            int askSize = (Double.isNaN(askSizeO))?-1:(int)askSizeO;

                            if ((bidSize>0) || (askSize>0)) {
                                if (log.isDebugEnabled()) log.debug("caching {} {}@{}/{}@{}", priceInstrId, bidSize, bid, askSize, ask);
                                _mdCache.put(priceInstrId, new MDSnapshot(priceInstrId, bid, bidSize, ask, askSize));
                                _frequencyMap.newMds(priceInstrId);
                            } else if (!_whenEmptyStackUseLastCached) {
                               	_mdCache.remove(priceInstrId);
                            }
                        });
                    } catch (Exception e) {
                        log.error(instr.toString(), e);
                    }
                    _frequencyMap.addInstr(instrId);
                }
            });

            _client.addSnippet(() -> {
            	_featureExerciser.evalState();
            	return 1; // keep evaluating
            });
        } catch (Exception e) {
            log.error("{} && {}", _uid, _rdSubSql, e);
        }
    }

    public boolean isLoggedIn() {
    	return _userMgr.isLoggedIn(_uid, _ecn);
    }

    public double getMinPriceTick(String instrId) {
    	return _minPriceTickMap.get(instrId);
    }

    public String nextId() {
    	return _idGen.nextId();
    }

    public String addOrder(String ordId,
                           String instrId, MadrigalSide side, MadrigalOrdType ordType, MadrigalTimeInForce tif,
                           double price, double orderQty, double shownQty, int randomMax,
                           boolean useNative) {
    	return _omClient.addOrder(_uid, _ecn, ordId, instrId, side, ordType, tif, price, orderQty, shownQty, randomMax, useNative);
    }

    public void rwtOrder(String ordId, double shownQty, double orderQty, int randomMax, double price) {
    	_omClient.rwtOrder(ordId, shownQty, orderQty, randomMax, price);
    }

    public void delOrder(String ordId) {
    	_omClient.delOrder(ordId);
    }



    private Iterator<MDSnapshot> _iter;
    public MDSnapshot roundRobinMds() {
        if (_mdCache.isEmpty()) return null;
        if (_iter==null) {
            _iter = _mdCache.values().iterator();
        }
        MDSnapshot mds = null;
        if (_iter.hasNext()) {
            mds = _iter.next();
        } else {
            _iter = _mdCache.values().iterator();
            if (_iter.hasNext()) {
                mds = _iter.next();
            }
        }
        return mds;
    }

    public MDSnapshot mostActiveMds() {
        String instrId = _frequencyMap.mostActive();
        if (instrId==null) return null;
        MDSnapshot mds = _mdCache.get(instrId);
        if (log.isDebugEnabled()) log.debug("most active = {}", mds);
        return mds;
    }

    // ------------------------------------------------------
    public static class MDSnapshot {
    	public String _instrId;
    	public double _bid;
    	public int _bidSize;
    	public double _ask;
    	public int _askSize;

    	public MDSnapshot(String instrId, double bid, int bidSize, double ask, int askSize) {
            _instrId = instrId;
            _bid = bid;
            _bidSize = bidSize;
            _ask = ask;
            _askSize = askSize;
        }
        public String toString() {
            return "{"+_instrId+" "+_bidSize+"@"+_bid+"/"+_askSize+"@"+_ask+"}";
        }
    }

    // ------------------------------------------------------
    public static class FrequencyMap {
        private final Map<String, DelayQueue<DelayedObj>> _mdMap = new HashMap<>();

        public FrequencyMap() {}

        public void addInstr(String instrId) {
            DelayQueue<DelayedObj> newQueue = new DelayQueue<>(100, new DelayedObj());
            _mdMap.put(instrId, newQueue);
        }

        public void newMds(String instrId) {
            DelayQueue<DelayedObj> queue = _mdMap.get(instrId);
            queue.add(5000);
            queue.drain();
        }

        public String mostActive() {
            String instrId = null;
            int max = 0;
            for (Map.Entry<String, DelayQueue<DelayedObj>> entry : _mdMap.entrySet()) {
                DelayQueue<DelayedObj> queue = entry.getValue();
                queue.drain();
                int s = queue.size();
                if (s>max) {
                    max = s;
                    instrId = entry.getKey();
                }
            }
            return instrId;
        }
    }

    // ------------------------------------------------------
    private class MyOMClient extends OrderManagerClient {
        public MyOMClient(String uid, PrestoClient client) {
            super(client, _ecn);
            addUser(uid);
        }

        @Override // OrderManagerClient
        public void onOrderResponse(OrderObj er) {
            _featureExerciser.handleResponse(er);
        }
    }
}
