package net.a_cappella.madrigal.cukes.adaptors.um;

import net.a_cappella.continuo.collective.AppInfo;

public class CukeAppInfo {
	private final short instance;

	public CukeAppInfo(short instance) {
		this.instance = instance;
	}

	public short getInstance() {
		return instance;
	}

	public AppInfo of() {
		return new AppInfo("userservice", (short) -1, instance);
	}
}
