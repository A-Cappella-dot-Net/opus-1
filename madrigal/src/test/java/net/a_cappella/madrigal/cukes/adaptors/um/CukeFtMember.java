package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.FtMemberObj;

public class CukeFtMember {
	private final int instance;
	private final String action;

	public CukeFtMember(int instance, String action) {
		this.instance = instance;
		this.action = action;
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
