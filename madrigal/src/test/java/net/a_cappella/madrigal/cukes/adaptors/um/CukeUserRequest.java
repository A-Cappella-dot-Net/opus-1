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
import net.a_cappella.madrigal.common.obj.UserStatusObj;

import java.util.Map;

public class CukeUserRequest {
	private String uid;
	private String pwd;
	private String clId;
	private String op;
	private boolean rejectIfLoggedIn;
	private boolean forceLogout;

	@DataTableType
	public CukeUserRequest dttCukeUserRequest(Map<String, String> entry) {
		CukeUserRequest cur = new CukeUserRequest();
		cur.uid = entry.get("uid");
		cur.pwd = entry.get("pwd");
		cur.clId = entry.get("clId");
		cur.op = entry.get("op");
		cur.rejectIfLoggedIn = Boolean.parseBoolean(entry.get("rejectIfLoggedIn"));
		cur.forceLogout = Boolean.parseBoolean(entry.get("forceLogout"));
		return cur;
	}

	public String getUid() {
		return uid;
	}
	public String getPwd() {
		return pwd;
	}
	public String getClId() {
		return clId;
	}
	public String getOp() {
		return op;
	}
	public boolean isRejectIfLoggedIn() {
		return rejectIfLoggedIn;
	}
	public boolean isForceLogout() {
		return forceLogout;
	}

	public UserStatusObj of() {
		UserStatusObj obj = new UserStatusObj();
		obj.setRequest(uid, clId, 0, MadrigalLogOp.valueOf(op), pwd, rejectIfLoggedIn, forceLogout, System.currentTimeMillis());
		return obj;
	}
}
