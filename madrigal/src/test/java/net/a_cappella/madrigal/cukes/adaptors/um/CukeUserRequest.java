package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.obj.UserStatusObj;

public class CukeUserRequest {
	private final String uid;
	private final String pwd;
	private final String clId;
	private final String op;
	private final boolean rejectIfLoggedIn;
	private final boolean forceLogout;

	public CukeUserRequest(String uid, String pwd, String clId, String op, boolean rejectIfLoggedIn, boolean forceLogout) {
		this.uid = uid;
		this.pwd = pwd;
		this.clId = clId;
		this.op = op;
		this.rejectIfLoggedIn = rejectIfLoggedIn;
		this.forceLogout = forceLogout;
	}

	public String getUid() {
		return uid;
	}
	public String getPwd() {
		return pwd;
	}
	public String getClId() {
		return clId;
	}
	public String getOp() {
		return op;
	}
	public boolean isRejectIfLoggedIn() {
		return rejectIfLoggedIn;
	}
	public boolean isForceLogout() {
		return forceLogout;
	}

	public UserStatusObj of() {
		UserStatusObj obj = new UserStatusObj();
		obj.setRequest(uid, clId, MadrigalLogOp.valueOf(op), pwd, rejectIfLoggedIn, forceLogout, System.currentTimeMillis());
		return obj;
	}
}
