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

package net.a_cappella.madrigal.lh.om;

import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import net.a_cappella.madrigal.common.obj.OrderObj;

import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.IOC;

public class Immutables {
	// invariants
	private String _uid;
	private String _ecnUid;
	private String _instrId;
	private String _ecnInstrId;
	private MadrigalTimeInForce _tif;
	private MadrigalSide _side;
	private boolean _useNative;

	// ids
	private String _ordId;

	// synthetic
	private ImmutableType _immutableType;

	public void extract(OrderObj order) {
		// invariants
		_uid = order.getUid();
		_ecnUid = order.getEcnUid();
		_instrId = order.getInstrId();
		_ecnInstrId = order.getEcnInstrId();
		_tif = order.getTimeInForce();
		_side = order.getSide();
		_useNative = order.isUseNative();

		// ids
		_ordId = order.getOrdId();

		// synthetic
		if (IOC == _tif) {
			_immutableType = ImmutableType.IOC;
		} else if (order.getShownQty()==0.0) {
			_immutableType = ImmutableType.SNIPER;
		} else {
			_immutableType = ImmutableType.NORMAL;
		}
	}

	public void restore(OrderObj order) {
		// invariants
		order.setUid(_uid);
		order.setEcnUid(_ecnUid);
		order.setInstrId(_instrId);
		order.setEcnInstrId(_ecnInstrId);
		order.setTimeInForce(_tif);
		order.setSide(_side);
		order.setUseNative(_useNative);

		// ids
		order.setOrdId(_ordId);
	}

	public String getEcnUid() {
		return _ecnUid;
	}

	public MadrigalTimeInForce getTif() {
		return _tif;
	}

	public MadrigalSide getSide() {
		return _side;
	}

	public boolean isUseNative() {
		return _useNative;
	}

	public ImmutableType getImmutableType() {
		return _immutableType;
	}

	@Override
	public String toString() {
		return "Immutables [_uid=" + _uid + ", _ecnUid=" + _ecnUid + ", _instrId=" + _instrId + 
               ", _ecnInstrId=" + _ecnInstrId + ", _tif=" + _tif + ", _side=" + _side + 
               ", _ordId=" + _ordId + ", _immutableType=" + _immutableType + ", _useNative=" + _useNative + "]";
	}
}
