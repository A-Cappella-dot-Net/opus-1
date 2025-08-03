package net.a_cappella.continuo.msg;

public interface Rtg {
    void setOriginClient(String originClient);
    String getOriginClient();
    void copyRoutingFields(Rtg rtg);
}
