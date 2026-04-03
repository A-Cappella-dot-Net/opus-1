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

package net.a_cappella.madrigal.om.logic;

public class DelNakRetryManager {

	private final DelRetryType _delRetryType;
	private final int _delRetryConstant;

	private int _delRetryCount;
	private long _delRetryTimeout;

	public DelNakRetryManager(DelRetryType delRetryType, int delRetryConstant) {
		_delRetryType = delRetryType;
		_delRetryConstant = delRetryConstant;
	}

	public void initCancelRetryLogic() {
		if (_delRetryType == DelRetryType.COUNT) {
			_delRetryCount = _delRetryConstant;
		} else { // TIMEOUT
			_delRetryTimeout = System.currentTimeMillis() + _delRetryConstant;
			_delRetryCount = 0;
		}
	}

	public boolean okToRetryCancel() {
		if (_delRetryType == DelRetryType.DISABLED) return false;

		if (_delRetryType == DelRetryType.COUNT) {
			return --_delRetryCount >= 0;
		} else { // TIMEOUT
			_delRetryCount++;
			return System.currentTimeMillis() >= _delRetryTimeout;
		}
	}
}
