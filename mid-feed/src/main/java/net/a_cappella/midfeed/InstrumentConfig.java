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

package net.a_cappella.midfeed;

public class InstrumentConfig {
	public String _instrId;
	public double _minPriceTick;
	public double _midPrice;
	public long _minTimeout;
	public long _maxTimeout;

	public InstrumentConfig(String str) {
		String[] comps = str.split("\\|");
		_instrId = comps[0];
		_minPriceTick = Double.parseDouble(comps[1]);
		_midPrice = Double.parseDouble(comps[2]);
		_minTimeout = Long.parseLong(comps[3]);
		_maxTimeout = Long.parseLong(comps[4]);
	}

	public double randomMid() {
        double rand = Math.random();
        int ticks = (rand < 0.3333)?-1:(rand>0.6666)?1:0;
		return _midPrice + ticks * _minPriceTick;
	}

	public long randomDelay() {
		return _minTimeout + (long) (Math.random() * (_maxTimeout - _minTimeout));
	}

	public String toString() {
		return _instrId+"|"+_minPriceTick+"|"+_midPrice+"|"+_minTimeout+"|"+_maxTimeout;
	}
}
