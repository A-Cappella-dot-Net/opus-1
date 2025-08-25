package net.a_cappella.madrigal.cukes.adaptors.um;

import io.cucumber.java.DataTableType;

import java.util.Map;

public class CukeExchangeLogOp {
	private final String op;
	private final String uid;
	private final String pwd;

	@DataTableType
	public static CukeExchangeLogOp dttCukeExchangeLogOp(Map<String, String> entry) {
		return new CukeExchangeLogOp(
				entry.get("op"),
				entry.get("uid"),
				entry.get("pwd")
		);
	}

	public CukeExchangeLogOp(String op, String uid, String pwd) {
		this.op = op;
		this.uid = uid;
		this.pwd = pwd;
	}

	public String getOp() {
		return op;
	}
	public String getUid() {
		return uid;
	}
	public String getPwd() {
		return pwd;
	}

	@Override
	public String toString() {
		return "CukeExchangeLogOp [op=" + op + ", uid=" + uid + ", pwd=" + pwd + "]";
	}
}
