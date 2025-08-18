package net.a_cappella.test.presto.parallel;

public interface IKPHandler<T, S> {
    boolean handleMessage(IKPMessage<T> message, S threadLocalObject);
}
