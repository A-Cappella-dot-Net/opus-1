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

import net.a_cappella.madrigal.common.obj.CredentialsObj;
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

public class CredentialsCache implements ICredentialsCache {
    private static final Logger log = LoggerFactory.getLogger(CredentialsCache.class);

    protected PrestoClient _client;

    private final String _ecn;
    public String getEcn() {
    	return _ecn;
    }

    private String _credentialsSubSql = "select * from credentials";
    public void setCredentialsSubSql(String credentialsSubSql) {
        _credentialsSubSql = credentialsSubSql;
    }

    private String _ecnCredentialsSubSql = "select * from ecn.credentials where ecn='%s'";
    public void setEcnCredentialsSubSql(String ecnCredentialsSubSql) {
        _ecnCredentialsSubSql = ecnCredentialsSubSql;
    }

    protected Map<String, CredentialsObj> _credentialsCache = new HashMap<>();
    protected Map<String, EcnCredentialsObj> _ecnCredentialsCache = new HashMap<>();

    // TODO may wish to handle adds / deletes / updates

    public CredentialsCache(PrestoClient client, String ecn) {
    	_client = client;
    	_ecn = ecn;
    }

    public void init() {
    	_client.waitUntilInitialized();
        try {
        	_client.snapSubscribe(_credentialsSubSql, (obj, subsId) -> {
                CredentialsObj credentials = (CredentialsObj) obj;
                if (log.isDebugEnabled()) log.debug("got "+credentials);
                _credentialsCache.put(credentials.getUid(), credentials);
        	});

        	_client.snapSubscribe(String.format(_ecnCredentialsSubSql, _ecn), (obj, subsId) -> {
                EcnCredentialsObj credentials = (EcnCredentialsObj) obj;
                if (log.isDebugEnabled()) log.debug("got "+credentials);
                _ecnCredentialsCache.put(credentials.getUid(), credentials);
        	});
        } catch (Exception e) {
            log.error("", e);
        }
    }

    @Override
	public EcnCredentialsObj getEcnCredentials(String uid) {
		return _ecnCredentialsCache.get(uid);
	}

	public CredentialsObj getCredentials(String uid) {
		return _credentialsCache.get(uid);
	}
}
