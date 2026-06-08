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

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public final class ProxyRouter {
    private static final ConcurrentMap<RouteKey, SocketAddress> ROUTES = new ConcurrentHashMap<>();
    private static final Map<String, CntFromTo> PROXIES = new HashMap<>();

    public static void redirect(String localhost, IdFromTo[] idFromTos) {
        for (int i = 0; i < idFromTos.length; i++) {
            IdFromTo ift = idFromTos[i];
            String id = ift._id;
            SocketAddress from = new InetSocketAddress(localhost, ift._from);
            SocketAddress to = new InetSocketAddress(localhost, ift._to);
            System.out.println("ProxyRouter.redirect (" + id + ", " + from + ") => " + to);
            ROUTES.put(new RouteKey(id, from), to);
            String key = ift._to + ":" + ift._from;
            CntFromTo entry = PROXIES.get(key);
            if (entry == null) {
                PROXIES.put(key, new CntFromTo(1, ift._to, ift._from));
            } else {
                entry._cnt++;
            }
        }
    }

    public static CntFromTo[] forwards() {
        CntFromTo[] forwards = new CntFromTo[PROXIES.size()];
        int i = 0;
        for (CntFromTo entry : PROXIES.values()) {
            forwards[i++] = entry;
        }
        return forwards;
    }

    public static void clear() {
        ROUTES.clear();
        PROXIES.clear();
    }

    /** If there is a defined route from the current RouteKey then redirect to that value */
    public static SocketAddress resolve(SocketAddress requested) {
        if (requested instanceof InetSocketAddress) {
            String id = ThreadMarker.getMark();
            if (id != null) {
                SocketAddress resolved = ROUTES.get(new RouteKey(id, requested));
                if (resolved != null) {
                    System.out.println("ProxyRouter.resolve requested=" + requested + " resolved=" + resolved);
                    return resolved;
                }
            }
        }
        return requested;
    }
}