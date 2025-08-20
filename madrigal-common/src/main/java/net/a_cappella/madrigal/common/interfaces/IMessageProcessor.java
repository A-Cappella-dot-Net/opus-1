package net.a_cappella.madrigal.common.interfaces;

public interface IMessageProcessor {
    void processMessage(String subject, Object obj, boolean publishInProcess);
    IPublishable processRequest(String subject, IPublishable pub);
}
