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

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

import static net.a_cappella.continuo.PrestoConstants.PATHS_SUBJECTS;

public class PathsSubjectsMsg extends Msg {
    public List<Path> _paths;

    public PathsSubjectsMsg() {
    }

    @Override
    public int getMsgType() {
        return PATHS_SUBJECTS;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        if (_paths == null) {
            buffer.putShort((short) -1);
        } else {
            buffer.putShort((short) _paths.size());
            for (Path path : _paths) {
                path.encode(buffer);
            }
        }
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        short size = buffer.getShort();
        if (size >= 0) {
            _paths = new ArrayList<>(size);
            for (int i = 0; i < size; i++) {
                Path path = new Path();
                path.decode(buffer, len);
                _paths.add(path);
            }
        } else {
            _paths = null;
        }
        return this;
    }

    @Override
    public void reset() {
        if (_paths != null) {
            _paths.clear();
        }
    }

    @Override
    public String toString() {
        return "{" + _paths + "}";
    }

    public Path add(String filePath) {
        Path path = new Path(filePath);
        if (_paths == null) _paths = new ArrayList<>();
        _paths.add(path);
        return path;
    }

    public static class Path {
        public String _path;
        public List<String> _subjects;

        public Path() {
        }

        public Path(String path) {
            _path = path;
        }

        public void add(String subject) {
            if (_subjects == null) _subjects = new ArrayList<>();
            _subjects.add(subject);
        }

        public void encode(ByteBuffer buffer) {
            putString(buffer, _path);
            if (_subjects == null) {
                buffer.putShort((short) -1);
            } else {
                buffer.putShort((short) _subjects.size());
                for (String subject : _subjects) {
                    putString(buffer, subject);
                }
            }
        }

        public Path decode(ByteBuffer buffer, int len) {
            _path = getString(buffer);
            short size = buffer.getShort();
            if (size >= 0) {
                _subjects = new ArrayList<>(size);
                for (int j = 0; j < size; j++) {
                    String subject = getString(buffer);
                    _subjects.add(subject);
                }
            } else {
                _subjects = null;
            }
            return this;
        }

        @Override
        public String toString() {
            return "{" + _path + ":" + _subjects + "}";
        }
    }
}
