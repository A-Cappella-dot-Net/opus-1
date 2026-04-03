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

package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;
import net.a_cappella.madrigal.common.constants.MadrigalGatewayType;
import net.a_cappella.madrigal.common.constants.MadrigalMarketStatus;
import net.a_cappella.madrigal.common.obj.MarketStatusObj;

import java.util.Map;

public class CukeMarketStatus {
	String ecn;
	String gwt;
	String status;

	@DataTableType
	public static CukeMarketStatus cukeMarketStatusEntry(Map<String, String> entry) {
		CukeMarketStatus cms = new CukeMarketStatus();
		cms.ecn = entry.get("ecn");
		cms.gwt = entry.get("gwt");
		cms.status = entry.get("status");
		return cms;
	}

	public String getEcn() {
		return ecn;
	}
	public String getGwt() {
		return gwt;
	}
	public String getStatus() {
		return status;
	}

	public MarketStatusObj of() {
		MarketStatusObj obj = new MarketStatusObj();
		obj.set(ecn, MadrigalGatewayType.valueOf(gwt), MadrigalMarketStatus.valueOf(status), System.currentTimeMillis());
		return obj;
	}
}
