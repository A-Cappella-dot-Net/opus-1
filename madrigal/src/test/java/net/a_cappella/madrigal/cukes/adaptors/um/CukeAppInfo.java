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
import net.a_cappella.continuo.collective.AppInfo;

import java.util.Map;

public class CukeAppInfo {
	private short instance;

	@DataTableType
	public static CukeAppInfo dttCukeAppInfo(Map<String, String> entry) {
		CukeAppInfo cai = new CukeAppInfo();
		cai.instance = Short.parseShort(entry.get("instance"));
		return cai;
	}

	public short getInstance() {
		return instance;
	}

	public AppInfo of() {
		return new AppInfo("userservice", (short) -1, instance);
	}
}
