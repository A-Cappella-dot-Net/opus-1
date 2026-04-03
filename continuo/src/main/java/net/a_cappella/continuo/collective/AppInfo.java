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

package net.a_cappella.continuo.collective;

import java.util.Objects;

public class AppInfo {
    private String _app = "noncore";
    private short _stripe = -1;
    private short _instance = -1;
    private String _shard = _app;
    private String _id = _app;

    public AppInfo() {}

    public AppInfo(AppInfo other) {
        this(other._app, other._stripe, other._instance);
    }

    public AppInfo(String str) {
        if (str==null || "".equals(str.trim())) return; // use default values
        int pos = str.indexOf('@');
        if (pos<0) {
            parseAppNoInstance(str);
        } else if (pos==0) {
        } else {
            parseAppNoInstance(str.substring(0, pos));
        }
        compFields();
    }

    public AppInfo(String app, short stripe, short instance) {
        _app = app;
        _stripe = stripe;
        _instance = instance;
        compFields();
    }

    public String getApp() {
        return _app;
    }
    public short getStripe() {
        return _stripe;
    }
    public short getInstance() {
        return _instance;
    }

    public String getShard() {
        return _shard;
    }
    public String getId() {
        return _id;
    }
    private void compFields() {
        _shard = _app + (_stripe<0 ? "" : ("-"+_stripe));
        _id = _shard + (_instance<0 ? "" : ("_"+_instance));
    }

    private void parseAppNoInstance(String str) {
        int pos = str.indexOf('_');
        if (pos<0) {
            parseAppNo(str);
        } else if (pos==0) {
            _instance = Short.parseShort(str);
        } else {
            parseAppNo(str.substring(0, pos));
            _instance = Short.parseShort(str.substring(pos+1));
        }
    }
    private void parseAppNo(String str) {
        int pos = str.indexOf('-');
        if (pos<0) {
            _app = str;
        } else if (pos==0) {
            _stripe = Short.parseShort(str);
        } else {
            _app = str.substring(0, pos);
            _stripe = Short.parseShort(str.substring(pos+1));
        }
    }

    public boolean equals(Object obj) {
        if (obj instanceof AppInfo) {
            AppInfo other = (AppInfo) obj;
            return _id.equals(other._id);
        }
        return false;
    }
    public int hashCode() {
        return Objects.hash(_id);
    }
    public String toString() {
        return _id;
    }
}
