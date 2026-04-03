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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.presto.ps.SnapHighWaterMark;

public class OrderSnapHighWaterMark implements SnapHighWaterMark {

	private long _seqNo = -1L;
	private long _execId = -1L;

	@Override
	public void initHighWaterMark(Obj obj) {
		_seqNo = obj.getSeqNo();
		OrderObj ord = (OrderObj) obj;
		_execId = ord.getExecId();
	}

	@Override
	public boolean isIncludedInSnap(Obj obj) {
		OrderObj ord = (OrderObj) obj;
		MadrigalMode mode = ord.getMadrigalMode();
		if (MadrigalMode.REQUEST == mode || ord.getEcn().startsWith(MadrigalConstants.LH_ECN_PREFIX)) {
			return _seqNo >= ord.getSeqNo();
		}
		if (MadrigalMode.RESPONSE == mode) {
			return _execId >= ord.getExecId();
		}
		return true; // if it gets here then do not pass along
	}

}
