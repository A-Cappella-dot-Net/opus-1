package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;

public class CukeEcnCredentials {
    private final String uid;
    private final String ecn;
    private final String ecnUid;

    public CukeEcnCredentials(String uid, String ecn, String ecnUid) {
		this.uid = uid;
		this.ecn = ecn;
		this.ecnUid = ecnUid;
	}

    public String getUid() {
		return uid;
	}
    public String getEcn() {
		return ecn;
	}
	public String getEcnUid() {
		return ecnUid;
	}

	public EcnCredentialsObj of() {
		EcnCredentialsObj creds = new EcnCredentialsObj();
		creds.set(uid, ecn, ecnUid, null, 0);
		return creds;
	}
}
