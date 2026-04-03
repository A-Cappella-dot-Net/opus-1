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

package net.a_cappella.mcache;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import net.a_cappella.presto.obj.CacheCmdObj;
import net.a_cappella.presto.ps.sql.SqlParser;
import net.a_cappella.presto.ps.sql.WhereNode;
import net.a_cappella.presto.structs.of.poolables.MapOfObjByObjKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.function.Consumer;

public class KeyBasedObjCache implements IObjCache {
    private static final Logger log = LoggerFactory.getLogger(KeyBasedObjCache.class);

    private String _subj;
    private final MapOfObjByObjKey _mapByKey = new MapOfObjByObjKey(new HashMap<>());

    @Override
	public void onSubscriptionMessage(Obj obj, long subsId) {
        ObjKey key = obj.getObjKey();
       	_mapByKey.put(key, obj);
        log.debug("add {} {} {}", _subj, key, obj);
	}

    @Override
    public void publishSnapRecords(Consumer<Obj> consumer) {
    	_mapByKey.values().forEach(consumer);
    }

    @Override
    public void onCacheCmdMessage(CacheCmdObj obj) {
    	String command = obj.getCommand();
    	switch (command) {
    	case ManagedCache.CMD_CLEAN:
        	String whereClause = obj.getWhereClause();
        	if (whereClause==null) _mapByKey.clear();
        	else {
    			try {
    	            WhereNode whereNode = SqlParser.parseWhereClause(whereClause);
    	            if (whereNode==null) _mapByKey.clear();
    	            else _mapByKey.removeIf(o -> whereNode.satisfiesWhereClause(o));
    			} catch (Exception e) {
    	            log.error("", e);
    			}
        	}
    		break;
    	case ManagedCache.CMD_LOG:
    		log();
    		break;
    	default:
    		log.warn("Unrecognized command {}", command);
    	}
    }

    @Override
    public void log() {
        log.info(_mapByKey.toString());
    }
}
