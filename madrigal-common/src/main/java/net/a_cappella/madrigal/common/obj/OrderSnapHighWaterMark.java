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
