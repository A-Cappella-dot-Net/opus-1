package net.a_cappella.madrigal.common.utils;

import javax.swing.SwingUtilities;

import net.a_cappella.madrigal.common.interfaces.ISwingBeanGetter;

public class StartOnEventDispatchThread {
	private final ISwingBeanGetter _beanGetter;

	public StartOnEventDispatchThread(ISwingBeanGetter beanGetter) {
		_beanGetter = beanGetter;
	}

	public void start() {
		SwingUtilities.invokeLater(() -> _beanGetter.getBean());
	}
}
