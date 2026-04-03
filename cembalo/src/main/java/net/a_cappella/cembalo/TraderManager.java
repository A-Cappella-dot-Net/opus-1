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

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class TraderManager {
    private final Credentials _credentials;
    private final Map<SelectionKey, List<String>> _bySelectionKey = new HashMap<>();
    private final Map<String, SelectionKey> _byUid = new HashMap<>();

    private final Lock _lock = new ReentrantLock();

    public TraderManager(Credentials credentials) {
        _credentials = credentials;
    }

    public LogInOutStatus login(String uid, String pwd, SelectionKey selectionKey) {
        if (!_credentials.allowed(uid, pwd)) return LogInOutStatus.LOGIN_INVALID_CREDENTIALS;
        _lock.lock();
        try {
            SelectionKey connectedSelectionKey = _byUid.get(uid);
            if (connectedSelectionKey==null) {
                _byUid.put(uid, selectionKey);
                _bySelectionKey.computeIfAbsent(selectionKey, k -> new ArrayList<>()).add(uid);
                return LogInOutStatus.LOGIN_YES;
            } else {
                if (connectedSelectionKey.equals(selectionKey)) return LogInOutStatus.LOGIN_YES_ALREADY;
                return LogInOutStatus.LOGIN_NO_ALREADY;
            }
        } finally {
            _lock.unlock();
        }
    }

    public LogInOutStatus logout(String uid, SelectionKey selectionKey) {
        _lock.lock();
        try {
            SelectionKey connectedSelectionKey = _byUid.get(uid);
            if (connectedSelectionKey==null) {
                return LogInOutStatus.LOGOUT_ALREADY;
            } else {
                if (connectedSelectionKey.equals(selectionKey)) {
                    _byUid.remove(uid);
                    _bySelectionKey.get(selectionKey).remove(uid);
                    return LogInOutStatus.LOGOUT_YES;
                }
                return LogInOutStatus.LOGOUT_NO_DIFFERENT_CONNECTION;
            }
        } finally {
            _lock.unlock();
        }
    }

    public void disconnect(SelectionKey selectionKey) {
        _lock.lock();
        try {
            List<String> uids = _bySelectionKey.remove(selectionKey);
            if (uids!=null) {
                for (int i=0; i<uids.size(); i++) {
                    String uid = uids.get(i);
                    _byUid.remove(uid);
                }
            }
        } finally {
            _lock.unlock();
        }
    }

    public boolean isLoggedIn(final String uid, final SelectionKey key) {
        _lock.lock();
        try {
            List<String> traders = _bySelectionKey.get(key);
            return traders!=null && traders.contains(uid);
        } finally {
            _lock.unlock();
        }
    }
}
