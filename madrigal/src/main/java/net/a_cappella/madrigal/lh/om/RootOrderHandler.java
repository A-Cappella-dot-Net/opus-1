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

import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.constants.MadrigalReqType;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.lh.om.logic.DelRetryType;
import net.a_cappella.madrigal.lh.om.strategy.IOrderHandlerStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collection;
import java.util.List;

public class RootOrderHandler implements IOrderHandler {
    private static final Logger log = LoggerFactory.getLogger(RootOrderHandler.class);

    private final OrderManagerService _service;
	private final String _ecn;

	private final Immutables _immutables = new Immutables();
	private OrderHandler _handler;

	public RootOrderHandler(OrderManagerService service, String ecn, OrderObj order) {
		_service = service;
		_ecn = ecn;
		_immutables.extract(order);
	}

    public OrderManagerService getService() {
    	return _service;
    }
	public Immutables getImmutables() {
		return _immutables;
	}
	public OrderHandler getHandler() {
		return _handler;
	}

	@Override // IOrderRequestHandler
	public void handleAddRequest(OrderObj request) {
		if (log.isDebugEnabled()) log.info("0 handleAddRequest {}", request);
		IOrderHandlerStrategy rootStrategy = _service.getOmsParams().getStrategy(_immutables);
		_handler = new OrderHandler(0); // TODO use managed objects
		_handler.setReqVer(request.getVer());
		_handler.set(this, this, rootStrategy, request.getOrdId());
		_handler.handleAddRequest(request);
	}

	@Override // IOrderRequestHandler
	public void handleRwtRequest(OrderObj request) {
		_immutables.restore(request);
		if (log.isDebugEnabled()) log.info("0 handleRwtRequest {}", request);
		_handler.setReqVer(request.getVer());
		_handler.handleRwtRequest(request);
	}

	@Override // IOrderRequestHandler
	public void handleDelRequest(OrderObj request) {
		_immutables.restore(request);
		if (log.isDebugEnabled()) log.info("0 handleDelRequest {}", request);
		_handler.setReqVer(request.getVer());
		_handler.handleDelRequest(request);
	}

	@Override // IOrderResponseHandler
	public void handleResponse(OrderObj response) {
		if (log.isDebugEnabled()) log.info("0 handleResponse {}", response);
		response.setEcn(_ecn); // this message goes out to the client
		if (response.getVer() == 0 && response.getReqType() == MadrigalReqType.DEL && response.getStatus() == MadrigalOrdStatus.ACK) {
			response.setStatus(MadrigalOrdStatus.CXL);
		}
		_service.publishResponse(response);
		if (response.isFtDone()) {
			_service.finalizeHandler(response.getOrdId());
		}
	}

	public void activateOrder(OrderObj state, List<OrderObj> queuedList, Collection<OrderObj> fills) {
		if (log.isDebugEnabled()) log.info("0 activateOrder {} queuedList={} fills={}", state, queuedList, fills);

		IOrderHandlerStrategy rootStrategy = _service.getOmsParams().getStrategy(_immutables);
		// TODO use managed objects
		_handler = new OrderHandler(state, 0); // this resets the mode to RESPONSE

		_handler.set(this, this, rootStrategy, state.getOrdId());
		_handler.activateOrder(queuedList, fills);
	}

	public DelRetryType getDelRetryType() {
		return _service.getOmsParams().getDelRetryType();
	}
	public int getDelRetryConstant() {
		return _service.getOmsParams().getDelRetryConstant();
	}
	public IOrderHandlerStrategy getNativeStrategy() {
		return _service.getOmsParams().getNativeStrategy();
	}
	public IOrderHandlerStrategy getIocStrategy() {
		return _service.getOmsParams().getSimulatedIocStrategy();
	}
	public IOrderHandlerStrategy getSniperStrategy() {
		return _service.getOmsParams().getSniperStrategy();
	}
	public IOrderHandlerStrategy getSimulatedIbgRwtStrategy() {
		return _service.getOmsParams().getSimulatedIbgRwtStrategy();
	}
	public IOrderHandlerStrategy getResumeOnFailoverStrategy() {
		return _service.getOmsParams().getResumeOnFailoverStrategy();
	}
}
