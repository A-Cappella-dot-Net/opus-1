package net.a_cappella.madrigal.cukes.adaptors;

import net.a_cappella.madrigal.ICredentialsCache;
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;

import java.util.HashMap;
import java.util.Map;

public class CukeCredentialsCache implements ICredentialsCache {
    protected Map<String, CukeEcnCredentials> _ecnCredentialsCache = new HashMap<>(); // <uid, EcnCredentialsObj>
    {
    	_ecnCredentialsCache.put("uid", new CukeEcnCredentials("uid", "ecn", "ecnUid"));
    }

    @Override
	public EcnCredentialsObj getEcnCredentials(String uid) {
		return _ecnCredentialsCache.get(uid).of();
	}
}
