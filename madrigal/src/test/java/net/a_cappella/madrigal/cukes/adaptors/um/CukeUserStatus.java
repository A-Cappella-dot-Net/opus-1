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
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.UserStatusObj;

import java.util.Map;

import static com.google.common.base.Strings.nullToEmpty;

public class CukeUserStatus {
	private String uid;
	private String clId;
	private String op;
	private String status;
	private String reqStatus;
	private String text;

	@DataTableType
	public static CukeUserStatus cukeUserStatusEntry(Map<String, String> entry) {
		CukeUserStatus cus = new CukeUserStatus();
		cus.uid = entry.get("uid");
		cus.clId = entry.get("clId");
		cus.op = entry.get("op");
		cus.status = entry.get("status");
		cus.reqStatus = entry.get("reqStatus");
		cus.text = nullToEmpty(entry.get("text"));
		return cus;
	}

	public String getUid() {
		return uid;
	}
	public String getClId() {
		return clId;
	}
	public String getOp() {
		return op;
	}
	public String getStatus() {
		return status;
	}
	public String getReqStatus() {
		return reqStatus;
	}
	public String getText() {
		return text;
	}

	public UserStatusObj of() {
		UserStatusObj obj = new UserStatusObj();
		obj.setResponse(uid, clId, 0, MadrigalLogOp.valueOf(op), MadrigalUserStatus.valueOf(status), MadrigalUserStatus.valueOf(reqStatus), text, System.currentTimeMillis());
		return obj;
	}
}
