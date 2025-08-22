package net.a_cappella.madrigal.cukes.adaptors.um;

public class CukeExchangeLogOp {
	private final String op;
	private final String uid;
	private final String pwd;

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
