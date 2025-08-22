package net.a_cappella.madrigal.om.logic;

public enum DelRetryType {
	DISABLED("disabled"), COUNT("count"), TIMEOUT("timeout");

	private final String id;

	DelRetryType(String id) {
		this.id = id;
	}

	public String toString() {
		return this.id;
	}

	public static DelRetryType getEnumFromName(String name) {
		if ("DISABLED".equalsIgnoreCase(name)) {
			return DelRetryType.DISABLED;
		} else if ("COUNT".equalsIgnoreCase(name)) {
			return DelRetryType.COUNT;
		} else if ("TIMEOUT".equalsIgnoreCase(name)) {
			return DelRetryType.TIMEOUT;
		}
		return null;
	}
}
