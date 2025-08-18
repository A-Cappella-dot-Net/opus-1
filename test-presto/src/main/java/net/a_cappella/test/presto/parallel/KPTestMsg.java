package net.a_cappella.test.presto.parallel;

import net.a_cappella.continuo.msg.TestMsg;

public class KPTestMsg extends TestMsg implements IKPMessage<String> {
	private String _threadKey;

	@Override
	public void setThreadKey(String threadKey) {
		_threadKey = threadKey;
	}
	@Override
	public String getThreadKey() {
		return _threadKey;
	}

	@Override
    public void reset() {
    	super.reset();
    	_threadKey = null;
    }

}
