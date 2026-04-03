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

package net.a_cappella.madrigal.common.beans;

public class EcnCredentials {
    private final String _uid;
    private final String _ecn;
    private final String _ecnUid;
    private final String _ecnPwd;
    private final String _acct; // only for CME

    public EcnCredentials(String uid, String ecn, String ecnUid, String ecnPwd, String acct) {
        _uid = uid;
        _ecn = ecn;
        _ecnUid = ecnUid;
        _ecnPwd = ecnPwd;
        _acct = acct;
    }

    public String getUid() {
        return _uid;
    }
    public String getEcn() {
        return _ecn;
    }
    public String getEcnUid() {
        return _ecnUid;
    }
    public String getEcnPwd() {
        return _ecnPwd;
    }
    public String getAcct() {
        return _acct;
    }
}
