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

package net.a_cappella.test.aeron.presto;

import net.a_cappella.continuo.utils.StatsLogger;

public class StatsTestsParams {
    private static final String TAB = StatsLogger.TAB;

    private final int _repeatCnt;
	private int _currentTest;
	private static int _testCnt;
	private final StatsTestParams[] _testParams;

	public StatsTestsParams(final StatsTestParams[] testParams) {
		this(testParams, 5);
	}

	public StatsTestsParams(final StatsTestParams[] testParams, final int repeatCnt) {
		_repeatCnt = repeatCnt;
		_testParams = testParams;
	}

	public void initTestParams() {
		_currentTest = 0;
		_testCnt = 0;
		_testParams[_currentTest].updateTestParams();
	}

	public boolean nextTestParams() {
		if (++_testCnt < _repeatCnt) return true;
		_testCnt = 0;
		_currentTest++;
		if (_currentTest >= _testParams.length) {
			return false;
		}
		_testParams[_currentTest].updateTestParams();
		return true;
	}

	public String currentTestParams() {
		return _testCnt+TAB+_testParams[_currentTest].toString();
	}

	public String header() {
		return "tstCnt"+TAB+_testParams[0].header();
	}
}
