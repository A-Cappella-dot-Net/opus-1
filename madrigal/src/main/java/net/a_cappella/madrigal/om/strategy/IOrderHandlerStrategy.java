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

package net.a_cappella.madrigal.om.strategy;

import net.a_cappella.madrigal.common.obj.EcnPriceObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.madrigal.om.OrderHandler;

public interface IOrderHandlerStrategy {
	String getLabel();
	boolean isConflateRequests();
	boolean isProcessOnePendingRequestAtATime();
	boolean isStrictRwt();
	String validateAddRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	String validateRwtRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	String validateDelRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleAddRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleRwtRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	void handleDelRequest(OrderObj request, OrderHandler handler); // mode=REQUEST
	OrderObj handleResponse(OrderObj er, OrderHandler handler); // mode=RESPONSE
	void handleEcnPrice(EcnPriceObj ecnPrice, OrderHandler handler, OrderObj request);
	void onFtDone(OrderHandler handler);
}
