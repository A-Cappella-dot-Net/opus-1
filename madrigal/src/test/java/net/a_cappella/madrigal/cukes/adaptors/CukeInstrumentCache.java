package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.IInstrumentCache;
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
