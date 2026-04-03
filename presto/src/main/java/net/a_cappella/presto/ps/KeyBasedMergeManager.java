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

package net.a_cappella.presto.ps;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashSet;
import java.util.Set;

public class KeyBasedMergeManager extends AbstractMergeManager {
    private static final Logger log = LoggerFactory.getLogger(KeyBasedMergeManager.class);

    private final SetOfObjKey _keysSet = new SetOfObjKey(new HashSet<>());

    @Override
    public void onSnpMsg(Obj obj) {
        if (_keysSet.containsKey(obj)) {
            log.info("NOT dispatching (wrong order) to {} obj={}", _subject, obj);
        } else {
            _subListener.onSubscriptionMessage(obj, _subId);
        }
    }

    @Override
    public void onPub(Obj obj) {
        _keysSet.add(obj);
        _subListener.onSubscriptionMessage(obj, _subId);
    }

    @Override
    public void onSnapComplete() {
        _keysSet.clear();
    }

    private static class SetOfObjKey {
        protected Set<ObjKey> _set;

        public SetOfObjKey(Set<ObjKey> set) {
            _set = set;
        }

        public boolean containsKey(Obj obj) {
            return _set.contains(obj.getObjKey());
        }

        public void add(Obj obj) {
            if (_set.add(obj.getObjKey())) obj.startUsing();
        }

        public void clear() {
            _set.forEach(key -> {key.getObj().stopUsing();});
            _set.clear();
        }
    }
}
