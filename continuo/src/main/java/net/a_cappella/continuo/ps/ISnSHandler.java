package net.a_cappella.continuo.ps;

public interface ISnSHandler {
    ISubscriptionListener getSubListener();
    String getSubject();
    long getSubId();
}
