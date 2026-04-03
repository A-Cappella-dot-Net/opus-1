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

package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Msg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.VERSIONED_STRING_MSG;

public class VersionedStringMsg extends Msg {
    private static final Logger log = LoggerFactory.getLogger(VersionedStringMsg.class);

    public String _name;
    public int _version;
    public String _string;

    public VersionedStringMsg() {
        this(null, 0, null);
    }

    public VersionedStringMsg(String name) {
        this(name, 0, null);
    }

    public VersionedStringMsg(VersionedStringMsg other) {
        this(other._name, other._version, other._string);
    }

    public VersionedStringMsg(String name, Integer version, String list) {
        _name = name;
        _version = version;
        _string = list;
    }

    @Override
    public int getMsgType() {
        return VERSIONED_STRING_MSG;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        putString(buffer, _name);
        buffer.putInt(_version);
        putString(buffer, _string);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _name = getString(buffer);
        _version = buffer.getInt();
        _string = getString(buffer);
        return this;
    }

    @Override
    public void reset() {
        _name = null;
        _version = 0;
        _string = null;
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof VersionedStringMsg)) {
            return false;
        }
        VersionedStringMsg other = (VersionedStringMsg) obj;
        return _name.equals(other._name) && _string.equals(other._string) && _version == other._version;
    }

    @Override
    public int hashCode() {
        return _name.hashCode() * 31 + _string.hashCode() * 10191 + _version;
    }

    @Override
    public String toString() {
        return _name + "(" + _version + " " + _string + ")";
    }


    public void parse(BufferedReader reader) throws Exception {
        _version = Integer.parseInt(nextVal(reader, _name + ".version"));
        _string = nextVal(reader, _name);
    }

    public void format(BufferedWriter writer) {
        try {
            writer.write(_name + ".version=" + _version);
            writer.newLine();
            writer.write(_name + "=" + _string);
            writer.newLine();
        } catch (IOException x) {
            log.error("", x);
        }
    }

    private String nextVal(BufferedReader reader, String fieldName) throws IOException {
        String line = reader.readLine();
        int pos = line.indexOf('=');
        return line.substring(pos + 1); // not trim by design;
    }
}
