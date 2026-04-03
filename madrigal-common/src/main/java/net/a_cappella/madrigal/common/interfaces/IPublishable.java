/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
