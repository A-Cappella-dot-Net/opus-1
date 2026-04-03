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

package net.a_cappella.madrigal.cukes.adaptors;

import io.cucumber.java.DataTableType;
import net.a_cappella.madrigal.common.constants.MadrigalActionOnFailover;
import net.a_cappella.madrigal.om.logic.DelRetryType;

import java.util.Map;

import static net.a_cappella.madrigal.CukeUtils.*;

public class OrderManagerServiceConfig {
	private DelRetryType delRetryType;
	private Integer delRetryConstant;
	private Boolean nativeIocSupported;
	private Boolean conflateRequests;
	private Boolean processOnePendingRequestAtATime;
	private Boolean useDelAddForPriceChange;
	private Boolean strictRwt;
	private MadrigalActionOnFailover actionOnFailover;

	@DataTableType
	public static OrderManagerServiceConfig dttOrderManagerServiceConfig(Map<String, String> entry) {
		OrderManagerServiceConfig omc = new OrderManagerServiceConfig();

		omc.delRetryType = DelRetryType.getEnumFromName(entry.get("delRetryType"));
		omc.delRetryConstant = parseInteger(entry.get("delRetryConstant"));
		omc.nativeIocSupported = parseBoolean(entry.get("nativeIocSupported"));
		omc.conflateRequests = parseBoolean(entry.get("conflateRequests"));
		omc.processOnePendingRequestAtATime = parseBoolean(entry.get("processOnePendingRequestAtATime"));
		omc.useDelAddForPriceChange = parseBoolean(entry.get("useDelAddForPriceChange"));
		omc.strictRwt = parseBoolean(entry.get("strictRwt"));
		omc.actionOnFailover = parseMadrigalActionOnFailover(entry.get("actionOnFailover"));

		return omc;
    }

	public DelRetryType getDelRetryType(DelRetryType defaultValue) {
		return delRetryType==null ? defaultValue : delRetryType;
	}
	public Integer getDelRetryConstant(Integer defaultValue) {
		return delRetryType==null ? defaultValue : delRetryConstant;
	}

	public boolean isNativeIocSupported(boolean defaultValue) {
		return nativeIocSupported==null ? defaultValue : nativeIocSupported;
	}
	public boolean isConflateRequests(boolean defaultValue) {
		return conflateRequests==null ? defaultValue : conflateRequests;
	}
	public boolean isProcessOnePendingRequestAtATime(boolean defaultValue) {
		return processOnePendingRequestAtATime==null ? defaultValue : processOnePendingRequestAtATime;
	}
	public boolean isUseDelAddForPriceChange(boolean defaultValue) {
		return useDelAddForPriceChange==null ? defaultValue : useDelAddForPriceChange;
	}
	public boolean isStrictRwt(boolean defaultValue) {
		return strictRwt==null ? defaultValue : strictRwt;
	}
	public MadrigalActionOnFailover getActionOnFailover(MadrigalActionOnFailover defaultValue) {
		return actionOnFailover==null ? defaultValue : actionOnFailover;
	}
}
