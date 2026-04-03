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
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;

import java.util.Map;

public class CukeEcnCredentials {
    private final String uid;
    private final String ecn;
    private final String ecnUid;
	private final String ecnPwd;

	@DataTableType
	public static CukeEcnCredentials dttCukeEcnCredentials(Map<String, String> entry) {
		return new CukeEcnCredentials(
				entry.get("uid"),
				entry.get("ecn"),
				entry.get("ecnUid"),
				entry.get("ecnPwd")
		);
	}

	public CukeEcnCredentials(String uid, String ecn, String ecnUid, String ecnPwd) {
		this.uid = uid;
		this.ecn = ecn;
		this.ecnUid = ecnUid;
		this.ecnPwd = ecnPwd;
	}

    public String getUid() {
		return uid;
	}
    public String getEcn() {
		return ecn;
	}
	public String getEcnUid() {
		return ecnUid;
	}
	public String getEcnPwd() {
		return ecnPwd;
	}

	public EcnCredentialsObj of() {
		EcnCredentialsObj creds = new EcnCredentialsObj();
		creds.set(uid, ecn, ecnUid, ecnPwd, 0);
		return creds;
	}
}
