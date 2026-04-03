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

package net.a_cappella.madrigal.common.beans;

import java.util.Map;

public class User {
	private final String _uid;
	private final String _pwd;
	private final Map<String, EcnCredentials> _ecnCredentials;

	public User(String uid, String pwd, Map<String, EcnCredentials> ecnCredentials) {
		_uid = uid;
		_pwd = pwd;
		_ecnCredentials = ecnCredentials;
	}
	public String getUid() {
		return _uid;
	}
	public String getPwd() {
		return _pwd;
	}
	public Map<String, EcnCredentials> getEcnCredentials() {
		return _ecnCredentials;
	}
	public EcnCredentials getEcnCredentials(String ecn) {
		return _ecnCredentials.get(ecn);
	}
}
