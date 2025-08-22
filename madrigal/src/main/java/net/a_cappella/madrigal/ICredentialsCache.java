package net.a_cappella.madrigal;

import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;

public interface ICredentialsCache {
	EcnCredentialsObj getEcnCredentials(String uid);
}
