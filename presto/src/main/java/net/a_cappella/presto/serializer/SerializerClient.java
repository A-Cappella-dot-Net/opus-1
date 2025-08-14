package net.a_cappella.presto.serializer;

public interface SerializerClient {
    void waitUntilInitialized();

    void onActivate(long seqNo);
    void onDeactivate();
}
