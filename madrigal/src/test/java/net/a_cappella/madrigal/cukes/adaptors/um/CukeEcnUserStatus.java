package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;
import net.a_cappella.madrigal.common.constants.MadrigalLogOp;
import net.a_cappella.madrigal.common.constants.MadrigalMode;
import net.a_cappella.madrigal.common.constants.MadrigalUserStatus;
import net.a_cappella.madrigal.common.obj.EcnUserStatusObj;

import java.util.Map;

public class CukeEcnUserStatus {
    private String mode;
    private final String uid;
    private final String ecn;
    private final String ecnUid;

    private final String op;		// REQUEST
    private final String ecnPwd;	// REQUEST
    private final String status;	// RESPONSE
    private final String text;	// RESPONSE

    private int instance; // RESPONSE

	@DataTableType
	public static CukeEcnUserStatus cukeEcnUserStatusEntry(Map<String, String> entry) {
		return new CukeEcnUserStatus(
				entry.get("mode"),
				entry.get("uid"),
				entry.get("ecn"),
				entry.get("ecnUid"),
				entry.get("op"),
				entry.get("ecnPwd"),
				entry.get("status"),
				entry.get("text"),
				0
		);
	}


    public CukeEcnUserStatus(String mode, String uid, String ecn, String ecnUid, String op, String ecnPwd, String status, String text, int instance) {
    	this.mode = mode;
    	this.uid = uid;
    	this.ecn = ecn;
    	this.ecnUid = ecnUid;
    	this.op = op;
    	this.ecnPwd = ecnPwd;
    	this.status = status;
    	this.text = text;
    	this.instance = instance;
    }

	public String getMode() {
		return mode;
	}
	public void setMode(MadrigalMode mode) {
		this.mode = mode.name();
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
	public String getOp() {
		return op;
	}
	public String getEcnPwd() {
		return ecnPwd;
	}
	public String getStatus() {
		return status;
	}
	public String getText() {
		return text;
	}
	public int getInstance() {
		return instance;
	}
	public void setInstance(int instance) {
		this.instance = instance;
	}

	public EcnUserStatusObj of() {
		EcnUserStatusObj obj = new EcnUserStatusObj();
		if ("RESPONSE".equals(mode)) {
			obj.setResponse(instance, uid, ecn, ecnUid, ecnPwd, MadrigalLogOp.valueOf(op), MadrigalUserStatus.valueOf(status), text, System.currentTimeMillis());
		} else {
			obj.setRequest(instance, uid, ecn, ecnUid, ecnPwd, MadrigalLogOp.valueOf(op), System.currentTimeMillis());
		}
		return obj;
	}
}
