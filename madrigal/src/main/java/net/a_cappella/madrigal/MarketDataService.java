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

import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class MarketDataService implements IMarketDataService {
    private static final Logger log = LoggerFactory.getLogger(MarketDataService.class);

    private static String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";

    private final String _ftGroup;
    private final int _ftInstance;
	private boolean _active;
	private final PrestoClient _client;

	public MarketDataService(PrestoClient client) {
        _client = client;
		_ftGroup = "FT.MDS." + client.getAppInfo().getShard();
		_ftInstance = _client.getAppInfo().getInstance();
		_ftMemberSubSql = String.format(_ftMemberSubSql, _ftGroup, _ftInstance);
    }

    public void init() {
		_client.waitUntilInitialized();

    	try {
            _client.subscribe(_ftMemberSubSql, (obj, subsId) -> {
            	onFtMemberMessage((FtMemberObj) obj);
        	});
    	} catch (Exception e) {
            log.error("", e);
        }

    	_client.registerFtMember(_ftGroup, _ftInstance, 1);
    }

	private void onFtMemberMessage(FtMemberObj ftMem) {
        log.info("onFtMemberMessage("+ftMem+")");

        FtMsgOp op = ftMem.getAction();
		if (op == ACTIVATE) {
			_active = true;
		} else if (op == DEACTIVATE) {
			_active = false;
		}
	}

	@Override // IMarketDataService
	public void publishMarketStatus(MarketStatusObj marketStatus) throws Exception {
		if (_active) {
			_client.serialize(marketStatus);
		}
	}

	@Override // IMarketDataService
	public void publishInstrument(EcnInstrumentObj ecnInstrument) throws Exception {
		if (_active) {
			_client.serialize(ecnInstrument);
		}
	}

	@Override // IMarketDataService
	public void publishEcnPrice(EcnPriceObj ecnPrice) throws Exception {
		if (_active) {
			_client.serialize(ecnPrice);
		}
	}

	@Override // IMarketDataService
	public void publishEcnInstrStatus(EcnInstrStatusObj ecnInstrStatus) throws Exception {
		if (_active) {
			_client.serialize(ecnInstrStatus);
		}
	}

	@Override // IMarketDataService
	public void publishEcnImbalance(EcnImbalanceObj ecnImbalance) throws Exception {
		if (_active) {
			_client.serialize(ecnImbalance);
		}
	}
}
