package net.a_cappella.madrigal.cukes.adaptors.um;

public class CukeExchangeLogOpResponse {
	private final String ecnUid;
	private final String status;
	private final String text;

	public CukeExchangeLogOpResponse(String ecnUid, String status, String text) {
		this.ecnUid = ecnUid;
		this.status = status;
		this.text = text;
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
