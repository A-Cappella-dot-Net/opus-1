package net.a_cappella.madrigal.common.utils;

import net.a_cappella.madrigal.common.interfaces.IIdGenerator;

public class SimpleIdGenerator implements IIdGenerator {
	private long currentId = 0;

	@Override
	public String nextId() {
		return String.format("%05d", ++currentId);
	}

}
