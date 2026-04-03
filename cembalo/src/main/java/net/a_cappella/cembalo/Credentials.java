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

package net.a_cappella.cembalo;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

public class Credentials {
    private final Map<String, String> _map = new HashMap<>();

    public Credentials(Map<String, Map<String, String>> map) {
        for (Map.Entry<String, Map<String, String>> entry : map.entrySet()) {
            String org = entry.getKey();
            for (Map.Entry<String, String> cred : entry.getValue().entrySet()) {
                String uid = cred.getKey();
                String pwd = cred.getValue();
                _map.put(org+"."+uid, pwd);
            }
        }
    }

    public boolean allowed(String orgUid, String pwd) {
        return Objects.equals(_map.get(orgUid), pwd);
    }
}
