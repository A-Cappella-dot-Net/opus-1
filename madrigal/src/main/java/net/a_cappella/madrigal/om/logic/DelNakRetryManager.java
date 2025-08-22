package net.a_cappella.madrigal.om.logic;

public class DelNakRetryManager {

	private final DelRetryType _delRetryType;
	private final int _delRetryConstant;

	private int _delRetryCount;
	private long _delRetryTimeout;

	public DelNakRetryManager(DelRetryType delRetryType, int delRetryConstant) {
		_delRetryType = delRetryType;
		_delRetryConstant = delRetryConstant;
	}

	public void initCancelRetryLogic() {
		if (_delRetryType == DelRetryType.COUNT) {
			_delRetryCount = _delRetryConstant;
		} else { // TIMEOUT
			_delRetryTimeout = System.currentTimeMillis() + _delRetryConstant;
			_delRetryCount = 0;
		}
	}

	public boolean okToRetryCancel() {
		if (_delRetryType == DelRetryType.DISABLED) return false;

		if (_delRetryType == DelRetryType.COUNT) {
			return --_delRetryCount >= 0;
		} else { // TIMEOUT
			_delRetryCount++;
			return System.currentTimeMillis() >= _delRetryTimeout;
		}
	}
}
