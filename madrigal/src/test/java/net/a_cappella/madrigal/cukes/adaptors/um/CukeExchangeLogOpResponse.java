package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;

import java.util.Map;

public class CukeExchangeLogOpResponse {
	private String ecnUid;
	private String status;
	private String text;

	@DataTableType
	public static CukeExchangeLogOpResponse dttCukeExchangeLogOpResponse(Map<String, String> entry) {
		CukeExchangeLogOpResponse resp = new CukeExchangeLogOpResponse();
		resp.ecnUid = entry.get("ecnUid");
		resp.status = entry.get("status");
		resp.text = entry.get("text");
		return resp;
	}

	public String getEcnUid() {
		return ecnUid;
	}
	public String getStatus() {
		return status;
	}
	public String getText() {
		return text;
	}

}
