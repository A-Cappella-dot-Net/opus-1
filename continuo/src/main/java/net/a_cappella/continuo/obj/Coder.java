package net.a_cappella.continuo.obj;

public interface Coder {
    Obj getObj();
    void setObj(Obj obj);

    int getVersion();
    void setObjType(int objType);
    int getObjType();

    String getSubject();
    PubType getPubType();
    long getRequestId();
    String getOriginClient();
    short getMine();
    long getTsNanos();
    boolean isBackPressured();
    boolean isOnLoopback();
    long getSerialId();
    long getSeqNo();
}
