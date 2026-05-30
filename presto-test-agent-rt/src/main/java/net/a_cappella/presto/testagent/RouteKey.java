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

package net.a_cappella.presto.testagent;

import java.net.SocketAddress;
import java.util.Objects;

public final class RouteKey {
    private final String _id;       // who is connecting (from ThreadMarker)
    private final SocketAddress _target;  // where they asked to connect

    public RouteKey(String id, SocketAddress target) {
        _id = id;
        _target = target;
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof RouteKey other)) return false;
        return Objects.equals(_id, other._id) && Objects.equals(_target, other._target);
    }

    @Override
    public int hashCode() {
        return Objects.hash(_id, _target);
    }

    @Override
    public String toString() {
        return "RouteKey[" + _id + " -> " + _target + "]";
    }
}