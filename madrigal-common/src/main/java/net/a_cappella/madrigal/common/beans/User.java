package net.a_cappella.madrigal.common.beans;

import java.util.Map;

public class User {
	private final String _uid;
	private final String _pwd;
	private final Map<String, EcnCredentials> _ecnCredentials;

	public User(String uid, String pwd, Map<String, EcnCredentials> ecnCredentials) {
		_uid = uid;
		_pwd = pwd;
		_ecnCredentials = ecnCredentials;
	}
	public String getUid() {
		return _uid;
	}
	public String getPwd() {
		return _pwd;
	}
	public Map<String, EcnCredentials> getEcnCredentials() {
		return _ecnCredentials;
	}
	public EcnCredentials getEcnCredentials(String ecn) {
		return _ecnCredentials.get(ecn);
	}
}
