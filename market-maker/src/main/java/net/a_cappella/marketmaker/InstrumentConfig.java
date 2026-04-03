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

package net.a_cappella.marketmaker;

public class InstrumentConfig {
	public String _instrId;
	public int _normalSpreadTicks;
	public int _wideSpreadTicks;
	public int _whenHitInterval;
	public boolean _pullOrderWhenHit;
	public double _bidSize;
	public double _askSize;
	public int _sniperInterval;
	public double _tobFraction = Double.NaN;

	public InstrumentConfig(String instrument) {
		// 912828Q45:1-3-5000-false:10-10
		String[] components = instrument.split(":");
		_instrId = components[0];
		String[] pair = components[1].split("-");
		_normalSpreadTicks = Integer.parseInt(pair[0]);
		_wideSpreadTicks = Integer.parseInt(pair[1]);
		_whenHitInterval = Integer.parseInt(pair[2]);
		_pullOrderWhenHit = (pair.length>3) ? Boolean.parseBoolean(pair[3]) : true;
		pair = components[2].split("-");
		_bidSize = Double.parseDouble(pair[0]);
		_askSize = Double.parseDouble(pair[1]);
		if (components.length>3) {
    		// 912828Q45:1-3-5000:10-10:2000-0.25
    		pair = components[3].split("-");
    		_sniperInterval = Integer.parseInt(pair[0]);
    		_tobFraction = Double.parseDouble(pair[1]);
		}
	}
}
