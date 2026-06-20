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

import net.a_cappella.madrigal.instrument.IInstrumentCache;
import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;

import java.util.HashMap;
import java.util.Map;

public class CukeInstrumentCache implements IInstrumentCache {
    protected Map<String, CukeEcnInstrument> _instrumentCache = new HashMap<>(); // <instrId, CukeEcnInstrument>
    {
    	_instrumentCache.put("instrId",   new CukeEcnInstrument("instrId",   "ecnInstrId",   0.01, 1000.0, 1.0, 1.0, "ecn"));
    	_instrumentCache.put("instrId.5", new CukeEcnInstrument("instrId.5", "ecnInstrId.5", 0.01, 1000.0, 0.5, 0.5, "ecn"));
    	_instrumentCache.put("instrId5",  new CukeEcnInstrument("instrId5",  "ecnInstrId5",  0.01, 1000.0, 5.0, 1.0, "ecn"));
    }

    public String getEcnInstrId(String instrId) {
    	CukeEcnInstrument instr = _instrumentCache.get(instrId);
    	if (instr==null) return null;
    	String symbol = instr.getSymbol();
    	return symbol;
    }

    public EcnInstrumentObj getEcnInstr(String instrId) {
    	return _instrumentCache.get(instrId).of();
    }
}
