package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;
import net.a_cappella.continuo.collective.AppInfo;

import java.util.Map;

public class CukeAppInfo {
	private short instance;

	@DataTableType
	public static CukeAppInfo dttCukeAppInfo(Map<String, String> entry) {
		CukeAppInfo cai = new CukeAppInfo();
		cai.instance = Short.parseShort(entry.get("instance"));
		return cai;
	}

	public short getInstance() {
		return instance;
	}

	public AppInfo of() {
		return new AppInfo("userservice", (short) -1, instance);
	}
}
