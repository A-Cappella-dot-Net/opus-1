package net.a_cappella.madrigal;

public interface ILoginManagerAdaptor {
	void login(String ecnUid, String ecnPwd);
	void logout(String ecnUid, String ecnPwd);
}
