package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.madrigal.common.obj.CredentialsObj;

public class CukeCredentials {
	private final short instance;
	private final String uid;
	private final String pwd;

	public CukeCredentials(short instance, String uid, String pwd) {
		this.instance = instance;
		this.uid = uid;
		this.pwd = pwd;
	}

	public short getInstance() {
		return instance;
	}
	public String getUid() {
		return uid;
	}
	public String getPwd() {
		return pwd;
	}

	public CredentialsObj of() {
		CredentialsObj obj = new CredentialsObj();
		obj.set(uid, pwd, System.currentTimeMillis());
		return obj;
	}
}
