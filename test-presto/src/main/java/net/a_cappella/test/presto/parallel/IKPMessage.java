package net.a_cappella.test.presto.parallel;

public interface IKPMessage<T> {
	T getThreadKey();
	void setThreadKey(T key);
}
