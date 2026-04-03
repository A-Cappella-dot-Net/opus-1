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

package net.a_cappella.madrigal;

import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.structs.of.poolables.MapOfPoolable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;

public class InstrumentCache implements IInstrumentCache {
    private static final Logger log = LoggerFactory.getLogger(InstrumentCache.class);

    protected PrestoClient _client;

    private final String _ecn;
    public String getEcn() {
    	return _ecn;
    }

    private String _instrumentSubSql = "select * from ecn.instrument where ecn='%s'";
    public void setInstrumentSubSql(String instrumentSubSql) {
        _instrumentSubSql = instrumentSubSql;
    }

    protected MapOfPoolable<String, EcnInstrumentObj> _instrumentCache =
        	new MapOfPoolable<>(new ConcurrentHashMap<>()); // <instrId, EcnInstrumentObj>

    public InstrumentCache(PrestoClient client, String ecn) {
    	_client = client;
    	_ecn = ecn;
    }

    public void init() {
    	_client.waitUntilInitialized();
        try {
            _client.snapSubscribe(String.format(_instrumentSubSql, _ecn), (obj, subsId) -> {
                EcnInstrumentObj instr = (EcnInstrumentObj) obj;
                // TODO what to do when instrument rolls? reinitialize cache?
                String instrId = instr.getSecurityID();
                _instrumentCache.put(instrId, instr);
            });
        } catch (Exception e) {
            log.error("", e);
        }
    }

    public String getEcnInstrId(String instrId) {
    	EcnInstrumentObj instr = _instrumentCache.get(instrId);
    	if (instr==null) return null;
    	String symbol = instr.getSymbol();
    	instr.stopUsing();
    	return symbol;
    }

    public EcnInstrumentObj getEcnInstr(String instrId) {
    	return _instrumentCache.get(instrId);
    }
}
