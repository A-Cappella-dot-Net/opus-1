package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;

public class CukeEcnCredentials {
	private final String uid;
	private final String ecn;
	private final String ecnUid;
	private final String ecnPwd;

	public CukeEcnCredentials(String uid, String ecn, String ecnUid, String ecnPwd) {
		this.uid = uid;
		this.ecn = ecn;
		this.ecnUid = ecnUid;
		this.ecnPwd = ecnPwd;
	}

	public String getUid() {
		return uid;
	}
	public String getEcnUid() {
		return ecnUid;
	}
	public String getEcnPwd() {
		return ecnPwd;
	}

	public EcnCredentialsObj of() {
		EcnCredentialsObj obj = new EcnCredentialsObj();
		obj.set(uid, ecn, ecnUid, ecnPwd, System.currentTimeMillis());
		return obj;
	}
}
