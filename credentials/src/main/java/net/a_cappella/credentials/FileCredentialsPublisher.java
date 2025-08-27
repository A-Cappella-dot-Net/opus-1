package net.a_cappella.credentials;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.obj.CredentialsObj;
import net.a_cappella.madrigal.common.obj.EcnCredentialsObj;
import net.a_cappella.madrigal.common.utils.CSVParser;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.FileInputStream;
import java.util.List;

public class FileCredentialsPublisher {
    private static final Logger log = LoggerFactory.getLogger(FileCredentialsPublisher.class);

    private static final boolean USE_MAP_MSG = false;

    private PrestoClient _client;
    public void setClient(PrestoClient client) {
    	_client = client;
    }

	private final Obj _ecnCreds = (USE_MAP_MSG) ? new MapObj() : new EcnCredentialsObj();
	private final Obj _creds = (USE_MAP_MSG) ? new MapObj() : new CredentialsObj();

    private String _usersFile;
	public String getUsersFile() {
		return _usersFile;
	}
	public void setUsersFile(String usersFile) {
		_usersFile = usersFile;
	}

    public void start() {
    	try {
    		_client.waitUntilInitialized();

    		CSVParser parser = new CSVParser(new FileInputStream(_usersFile));
    		List<String[]> rows = parser.getRows();
    		for (int i=0; i<rows.size(); i++) {
    			String[] cols = rows.get(i);    			
    			publishUser(cols);
    		}
    	} catch (Exception e) {
    		log.error("Exception while reading users file", e);
    	}
    }

    private void publishUser(String[] cols) throws Exception {
    	final String uid = cols[0];
    	final String pwd = cols[1];
    	final String credentialsRaw = cols[2];

		if (credentialsRaw!=null) {
			String[] credentialsSet = credentialsRaw.split("\\|");
			for (String credentials : credentialsSet) {
				String[] details = credentials.split(":");
				String ecn = details[0];
				String ecnUid = details[1];
				String ecnPwd = details[2];
				if (USE_MAP_MSG) {
					MapObj map = (MapObj) _ecnCreds;
					map.setSubject(MadrigalConstants.SUBJ_ECN_CREDENTIALS);
					map.setString("uid", uid);
					map.setString("ecn", ecn);
					map.setString("ecnUid", ecnUid);
					map.setString("ecnPwd", ecnPwd);
					map.setTimestamp("ts", System.currentTimeMillis());
				} else {
					EcnCredentialsObj obj = (EcnCredentialsObj) _ecnCreds;
					obj.set(uid, ecn, ecnUid, ecnPwd, System.currentTimeMillis());
				}
				log.info("publishing credentials for: "+_ecnCreds);
				_client.publish(_ecnCreds);
			}
		}

		if (USE_MAP_MSG) {
			MapObj map = (MapObj) _creds;
			map.setSubject(MadrigalConstants.SUBJ_CREDENTIALS);
			map.setString("uid", uid);
			map.setString("pwd", pwd);
			map.setTimestamp("ts", System.currentTimeMillis());
		} else {
			CredentialsObj obj = (CredentialsObj) _creds;
	    	obj.set(uid, pwd, System.currentTimeMillis());
		}
		log.info("publishing credentials: "+_creds);
		_client.publish(_creds);
    }
}
