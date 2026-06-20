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

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.madrigal.common.obj.OrderObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.function.Consumer;

public class OrderState {
    private static final Logger log = LoggerFactory.getLogger(OrderState.class);

    private OrderObj _state;
	private final List<OrderObj> _queuedList = new ArrayList<>();
	private final Map<String, OrderObj> _unprocessedFills = new HashMap<>();

	public OrderObj getState() {
		return _state;
	}

	public Collection<OrderObj> getUnprocessedFills() {
		return _unprocessedFills.values();
	}

	public List<OrderObj> getQueuedList() {
		return _queuedList;
	}

	public void onRequest(OrderObj request, boolean snapComplete) {
		// TODO handle dup requests (already in OrderState)
		if (_state == null) {
			_state = ObjectManager.getInstance().acquire(MadrigalConstants.TYPE_ORDER);
			_state.set(request);
			_state.setMadrigalMode(MadrigalMode.RESPONSE);
		}
		addRequestToQueued(request);
		log("REQ", request, snapComplete);
	}
	private void addRequestToQueued(OrderObj request) {
		request.startUsing();
		for (int i=0; i<_queuedList.size(); i++) { // list is sorted ascending by version
			OrderObj crt = _queuedList.get(i);
			if (request.getVer() == crt.getVer()) return; // duplicate
			if (request.getVer() > crt.getVer()) continue;
			// request.getVer() < crt.getVer()
			_queuedList.add(i, request);
			return;
		}
		_queuedList.add(request);
	}

	public void onResponse(OrderObj response, boolean snapComplete) {
		// processed RESPONSE
		if (MadrigalOrdStatus.NAK == response.getStatus()) {
			removeRequestFromQueued(response);
		} else if (MadrigalOrdStatus.ACK == response.getStatus()) {
			removeRequestFromQueued(response);
			replaceStateWith(response);
		} else if (MadrigalOrdStatus.FILL == response.getStatus()) {
			replaceStateWith(response);
			OrderObj unprocessedFill = _unprocessedFills.remove(response.getFillId()); // the FILL has been processed
			if (unprocessedFill != null) unprocessedFill.stopUsing();
		} else if (MadrigalOrdStatus.DONE == response.getStatus()) {
			replaceStateWith(response);
		}
		log("RSP", response, snapComplete);
	}

	public void onUnprocessedFill(OrderObj response, boolean snapComplete) {
		// response.getStatus() == MadrigalOrdStatus.FILL
		_unprocessedFills.put(response.getFillId(), response);
		response.startUsing();
		log("FIL", response, snapComplete);
	}

	private void removeRequestFromQueued(OrderObj response) {
		for (int i=0; i<_queuedList.size(); i++) {
			OrderObj obj = _queuedList.get(i);
			if (obj.getVer() == response.getVer()) {
				OrderObj queued = _queuedList.remove(i);
				queued.stopUsing();
				return;
			}
		}
	}

	public void publishStateSnapshot(Consumer<Obj> consumer) {
		log.info("================== publishStateSnapshot");
		log();
		consumer.accept(_state);
		_queuedList.forEach(consumer);
		_unprocessedFills.values().forEach(consumer);
	}

	public void log() {
		log.info("  state: {}", _state);
		if (_queuedList.size() > 0) {
			log.info("  queued:");
			for (int i=0; i<_queuedList.size(); i++) {
				OrderObj req = _queuedList.get(i);
				log.info("    {}", req);
			}
		}
		if (_unprocessedFills.size() > 0) {
			log.info("  unprocessed fills:");
			Iterator<OrderObj> iterator = _unprocessedFills.values().iterator();
			do {
				OrderObj fill = iterator.next();
				log.info("    {}", fill);
			} while (iterator.hasNext());
		}
	}

	private void log(String objType, OrderObj order, boolean snapComplete) {
		if (log.isDebugEnabled()) {
			if (order.getPubType() == PubType.SNP_MSG)
				log.info("..................");
			else if (snapComplete)
				log.info("==================");
			else
				log.info("------------------");

			log.info("{} {}", objType, order);
			log();
		}
	}

	private void replaceStateWith(OrderObj response) {
		if (_state != null) _state.stopUsing();
		_state = response;
		_state.startUsing();
	}

	public void finalizeOrderState() {
		if (log.isDebugEnabled()) {
			log.info("=== finalizeOrderState: {}", _state);
		}
		_state.stopUsing();
		_state = null;
		for (int i=0; i<_queuedList.size(); i++) {
			_queuedList.get(i).stopUsing();
		}
		_queuedList.clear();
		if (_unprocessedFills.size() > 0) { // TODO no garbage
			Iterator<OrderObj> iterator = _unprocessedFills.values().iterator();
			do {
				iterator.next().stopUsing();
			} while (iterator.hasNext());
		}
		_unprocessedFills.clear();
	}
}
