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

import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.test.madrigal.ox.OrderExerciser.MDSnapshot;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;

public abstract class AbstractFeatureExerciser implements IFeatureExerciser {
    private static final Logger log = LoggerFactory.getLogger(AbstractFeatureExerciser.class);
    private static final boolean AMEND_EVEN_WHEN_NEWQTY_LESS_THAN_CUMQTY = true;

    private final int _loginDelayMillis = 1_000;
    private final int _waitToAddDelayMillis = 2_000;
    private final int _addDelayMillis = 1_000;
    private final int _rwtDelDelayMillis = 1_000;
    private final int _doneDelayMillis = 1_000;

    private enum State {
    	WAIT_FOR_LOGIN, WAIT_TO_ADD, ADD, RWT_DEL, WAIT_FOR_DONE
    }

    protected OrderExerciser _ox;

    private final boolean _useNative;

    private final String[] _versions;

    private final boolean _repeat;
    private final double[] _orderQtys;
    private final double[] _shownQtys;
    private final int[] _randomMaxs;
    /**
     * price changes in ticks
     * positive value means more aggressive, negative means more passive, zero means no price change and is the default
     */
    private final int[] _priceChgs; // in number of ticks

	private int _seqIx = 0;

    private double _orderQty;
    private double _shownQty;
    private int _randomMax;

    protected boolean _burst;
    protected boolean _passive;
    protected boolean _sendDel;

    private long _cutoff;
    private State _state = State.WAIT_FOR_LOGIN;

    private String _ordId;
    private String _instrId;
    private MadrigalSide _side;
    private double _price;

    private boolean _delSent;
    private double _cumQty;

    protected int _featureCount = -1;
    protected boolean[][] _featureParams = {
    	{true,  true,  true},
    	{false, true,  true},
    	{true,  false, true},
    	{false, false, true},
    	{true,  true,  false},
    	{false, true,  false},
    	{true,  false, false},
    	{false, false, false},
    };

    public AbstractFeatureExerciser(boolean useNative, String versionsSequence) {
    	_useNative = useNative;

    	// 7:2:2,9:3,11:2@-1,12:3@1,*
    	_versions = versionsSequence.split(",");
        int len = _versions.length;
        String lastToken = _versions[len-1].trim();
        if ("*".equals(lastToken)) {
        	_repeat = true;
        	len--;
        } else {
        	_repeat = false;
        }
        _orderQtys = new double[len];
        _shownQtys = new double[len];
    	_randomMaxs = new int[len];
    	_priceChgs = new int[len];

    	parseVersionsSequence(_versions, len);
    }

    private void parseVersionsSequence(String[] versions, int len) {
    	for (int i=0; i<len; i++) {
    		String[] sizesAndPriceChanges = versions[i].split("@");
        	String[] sizes = sizesAndPriceChanges[0].split(":");
        	if (sizes.length>=2) {
            	_orderQtys[i] = Double.parseDouble(sizes[0].trim());
            	_shownQtys[i] = Double.parseDouble(sizes[1].trim());
            	if (sizes.length>=3) {
            		_randomMaxs[i] = Integer.parseInt(sizes[2].trim());
            	} else {
            		_randomMaxs[i] = 0;
            	}
        	} else {
        		double size = Double.parseDouble(sizes[0].trim());
            	_orderQtys[i] = _shownQtys[i] = size;
        		_randomMaxs[i] = 0;
        	}
    		if (sizesAndPriceChanges.length>=2) {
    			_priceChgs[i] = Integer.parseInt(sizesAndPriceChanges[1].trim());
    		} else {
    			_priceChgs[i] = 0;
    		}
        }
    }

    @Override
	public void setOx(OrderExerciser ox) {
		_ox = ox;
	}

    @Override
    public MDSnapshot selectInstrMds() {
    	return _ox.mostActiveMds();
    }

    @Override
    public void set(String instrId, MadrigalSide side, double price) {
    	_instrId = instrId;
        _side = side;
        _price = price;
    	_seqIx = 0;
    	setCurrentParams();
    }

    private void setCurrentParams() {
    	_orderQty = _orderQtys[_seqIx];
    	_shownQty = _shownQtys[_seqIx];
    	_randomMax = _randomMaxs[_seqIx];
    }

    private boolean nextPlannedRwt() {
    	_seqIx++;
    	if (_seqIx < _orderQtys.length) {
    		setCurrentParams();
    		return true;
    	}
    	if (_repeat && !_sendDel && !_burst) {
    		_seqIx = 0;
    		setCurrentParams();
    		return true;
    	}
    	return false;
    }

    protected double price() {
    	int priceChgTicks = _priceChgs[_seqIx];
    	if (priceChgTicks == 0) {
    		return _price;
    	}
    	double priceChg = priceChgTicks * _ox.getMinPriceTick(_instrId);
    	if (Buy == _side) {
    		return _price + priceChg;
    	} else {
    		return _price - priceChg;
    	}
    }

    protected String instrId() {
    	return _instrId;
    }

    protected MadrigalSide side() {
    	return _side;
    }

    protected double orderQty() {
    	return _orderQty;
    }

    protected double shownQty() {
    	return _shownQty;
    }

    protected int randomMax() {
    	return _randomMax;
    }

