package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.UserStatusObj;

public class CukeUserStatus {
	private final String uid;
	private final String clId;
	private final String op;
	private final String status;
	private final String reqStatus;
	private final String text;

	public CukeUserStatus(String uid, String clId, String op, String status, String reqStatus, String text) {
		this.uid = uid;
		this.clId = clId;
		this.op = op;
		this.status = status;
		this.reqStatus = reqStatus;
		this.text = text;
	}

	public String getUid() {
		return uid;
	}
	public String getClId() {
		return clId;
	}
	public String getOp() {
		return op;
	}
	public String getStatus() {
		return status;
	}
	public String getReqStatus() {
		return reqStatus;
	}
	public String getText() {
		return text;
	}

	public UserStatusObj of() {
		UserStatusObj obj = new UserStatusObj();
		obj.setResponse(uid, clId, MadrigalLogOp.valueOf(op), MadrigalUserStatus.valueOf(status), MadrigalUserStatus.valueOf(reqStatus), text, System.currentTimeMillis());
		return obj;
	}
}
