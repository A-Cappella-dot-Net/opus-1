package net.a_cappella.continuo.managed;

public interface IPoolable {
    boolean isPooled();
    void setPooled(boolean pooled);
    int getIdentityHashCode();
    void acquire();
    void startUsing();
    void stopUsing();
    int getNumUsers();
    void reset();
}
