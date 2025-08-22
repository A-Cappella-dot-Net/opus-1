package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.common.constants.MadrigalActionOnFailover;
import net.a_cappella.madrigal.om.logic.DelRetryType;

public class OrderManagerServiceConfig {
	private DelRetryType delRetryType;
	private Integer delRetryConstant;
	private Boolean nativeIocSupported;
	private Boolean conflateRequests;
	private Boolean processOnePendingRequestAtATime;
	private Boolean useDelAddForPriceChange;
	private Boolean strictRwt;
	private MadrigalActionOnFailover actionOnFailover;

    public OrderManagerServiceConfig() {
    }

    public OrderManagerServiceConfig(
            DelRetryType delRetryType,
            Integer delRetryConstant,
            Boolean nativeIocSupported,
            Boolean conflateRequests,
            Boolean processOnePendingRequestAtATime,
            Boolean useDelAddForPriceChange,
            Boolean strictRwt,
            MadrigalActionOnFailover actionOnFailover
    ) {
        if (delRetryType != null) this.delRetryType = delRetryType;
        this.delRetryConstant = delRetryConstant;
        this.nativeIocSupported = nativeIocSupported;
        this.conflateRequests = conflateRequests;
        this.processOnePendingRequestAtATime = processOnePendingRequestAtATime;
        this.useDelAddForPriceChange = useDelAddForPriceChange;
        this.strictRwt = strictRwt;
        this.actionOnFailover = actionOnFailover;
    }

	public DelRetryType getDelRetryType(DelRetryType defaultValue) {
		return delRetryType==null ? defaultValue : delRetryType;
	}
	public Integer getDelRetryConstant(Integer defaultValue) {
		return delRetryType==null ? defaultValue : delRetryConstant;
	}

	public boolean isNativeIocSupported(boolean defaultValue) {
		return nativeIocSupported==null ? defaultValue : nativeIocSupported;
	}
	public boolean isConflateRequests(boolean defaultValue) {
		return conflateRequests==null ? defaultValue : conflateRequests;
	}
	public boolean isProcessOnePendingRequestAtATime(boolean defaultValue) {
		return processOnePendingRequestAtATime==null ? defaultValue : processOnePendingRequestAtATime;
	}
	public boolean isUseDelAddForPriceChange(boolean defaultValue) {
		return useDelAddForPriceChange==null ? defaultValue : useDelAddForPriceChange;
	}
	public boolean isStrictRwt(boolean defaultValue) {
		return strictRwt==null ? defaultValue : strictRwt;
	}
	public MadrigalActionOnFailover getActionOnFailover(MadrigalActionOnFailover defaultValue) {
		return actionOnFailover==null ? defaultValue : actionOnFailover;
	}
}
