package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;
import net.a_cappella.madrigal.common.obj.CredentialsObj;

import java.util.Map;

public class CukeCredentials {
	private short instance;
	private String uid;
	private String pwd;

	@DataTableType
	public static CukeCredentials dttCukeCredentials(Map<String, String> entry) {
		CukeCredentials cc = new CukeCredentials();
		cc.instance = Short.parseShort(entry.get("instance"));
		cc.uid = entry.get("uid");
		cc.pwd = entry.get("pwd");
		return cc;
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
