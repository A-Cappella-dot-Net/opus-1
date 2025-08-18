package net.a_cappella.test.presto.parallel;

public interface IKeyedParallelizer<T> {
    void init();
    void stop();
    void parallelize(IKPMessage<T> msg);
}
