package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.FtMemberObj;

import java.util.Map;

public class CukeFtMember {
	private int instance;
	private String action;

	@DataTableType
	public static CukeFtMember cukeFtMemberEntry(Map<String, String> entry) {
		CukeFtMember cfm = new CukeFtMember();
		cfm.instance = Integer.parseInt(entry.get("instance"));
		cfm.action = entry.get("action");
		return cfm;
	}

	public int getInstance() {
		return instance;
	}

	public String getAction() {
		return action;
	}

	public FtMemberObj of() {
		FtMemberObj obj = new FtMemberObj();
		obj.set("groupName", instance, FtMsgOp.valueOf(action), 0, 1, System.currentTimeMillis());
		return obj;
	}
}
