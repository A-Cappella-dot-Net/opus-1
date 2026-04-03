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

import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class EcnCredentialsCache {
    private static final Logger log = LoggerFactory.getLogger(EcnCredentialsCache.class);

    protected PrestoClient _client;

    private String _ecnCredentialsSubSql; // user.dir
    public void setEcnCredentialsSubSql(String ecnCredentialsSubSql) {
        _ecnCredentialsSubSql = ecnCredentialsSubSql;
    }

    /** uid->credentials mapping */
    protected Map<String, EcnCredentialsObj> _credentialsCache = new HashMap<>();
    public EcnCredentialsObj getCredentials(String uid) {
        return _credentialsCache.get(uid);
    }

    public EcnCredentialsCache(PrestoClient client) {
    	_client = client;
    }

    public void init() {
        try {
        	_client.snapSubscribe(_ecnCredentialsSubSql, (obj, subsId) -> {
                EcnCredentialsObj credentials = (EcnCredentialsObj) obj;
                String uid = credentials.getUid();
                String ecn = credentials.getEcn();
                String ecnUid = credentials.getEcnUid();
                String ecnPwd = credentials.getEcnPwd();
                long opTime = credentials.getTs();
                if (log.isDebugEnabled()) log.debug("got credentials for: "+uid+" "+ecn+" "+ecnUid+"/"+ecnPwd+" "+opTime);
                _credentialsCache.put(uid, credentials);
        	});
        } catch (Exception e) {
            log.error("", e);
        }

    }
}
