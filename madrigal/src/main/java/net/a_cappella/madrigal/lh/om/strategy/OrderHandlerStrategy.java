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

package net.a_cappella.madrigal.lh.om.strategy;

import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.lh.om.OrderHandler;

import static net.a_cappella.madrigal.common.constants.MadrigalConstants.VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY;

public abstract class OrderHandlerStrategy implements IOrderHandlerStrategy {

	@Override
	public String getLabel() {
		return this.getClass().getSimpleName();
	}

	@Override
	public String validateAddRequest(OrderObj request, OrderHandler handler) {
		double qty = request.getOrderQty();
		if (request.getShownQty() > 0.0) qty = request.getShownQty();
		EcnInstrumentObj ecnInstr = handler.getRootHandler().getService().getInstrumentCache().getEcnInstr(request.getInstrId());
		return (qty < ecnInstr.getMinQty()) ? VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY : null;
	}

	@Override
	public String validateRwtRequest(OrderObj request, OrderHandler handler) {
		double qty = request.getOrderQty();
		if (request.getShownQty() > 0.0) qty = request.getShownQty();
		EcnInstrumentObj ecnInstr = handler.getRootHandler().getService().getInstrumentCache().getEcnInstr(request.getInstrId());
		return (qty < ecnInstr.getMinQty()) ? VAL_ERR_RESIDUAL_LESS_THAN_MIN_QTY : null;
	}

	@Override
	public String validateDelRequest(OrderObj request, OrderHandler handler) {
		return null;
	}

	@Override
	public void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj request) {
	}

	@Override
	public void onFtDone(OrderHandler handler) {
	}

}
