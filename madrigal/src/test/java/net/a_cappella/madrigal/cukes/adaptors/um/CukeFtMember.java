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
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.FtMemberObj;

import java.util.Map;

public class CukeFtMember {
	private int instance;
	private String action;

	@DataTableType
	public static CukeFtMember cukeFtMemberEntry(Map<String, String> entry) {
		CukeFtMember cfm = new CukeFtMember();
		cfm.instance = Integer.parseInt(entry.get("instance"));
		cfm.action = entry.get("action");
		return cfm;
	}

	public int getInstance() {
		return instance;
	}

	public String getAction() {
		return action;
	}

	public FtMemberObj of() {
		FtMemberObj obj = new FtMemberObj();
		obj.set("groupName", instance, FtMsgOp.valueOf(action), 0, 1, System.currentTimeMillis());
		return obj;
	}
}
