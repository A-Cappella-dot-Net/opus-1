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

package net.a_cappella.madrigal.devtools;

public class TokenInfo {
    private final String _username;
    private final long _expiryTimeMillis;

    public TokenInfo(String username, long expiryTimeMillis) {
        _username = username;
        _expiryTimeMillis = expiryTimeMillis;
    }

    public boolean isExpired() {
        return _expiryTimeMillis < System.currentTimeMillis();
    }

    public String getUsername() {
        return _username;
    }
}
