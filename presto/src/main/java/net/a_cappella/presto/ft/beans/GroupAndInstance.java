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

package net.a_cappella.presto.ft.beans;

public class GroupAndInstance {
    public String _groupName;
    public int _instance;

    public GroupAndInstance(String groupName, int instance) {
        _groupName = groupName;
        _instance = instance;
    }

    public int hashCode() {
        return _groupName.hashCode()+_instance;
    }
    public boolean equals(Object o) {
        if (o instanceof GroupAndInstance) {
            GroupAndInstance other = (GroupAndInstance) o;
            return _instance==other._instance && _groupName.equals(other._groupName);
        }
        return false;
    }
    public String toString() {
        return _groupName+"-"+_instance;
    }
}