    private void setState(State state, String msg) {
    	setState(state, 0, msg);
    }
    private void setState(State state, long delayMillis) {
    	setState(state, delayMillis, null);
    }
    private void setState(State state, long delayMillis, String msg) {
    	if (_state != state) {
        	if (msg!=null) {
            	log.info("{}->{} {}", _state, state, msg);
        	}
    	}
    	_state = state;
    	if (delayMillis>0) {
    		_cutoff = System.currentTimeMillis() + delayMillis;
    	}
    }

    public void evalState() {
		switch (_state) {
		case WAIT_FOR_LOGIN:
			if (System.currentTimeMillis() > _cutoff) {
				if (_ox.isLoggedIn()) {
					setState(State.WAIT_TO_ADD, _waitToAddDelayMillis, "Logged In");
				} else {
					setState(State.WAIT_FOR_LOGIN, _loginDelayMillis);
				}
			}
			break;
		case WAIT_TO_ADD:
			if (System.currentTimeMillis() > _cutoff) {
				setState(State.ADD, "Ready for new order");
			}
			break;
		case ADD:
			if (System.currentTimeMillis() > _cutoff) {
				if (_ox.isLoggedIn()) {
					if (sendNewOrder()) {
						setState(State.RWT_DEL, (_burst) ? 0 : _rwtDelDelayMillis);
					} else {
						setState(State.ADD, _addDelayMillis);
					}
				} else {
					setState(State.WAIT_FOR_LOGIN, _loginDelayMillis);
				}
			}
			break;
		case RWT_DEL:
			if (System.currentTimeMillis() > _cutoff) {
				if (_ox.isLoggedIn()) {
					if (sendAmendOrCancel()) {
						setState(State.RWT_DEL, (_burst) ? 0 : _rwtDelDelayMillis);
					} else {
						setState(State.WAIT_FOR_DONE, _doneDelayMillis);
					}
				} else {
					setState(State.WAIT_FOR_LOGIN, _loginDelayMillis);
				}
			}
			break;
		case WAIT_FOR_DONE:
			if (System.currentTimeMillis() > _cutoff) {
				if (!_ox.isLoggedIn()) {
					setState(State.WAIT_FOR_LOGIN, _loginDelayMillis, "Not logged in: giving up");
				} else {
					setState(State.WAIT_FOR_DONE, _doneDelayMillis, "Not done yet: still waiting");
				}
			}
			break;
		}
	}

    public void handleResponse(OrderObj er) {
    	if (er.isFtDone()) {
    		setState(State.WAIT_TO_ADD, _waitToAddDelayMillis);
    	} else if (er.getStatus() == MadrigalOrdStatus.FILL) {
    		_cumQty = er.getCumQty();
    	} else if (er.getReqType() == MadrigalReqType.ADD) {
    		if (er.getStatus() == MadrigalOrdStatus.NAK) {
        		setState(State.WAIT_TO_ADD, _waitToAddDelayMillis);
    		} else { // ACK
    			if (!_burst) {
					setState(State.RWT_DEL, _rwtDelDelayMillis);
    			}
    		}
    	} else { // RWT or DEL
    		if (!_burst) {
				setState(State.RWT_DEL, _rwtDelDelayMillis);
    		}
    	}
    }

    protected String sendOrder(MadrigalOrdType ordType, MadrigalTimeInForce tif) {
    	log.info("{}", this);
        _delSent = false;
        _cumQty = 0;
        String ordId = _ox.nextId();
        _ox.addOrder(ordId, instrId(), side(), ordType, tif, price(), orderQty(), shownQty(), randomMax(), _useNative);
        return ordId;
    }

    private boolean sendNewOrder() {
    	boolean sent = false;
        MDSnapshot mds = selectInstrMds();
        if (mds!=null) {
            boolean validOrder = selectOrderDetails(mds);
            if (validOrder) {
                nextFeatureVariant();
            	_ordId = sendOrder();
            	sent = true;
            } else {
            	log.info("featureExerciser returned invalid order for {}", mds);
            }
        } else {
       		if (log.isDebugEnabled()) log.info("featureExerciser returned NULL mds");
        }
        return sent;
    }

    private boolean sendAmendOrCancel() {
    	boolean sent = false;
    	if (nextPlannedRwt()) { // there are still RWTs to be sent
    		if (AMEND_EVEN_WHEN_NEWQTY_LESS_THAN_CUMQTY) {
                _ox.rwtOrder(_ordId, shownQty(), orderQty(), randomMax(), price());
                sent = true;
    		} else {
				double orderQty = orderQty();
				if (orderQty > _cumQty) { // partially filled
					_ox.rwtOrder(_ordId, shownQty(), orderQty, randomMax(), price());
					sent = true;
				} else { // completely / over filled
					if (_sendDel && !_delSent) {
						_ox.delOrder(_ordId);
						sent = true;
						_delSent = true;
					} // else wait for the order to be done
				}
    		}
    	} else { // all RWTs have been sent
            if (_sendDel && !_delSent) {
                _ox.delOrder(_ordId);
                sent = true;
                _delSent = true;
            } // else wait for the order to be done
    	}
    	return sent;
    }

    private void nextFeatureVariant() {
    	_featureCount = (_featureCount + 1) % _featureParams.length;
    	_burst = _featureParams[_featureCount][0];
    	_sendDel = _featureParams[_featureCount][1];
    	_passive = _featureParams[_featureCount][2];
    }

    public String toString() {
        return _instrId+" "+_side+" ["+_seqIx+"] "+((_seqIx>=_orderQtys.length)?"-":_versions[_seqIx])+"@"+_price+" "+" burst="+_burst+" sendDel="+_sendDel;
    }

}
