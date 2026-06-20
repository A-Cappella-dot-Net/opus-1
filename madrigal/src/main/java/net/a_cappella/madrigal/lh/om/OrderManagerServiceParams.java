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

package net.a_cappella.madrigal.lh.om;

import net.a_cappella.madrigal.common.constants.MadrigalActionOnFailover;
import net.a_cappella.madrigal.lh.om.logic.DelRetryType;
import net.a_cappella.madrigal.lh.om.strategy.*;

public class OrderManagerServiceParams {

	private final IOrderManagerAdaptor _adaptor;

	private DelRetryType _delRetryType;
	private int _delRetryConstant;

	private boolean _nativeIocSupported = true;
	private boolean _conflateRequests = true;
	private boolean _processOnePendingRequestAtATime = false;
    private boolean _useDelAddForPriceChange = true;
    private boolean _strictRwt = true;
	private MadrigalActionOnFailover _actionOnFailover = MadrigalActionOnFailover.RESUME_IF_RECENT;

	private NativeStrategy _nativeStrategy;
	private SimulatedIocStrategy _simulatedIocStrategy;
	private SniperStrategy _sniperStrategy;
	private SimulatedIbgRwtStrategy _simulatedIbgRwtStrategy;
	private ResumeOnFailoverStrategy _resumeOnFailoverStrategy;

	public OrderManagerServiceParams(IOrderManagerAdaptor adaptor, DelRetryType delRetryType, int delRetryConstant) {
		_adaptor = adaptor;
		_delRetryType = delRetryType;
		_delRetryConstant = delRetryConstant;
	}

	public OrderManagerServiceParams(IOrderManagerAdaptor adaptor,
			String delRetryType,
			int delRetryConstant,
			boolean nativeIocSupported,
			boolean conflateRequests,
			boolean processOnePendingRequestAtATime,
			boolean useDelAddForPriceChange,
			boolean strictRwt,
			MadrigalActionOnFailover actionOnFailover) {
		_adaptor = adaptor;
		_delRetryType = DelRetryType.getEnumFromName(delRetryType);
		_delRetryConstant = delRetryConstant;
		_nativeIocSupported = nativeIocSupported;
		_conflateRequests = conflateRequests;
		_processOnePendingRequestAtATime = processOnePendingRequestAtATime;
		_useDelAddForPriceChange = useDelAddForPriceChange;
		_strictRwt = strictRwt;
		_actionOnFailover = actionOnFailover;
	}

	public void set(
			DelRetryType delRetryType,
			int delRetryConstant,
			boolean nativeIocSupported,
			boolean conflateRequests,
			boolean processOnePendingRequestAtATime,
			boolean useDelAddForPriceChange,
			boolean strictRwt,
			MadrigalActionOnFailover actionOnFailover) {
		_delRetryType = delRetryType;
		_delRetryConstant = delRetryConstant;
		_nativeIocSupported = nativeIocSupported;
		_conflateRequests = conflateRequests;
		_processOnePendingRequestAtATime = processOnePendingRequestAtATime;
		_useDelAddForPriceChange = useDelAddForPriceChange;
		_strictRwt = strictRwt;
		_actionOnFailover = actionOnFailover;
	}

	public DelRetryType getDelRetryType() {
		return _delRetryType;
	}
	public int getDelRetryConstant() {
		return _delRetryConstant;
	}

	public void setNativeIocSupported(boolean nativeIocSupported) {
    	_nativeIocSupported = nativeIocSupported;
    }
    public boolean isNativeIocSupported() {
    	return _nativeIocSupported;
    }

	public void setConflateRequests(boolean conflateRequests) {
		_conflateRequests = conflateRequests;
	}
    public boolean isConflateRequests() {
    	return _conflateRequests;
    }

	public void setProcessOnePendingRequestAtATime(boolean processOnePendingRequestAtATime) {
		_processOnePendingRequestAtATime = processOnePendingRequestAtATime;
	}
    public boolean isProcessOnePendingRequestAtATime() {
    	return _processOnePendingRequestAtATime;
    }

	public void setUseDelAddForPriceChange(boolean useDelAddForPriceChange) {
		_useDelAddForPriceChange = useDelAddForPriceChange;
	}
    public boolean isUseDelAddForPriceChange() {
    	return _useDelAddForPriceChange;
    }

	public void setStrictRwt(boolean strictRwt) {
		_strictRwt = strictRwt;
	}
    public boolean isStrictRwt() {
    	return _strictRwt;
    }

	public void setActionOnFailover(MadrigalActionOnFailover actionOnFailover) {
		_actionOnFailover = actionOnFailover;
	}
	public MadrigalActionOnFailover getActionOnFailover() {
		return _actionOnFailover;
	}

	public NativeStrategy getNativeStrategy() {
		return _nativeStrategy;
	}
	public SimulatedIocStrategy getSimulatedIocStrategy() {
		return _simulatedIocStrategy;
	}
	public SniperStrategy getSniperStrategy() {
		return _sniperStrategy;
	}
	public SimulatedIbgRwtStrategy getSimulatedIbgRwtStrategy() {
		return _simulatedIbgRwtStrategy;
	}
	public ResumeOnFailoverStrategy getResumeOnFailoverStrategy() {
		return _resumeOnFailoverStrategy;
	}

	public void init() {
		_nativeStrategy = new NativeStrategy(_conflateRequests, _processOnePendingRequestAtATime, _strictRwt, _adaptor);

		_simulatedIocStrategy = new SimulatedIocStrategy();
		_simulatedIbgRwtStrategy = new SimulatedIbgRwtStrategy(_conflateRequests, _useDelAddForPriceChange, _strictRwt);
		_sniperStrategy = new SniperStrategy(_strictRwt);
		_resumeOnFailoverStrategy = new ResumeOnFailoverStrategy(_conflateRequests, _strictRwt);
    }

    public IOrderHandlerStrategy getStrategy(Immutables immutables) {
    	switch (immutables.getImmutableType()) {
    	case IOC:
    		return getIocStrategy(immutables.isUseNative());
    	case SNIPER:
    		return _sniperStrategy;
    	default:
    		return getIbgRwtStrategy(immutables.isUseNative());
    	}
    }

    public IOrderHandlerStrategy getIocStrategy(boolean useNativeIoc) {
    	if (_nativeIocSupported && useNativeIoc) {
    		return _nativeStrategy;
    	}
		return _simulatedIocStrategy;
    }

    private IOrderHandlerStrategy getIbgRwtStrategy(boolean useNativeRwt) {
    	if (useNativeRwt) {
    		return _nativeStrategy;
    	}
		return _simulatedIbgRwtStrategy;
    }

	@Override
	public String toString() {
		return "OrderManagerServiceParams ["+
			"delRetryType="+_delRetryType+
			", delRetryConstant="+_delRetryConstant+
			", nativeIocSupported="+_nativeIocSupported+
			", conflateRequests="+_conflateRequests+
			", processOnePendingRequestAtATime="+_processOnePendingRequestAtATime+
			", useDelAddForPriceChange="+_useDelAddForPriceChange+
			", strictRwt="+_strictRwt+
			", actionOnFailover="+_actionOnFailover+
			"]";
	}
}
