package net.a_cappella.madrigal.common.interfaces;

import java.util.List;
import java.util.Map;

public interface IPublishable {
    void put(String fieldName, Object value);
    void remove(String fieldName);
    void setSendSubject(String subject);
    void setReplySubject(String subject);
    String getReplySubject();
    void setSubject(String subject);
    String getSubject();
    void setSubsId(Long subsId);
    long getSubsId();

    Object get(String fieldName);
    Double getDoubleVal(String fieldName);

    Map<String, Object> extractFields();
    Map<String, Object> extractFields(String fieldName);
    Map<String, Object> extractFields(List<String> fieldNames);
}
