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

import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.ACK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdStatus.NAK;
import static net.a_cappella.madrigal.common.constants.MadrigalOrdType.LIMIT;
import static net.a_cappella.madrigal.common.constants.MadrigalReqType.DEL;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.DAY;

public class MarketMakerSide {

    private static final Logger log = LoggerFactory.getLogger(MarketMakerSide.class);

	private enum OrderStatus {
		NULL, PENDING, ACKED, DELETING
	}

	// constants
    private final MarketMakerManager _mgr;
    private final MarketMaker _mm;
    private final String _instrId;
	private final MadrigalSide _side;
	private final double _orderSize;

	private final int _hitIntervalMillis;
    private final boolean _pullWhenHit;

	private double _currPx;
	private OrderStatus _currStatus = OrderStatus.NULL;
	private double _pendPx;
	private String _pendClOrdId;
	private OrderStatus _pendStatus = OrderStatus.NULL;

    private double _minPriceIncrement = Double.NaN;
    private double _normalSpread = Double.NaN;
    private double _wideSpread = Double.NaN;

	public double _mid = Double.NaN;

	// variables
	// order management
	private long _hitExpiryMillis;
	private String _ordId;

	public MarketMakerSide(MarketMakerManager mgr, MarketMaker mm, String instrId, MadrigalSide side, double orderSize, int hitIntervalMillis, boolean pullWhenHit) {
		_mgr = mgr;
		_mm = mm;
		_instrId = instrId;
		_side = side;
		_orderSize = orderSize;
		_hitIntervalMillis = hitIntervalMillis;
		_pullWhenHit = pullWhenHit;
	}

	public void setInstrumentDetails(double minPriceIncrement, double normalSpread, double wideSpread) {
		_minPriceIncrement = minPriceIncrement;
		_normalSpread = normalSpread;
		_wideSpread = wideSpread;
	}

	private void setHitExpiryTime() {
		log.info("{} {} HIT started", _instrId, _side);
		_hitExpiryMillis = System.currentTimeMillis() + _hitIntervalMillis;
	}

	private boolean isHitExpired() {
		if (_hitExpiryMillis == 0) {
			return true;
		}
		if (System.currentTimeMillis() > _hitExpiryMillis) {
			log.info("{} {} HIT expired", _instrId, _side);
			_hitExpiryMillis = 0;
			return true;
		}
		return false;
	}

	private boolean whenHitIgnore() {
		return _hitIntervalMillis == 0;
	}

	private double latestPx() {
		if (Double.isNaN(_pendPx)) return _currPx;
		return _pendPx;
	}

	private double newPrice() {
		double spread = (isHitExpired()) ? _normalSpread : _wideSpread;
		if (Buy == _side) {
			return Utils.alignDown(_mid - spread/2, _minPriceIncrement);
		} else {
			return Utils.alignUp(_mid + spread/2, _minPriceIncrement);
		}
	}

	private String addOrder(double pendPx) {
		_ordId = _mgr.nextOrderId();
		String clOrdId = _mgr.addOrder(_ordId, _instrId, _side, LIMIT, DAY, pendPx, _orderSize, _orderSize);
		_pendClOrdId = clOrdId;
		_pendPx = pendPx;
		_pendStatus = OrderStatus.PENDING;
		return clOrdId;
	}

	private String rwtOrder(double pendPx) {
		String clOrdId = _mgr.rwtOrder(_ordId, _orderSize, _orderSize, pendPx);
		_pendClOrdId = clOrdId;
		_pendPx = pendPx;
		_pendStatus = OrderStatus.PENDING;
		return clOrdId;
	}

	private String delOrder() {
		String clOrdId = _mgr.delOrder(_ordId);
		_currStatus = OrderStatus.DELETING; _currPx = Double.NaN;
		_pendStatus = OrderStatus.NULL; _pendPx = Double.NaN; _pendClOrdId = null;
		return clOrdId;
	}

	private void addSanitized() {
		if (!_mgr.isLoggedIn()) return;
		double pendPx = newPrice();
		if (_mm.sanitize(pendPx, _side)) {
			addOrder(pendPx);
		} else {
			// wait
		}
	}

	private void rwtSanitized() {
		if (!_mgr.isLoggedIn()) return;
		double pendPx = newPrice();
		if (_mm.sanitize(pendPx, _side)) {
			rwtOrder(pendPx);
		} else {
			delOrder();
		}
	}

	public void handleMidChange(double mid) {
		_mid = mid;
		if (_currStatus == OrderStatus.DELETING) {
			// wait for the DEL ACK/NAK
		} else if (_currStatus == OrderStatus.NULL && _pendStatus == OrderStatus.NULL) { // nothing active or pending
			if (isHitExpired()) {
				addSanitized();
			} else {
				// wait some more
			}
		} else { // something active or pending
			if (isHitExpired()) {
				rwtSanitized();
			} else {
				// wait some more
			}
		}
	}

	public void handleMarketDataSnapshot() {
		if (_currStatus == OrderStatus.DELETING) {
			// wait for the DEL ACK/NAK
		} else if (_currStatus == OrderStatus.NULL && _pendStatus == OrderStatus.NULL) { // nothing active or pending
			if (isHitExpired()) {
				addSanitized();
			} else {
				// wait some more
			}
		} else { // something active or pending
			if (!_mm.sanitize(latestPx(), _side)) {
				delOrder();
			} else {
				// leave order as is
			}
		}
	}

	public void handleOrderResponse(OrderObj response) {
		MadrigalReqType reqType = response.getReqType();
		if (reqType == DEL) {
			if (response.isFtDone()) {
				_currStatus = OrderStatus.NULL; _currPx = Double.NaN;
				if (whenHitIgnore()) {
					addSanitized();
				} else {
					setHitExpiryTime();
				}
			} else {
				// if not able to DELete then let it FILL
				// if already completed then ignore
			}
		} else { // ADD or RWT
			MadrigalOrdStatus status = response.getStatus();
			if (status == ACK) {
				_currStatus = OrderStatus.ACKED; _currPx = response.getPrice();
				if (response.getClOrdId().equals(_pendClOrdId)) { // latest order
					_pendStatus = OrderStatus.NULL; _pendPx = Double.NaN; _pendClOrdId = null; // nothing pending any more
				} else {
					// ignore responses for non latest requests
				}
			} else if (status == NAK) {
				if (response.getClOrdId().equals(_pendClOrdId)) { // latest order
					_pendStatus = OrderStatus.NULL; _pendPx = Double.NaN; _pendClOrdId = null; // nothing pending any more
				} else {
					// ignore responses for non latest requests
				}
			} else if (response.isFtDone()) { // first time when order is complete
				_currStatus = OrderStatus.NULL; _currPx = Double.NaN;
				if (whenHitIgnore()) {
					addSanitized(); // right away
				} else { // wait
					setHitExpiryTime();
				}
			} else if (!response.isDone()) { // genuine partial FILL
				if (whenHitIgnore()) {
					// leave order there
				} else {
					setHitExpiryTime();
					if (_pullWhenHit) {
						delOrder();
					} else { // widenWhenHit
						rwtSanitized();
					}
				}
			}
		}
	}

}
