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

package net.a_cappella.madrigal.om;

import com.google.common.annotations.VisibleForTesting;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.ICredentialsCache;
import net.a_cappella.madrigal.IInstrumentCache;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.madrigal.common.utils.StringDelayer;
import net.a_cappella.madrigal.user.EcnUserManager;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.ISnSListener;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_STRING_ALREADY_EXISTS;
import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_STRING_NON_EXISTENT_ORDER;
import static net.a_cappella.madrigal.common.constants.MadrigalMode.RESPONSE;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.ADD;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.RWT;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class OrderManagerService implements IOrderManagerService {
    private static final Logger log = LoggerFactory.getLogger(OrderManagerService.class);

    private static String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";

    private final String _marketDataSubSql = "select * from ecn.price where ecn='%s'";
    private final String _orderSubSql = "select * from order where ecn in ('%s', '%s')";
    private final String _finalizeOrderSubSql = "select * from finalize.order where ecn='%s'";
	private long _orderSubId;

    private final String _ecn;
    private final String _lhEcn;

	private final String _ftGroup;
    private final int _ftInstance;
	private boolean _active;
    private final PrestoClient _client;

	private final IOrderManagerAdaptor _adaptor;
	private final EcnUserManager _ecnUserManager;
	private final UserStatusCache _userStatusCache;

    private ActiveOrderHandlers _activeHandlers;
    private InactiveOrderStates _inactiveStates;
    private final Map<String, OrderHandler> _leafHandlers = new HashMap<>(); // (clOrdId, handler)

	private final ICredentialsCache _credentialsCache;
	private final IInstrumentCache _instrumentCache;
	private final Map<String, EcnPriceObj> _mdCache = new HashMap<>();
	private final Map<String, List<OrderHandler>> _priceListeners = new HashMap<>();

	private long _execId;
	public void setExecId(long execId) {
		_execId = execId;
	}

	private final OrderManagerServiceParams _omsParams;

	private int _finalizerDelay = 1000;
	public void setFinalizerDelay(int finalizerDelay) {
		_finalizerDelay = finalizerDelay;
	}
	private StringDelayer _handlerFinalizer;

	public OrderManagerService(PrestoClient client, String ecn,
                               ICredentialsCache credentialsCache,
                               IInstrumentCache instrumentCache,
                               OrderManagerServiceParams orderManagerServiceParams,
                               IOrderManagerAdaptor adaptor,
                               EcnUserManager ecnUserManager) {
        _client = client;
		_ftGroup = "FT.OMS." + client.getAppInfo().getShard();
		_ftInstance = _client.getAppInfo().getInstance();
		_ftMemberSubSql = String.format(_ftMemberSubSql, _ftGroup, _ftInstance);
        _ecn = ecn;
        _lhEcn = MadrigalConstants.LH_ECN_PREFIX + ecn;
        _credentialsCache = credentialsCache;
        _instrumentCache = instrumentCache;
        _omsParams = orderManagerServiceParams;
        _adaptor = adaptor;
        _ecnUserManager = ecnUserManager;
		_userStatusCache = new UserStatusCache();
	}

    public String getEcn() {
    	return _ecn;
    }
    public String getLhEcn() {
    	return _lhEcn;
    }
    public InactiveOrderStates getInactiveStates() {
    	return _inactiveStates;
    }
    public Map<String, OrderHandler> getLeafHandlers() {
    	return _leafHandlers;
    }
	public IInstrumentCache getInstrumentCache() {
		return _instrumentCache;
	}
	public Map<String, EcnPriceObj> getMdCache() {
		return _mdCache;
	}
	public OrderManagerServiceParams getOmsParams() {
		return _omsParams;
	}

    public void start() {
		_activeHandlers = new ActiveOrderHandlers(this, _ecn);
		_inactiveStates = new InactiveOrderStates(this);

		_omsParams.init();

		_client.waitUntilInitialized();

        try {
            _client.subscribe(_ftMemberSubSql, (obj, subsId) -> {
            	onFtMemberMessage((FtMemberObj) obj);
        	});

            _client.snapSubscribe(String.format(_marketDataSubSql, _ecn), (obj, subsId) -> {
                EcnPriceObj ecnPrice = (EcnPriceObj) obj;
                onEcnPrice(ecnPrice);
    		});

        	_client.subscribe(String.format(_finalizeOrderSubSql, _lhEcn), (obj, subsId) -> {
                FinalizeOrderObj finalizeOrder = (FinalizeOrderObj) obj;
                onFinalizeOrder(finalizeOrder);
        	});
        } catch (Exception e) {
            log.error("", e);
        }

    	_client.registerFtMember(_ftGroup, _ftInstance, 1);

        _handlerFinalizer = new HandlerFinalizer(_finalizerDelay);
        _handlerFinalizer.start();

		_ecnUserManager.setOrderManagerService(this);
	}

	private void onFtMemberMessage(FtMemberObj ftMem) {
        log.info("onFtMemberMessage("+ftMem+")");

        FtMsgOp op = ftMem.getAction();
		if (op == ACTIVATE) {
			_active = true;
			onActivate();
		} else if (op == DEACTIVATE) {
			_active = false;
			onDeactivate();
		}
	}

	@Override // IOrderManagerService
	public void publishMarketStatus(MarketStatusObj marketStatus) throws Exception {
		if (_active) {
			_client.serialize(marketStatus);
		}
	}

	@VisibleForTesting
	public void onOrderRequest(OrderObj order) {
        order.startUsing();

        String ordId = order.getOrdId();
        MadrigalReqType reqType = order.getReqType();
        if (ADD == reqType) {
        	RootOrderHandler rootOrderHandler = _activeHandlers.add(order);
            if (rootOrderHandler == null) {
                log.error(VAL_ERR_STRING_ALREADY_EXISTS+" '"+ordId+"'");
                // will not reply to this order
            } else {
				rootOrderHandler.handleAddRequest(order);
            }
        } else { // RWT or DEL
            RootOrderHandler rootOrderHandler = _activeHandlers.get(ordId);
        	if (rootOrderHandler==null) {
        		log.error(VAL_ERR_STRING_NON_EXISTENT_ORDER+" "+order);
        		order.setStatus(NAK);
        		order.setText(VAL_ERR_STRING_NON_EXISTENT_ORDER+" '"+ordId+"'");
        		order.setDone(true);
        		order.setFtDone(true);
                publishResponse(order);
        	} else {
                if (RWT == reqType) {
                    rootOrderHandler.handleRwtRequest(order);
                } else {
                    rootOrderHandler.handleDelRequest(order);
                }
        	}
        }
	}

	@VisibleForTesting
	public void onOrderResponse(OrderObj response) {
		String ordId = response.getOrdId();
		IOrderResponseHandler handler = _leafHandlers.get(ordId);
		if (handler==null) {
            log.error("Order '"+ordId+"' could not be found in handlers map. As a result, did not handle Execution Report "+response);
		} else {
			response.setTs(System.currentTimeMillis());
   			handler.handleResponse(response);
		}

	}

	private void onFinalizeOrder(FinalizeOrderObj finalizeOrder) {
		String ordId = finalizeOrder.getOrdId();
		RootOrderHandler rootHandler = _activeHandlers.finalizeOrder(ordId);
		if (rootHandler!=null) rootHandler.getHandler().finalizeHandler();
		_userStatusCache.finalizeOrder(ordId);
	}

	public void onEcnPrice(EcnPriceObj ecnPrice) {
        String instrId = ecnPrice.getInstrId();
		if (ecnPrice.isStale()) {
			_mdCache.remove(instrId);
		} else {
			_mdCache.put(instrId, ecnPrice);
			List<OrderHandler> listeners = _priceListeners.get(instrId);
			if (listeners != null) for (OrderHandler handler : listeners) {
				// notify subscribers
				handler.handleEcnPrice(ecnPrice);
			}
		}
	}





	public EcnPriceObj registerPriceListener(String instrId, OrderHandler handler) {
		_priceListeners.computeIfAbsent(instrId, l -> new ArrayList<>()).add(handler);
		return _mdCache.get(instrId);
	}
	public void unRegisterPriceListener(String instrId, OrderHandler handler) {
		List<OrderHandler> listeners = _priceListeners.get(instrId);
		if (listeners != null) listeners.remove(handler);
	}

	@Override
    public void publishResponse(OrderObj response) {
		try {
			response.setMadrigalMode(RESPONSE);
			String ecn = response.getEcn();
			if (_ecn.equals(ecn)) {
				if (MadrigalOrdStatus.FILL != response.getStatus()) response.setFillId(null);
				response.setExecId(++_execId);
				_client.publish(response);
			} else { // ecn.startsWith(LH_ECN_PREFIX)
				_client.serialize(response);
			}
		} catch (Exception e) {
			log.error("", e);
		}
    }



    public void onActivate() {
        // initial and failover activation
        log.info("----------------- onActivate");
        try {
        	_orderSubId = _client.snapSubscribe(String.format(_orderSubSql, _ecn, _lhEcn), new OrderMessageListener());
        } catch (Exception e) {
            log.error(getEcn(), e);
        }
        log.info("================= onActivate");
    }

    public void onDeactivate() {
    	_adaptor.disconnectFromExchange();
    	_client.unsubscribe(_orderSubId);
    	_activeHandlers.clear();
    }

    private class OrderMessageListener implements ISnSListener {
		@Override // ISnapCompleteListener
		public void onSnapComplete(long subId) {
			log.info("onSnapComplete");
			_adaptor.connectToExchange();
		}

		@Override // ISubscriptionListener
		public void onSubscriptionMessage(Obj obj, long subsId) {
            OrderObj order = (OrderObj) obj;
			if (_active) {
				if (log.isDebugEnabled()) log.info("onSubscriptionMessage "+order);

				String ecn = order.getEcn();
	    		if (_lhEcn.equals(ecn)) { // response from ECN does not have uid / ecnUid
					_userStatusCache.populateUids(order); // uid and ecnUid from UserStatus
	    		}
				populateEcnIds(order); // ecnUid from credentialsCache and ecnInstrId from instrumentCache
				if (_userStatusCache.isLoggedIn(order)) {
		    		if (_lhEcn.equals(ecn)) {
		    			onOrderResponse(order); // normal handling
		    		} else if (order.getMadrigalMode() == MadrigalMode.REQUEST) {
	    				onOrderRequest(order); // normal handling
		    		}
				} else {
					_inactiveStates.onSubscriptionMessage(order, true);
				}
			} // else warm instance, do nothing
		}

		@Override // ISubscriptionListener
	    public void onHighWaterMark(Obj obj) {
			OrderObj hwm = (OrderObj) obj;
			long seqNo = hwm.getSeqNo();
			long execId = hwm.getExecId();
			log.info("================== onHighWaterMark seqNo={} execId={}", seqNo, execId);
			setExecId(execId + 1001); // could have added 1 but it's easier to spot when a failover occurred if we add a larger number
	    }
    }

    public void onEcnUserStatusResult(EcnUserStatusObj ecnUserStatusObj) {
    	if (_ftInstance != ecnUserStatusObj.getInstance()) return;

    	_userStatusCache.onUserStatusUpdate(ecnUserStatusObj);

		if (!_active) return; // warm instance, do nothing

    	log.info("onEcnUserStatusResult {}", ecnUserStatusObj);

    	String ecnUid = ecnUserStatusObj.getEcnUid();
		MadrigalUserStatus userStatus = ecnUserStatusObj.getStatus();

		if (userStatus == MadrigalUserStatus.On) {
			// onLogin
			activateOrders(ecnUid);
		} else if (userStatus == MadrigalUserStatus.Off) {
			// onLogout
			deactivateOrders(ecnUid);
		}
    }

    public void cancelAllActiveOrders(String ecnUid) {
    	log.info("cancelAllActiveOrders {}", ecnUid);
    	_activeHandlers.cancelAllActiveOrders(ecnUid);
    }

    @VisibleForTesting
    public void activateOrders(String ecnUid) {
		log.info("================================= all inactive orders");
		_inactiveStates.log();
		log.info("--------------------------------- activateOrders for {}", ecnUid);
		_inactiveStates.activateOrders(ecnUid, _activeHandlers);
		log.info("================================= done activateOrders for {}", ecnUid);
	}

	private void deactivateOrders(String ecnUid) {
		log.info("================================= all active orders");
		_activeHandlers.log(ecnUid);
		log.info("--------------------------------- deactivateOrders " + ecnUid);
	}

	public void finalizeHandler(String ordId) {
    	_handlerFinalizer.add(ordId);
    }

    private class HandlerFinalizer extends StringDelayer {
    	private final FinalizeOrderObj _finalizeOrderObj = new FinalizeOrderObj();
    	public HandlerFinalizer(int delayInMillis) {
    		super(delayInMillis);
    	}
		@Override
		public void execute(String ordId) {
			_finalizeOrderObj.set(_lhEcn, ordId, System.currentTimeMillis());
			try {
				_client.publish(_finalizeOrderObj);
			} catch (Exception e) {
				log.error("", e);
			}
		}
    }




    public void populateEcnIds(OrderObj order) {
        String ecnUid = order.getEcnUid();
        if (ecnUid == null) {
            String uid = order.getUid();
            EcnCredentialsObj creds = _credentialsCache.getEcnCredentials(uid);
            if (creds != null) {
                ecnUid = creds.getEcnUid();
                creds.stopUsing();
                order.setEcnUid(ecnUid);
            }
        }

        String ecnInstrId = order.getEcnInstrId();
        if (ecnInstrId == null) {
            String instrId = order.getInstrId();
            ecnInstrId = _instrumentCache.getEcnInstrId(instrId);
            if (ecnInstrId != null) {
                order.setEcnInstrId(ecnInstrId);
            }
        }
    }
}
