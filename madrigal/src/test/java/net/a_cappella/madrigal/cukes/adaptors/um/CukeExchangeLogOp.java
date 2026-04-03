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

import java.util.Map;

public class CukeExchangeLogOp {
	private final String op;
	private final String uid;
	private final String pwd;

	@DataTableType
	public static CukeExchangeLogOp dttCukeExchangeLogOp(Map<String, String> entry) {
		return new CukeExchangeLogOp(
				entry.get("op"),
				entry.get("uid"),
				entry.get("pwd")
		);
	}

	public CukeExchangeLogOp(String op, String uid, String pwd) {
		this.op = op;
		this.uid = uid;
		this.pwd = pwd;
	}

	public String getOp() {
		return op;
	}
	public String getUid() {
		return uid;
	}
	public String getPwd() {
		return pwd;
	}

	@Override
	public String toString() {
		return "CukeExchangeLogOp [op=" + op + ", uid=" + uid + ", pwd=" + pwd + "]";
	}
}
