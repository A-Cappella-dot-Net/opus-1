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

import gnu.trove.map.TLongObjectMap;
import gnu.trove.map.hash.TLongObjectHashMap;
import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.madrigal.common.obj.FinalizeOrderObj;
import net.a_cappella.madrigal.common.obj.OrderObj;
import net.a_cappella.presto.ft.collective.IFtMemberListener;
import net.a_cappella.presto.ft.collective.IFtMonitorListener;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.presto.ps.SnSManager;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

public class CukeLhClient implements PrestoClient {
    @SuppressWarnings("unused")
    private static final Logger log = LoggerFactory.getLogger(CukeLhClient.class);

    private final AppInfo _appInfo;
    private final SnSManager _sns;
	private final TLongObjectMap<OrderObj> _executionReportsMap = new TLongObjectHashMap<>();



	public CukeLhClient(SnSManager sns, AppInfo appInfo) {
		_appInfo = appInfo;
		_sns = sns;
	}

	public long getSeqNo() {
    	return 0L;
    }
    public void setSeqNo(long seqNo) {
    }

	public void verifyExecutionReport(CukeOrder cukeEr) {
		long execId = cukeEr.getExecId();

		OrderObj er = _executionReportsMap.remove(execId);
		assertNotNull(er, "No ERs found for execId "+execId + ". Available execIds: " + Arrays.stream(_executionReportsMap.keys()).boxed().toList());
		assertEquals(cukeEr, CukeOrder.adapt(er));
	}

	public void verifyNoExecutionReports() {
		assertTrue(_executionReportsMap.isEmpty());
	}

	public void verifyExecutionReportsCount(int expectedSize) {
		assertEquals(expectedSize, _executionReportsMap.size());
	}

	@Override
	public void waitUntilInitialized() {}

    public void addSnippet(TightLoopSnippet snippet) {
    }

    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener) throws Exception {
    	return _sns.snapSubscribe(sql, subListener);
    }
    @Override
    public long snapSubscribe(String sql, ISubscriptionListener subListener, IMergeManager mergeManager) throws Exception {
    	return _sns.snapSubscribe(sql, subListener, mergeManager);
    }
    @Override
    public long snapSubscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
    	return _sns.snapSubscribe(sqlComps, subListener);
    }
    @Override
    public long snap(String sql, ISubscriptionListener subListener) throws Exception {
    	return _sns.snap(sql, subListener);
    }
    @Override
    public long snap(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
    	return _sns.snap(sqlComps, subListener);
    }
    @Override
    public long subscribe(String sql, ISubscriptionListener subListener)throws Exception  {
    	return _sns.subscribe(sql, subListener);
    }
    @Override
    public long subscribe(SqlParserResult sqlComps, ISubscriptionListener subListener) throws Exception {
    	return _sns.subscribe(sqlComps, subListener);
    }
    @Override
    public void unsubscribe(long subId) {
    	_sns.unsubscribe(subId);
    }

    public boolean onTLT() {
    	return false;
    }

	public void start() {
		_executionReportsMap.clear();
	}

	public void stop() {
	}

	@Override
	public int publish(Obj obj) {
		assertTrue(obj instanceof OrderObj || obj instanceof FinalizeOrderObj);
		if (obj instanceof OrderObj) {
			OrderObj response = (OrderObj) obj;
			_executionReportsMap.put(response.getExecId(), new OrderObj(response)); // the response is the orderState object which is being re-used
		}
		return 0;
	}

	@Override
	public int serialize(Obj obj) {
		return publish(obj);
	}

	@Override
	public int request(SnapRequestObj obj) {return 0;}

	@Override
	public int reply(Obj obj, PubType pubType) {return 0;}

	@Override
	public void loopback(Obj obj) {}


	@Override
	public AppInfo getAppInfo() {
		return _appInfo;
	}

	@Override
	public void registerFtMember(String groupName, int instance, int activeGoal) {
	}

	@Override
	public void unregisterFtMember(String groupName, int instance) {
	}

	@Override
	public void registerFtMemberListener(IFtMemberListener listener) {
	}

	@Override
	public void unregisterFtMemberListener(IFtMemberListener listener) {
	}

	@Override
	public void registerFtMonitor(String groupName) {
	}

	@Override
	public void unregisterFtMonitor(String groupName) {
	}

	@Override
	public void registerFtMonitorListener(IFtMonitorListener listener) {
	}

	@Override
	public void unregisterFtMonitorListener(IFtMonitorListener listener) {
	}
}
