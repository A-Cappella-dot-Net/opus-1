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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class QueuedMergeManager extends AbstractMergeManager {
    private static final Logger log = LoggerFactory.getLogger(QueuedMergeManager.class);

    private final SnapHighWaterMark _hwm;
    private final List<Obj> _queue = new ArrayList<>();

    public QueuedMergeManager(SnapHighWaterMark hwm) {
        _hwm = hwm;
    }

    @Override
    public void onSnpMsg(Obj obj) {
        _subListener.onSubscriptionMessage(obj, _subId);
    }

    @Override
    public void onSnpHwm(Obj obj) {
        _hwm.initHighWaterMark(obj);
        _subListener.onHighWaterMark(obj);
    }

    @Override
    public void onPub(Obj obj) {
        obj.startUsing();
        _queue.add(obj);
    }

    @Override
    public void onSnapComplete() {
        for (int i=0; i<_queue.size(); i++) {
            Obj obj = _queue.get(i);
            if (!_hwm.isIncludedInSnap(obj)) {
                _subListener.onSubscriptionMessage(obj, _subId);
            } else {
                log.info("onSnapComplete dropping "+obj);
            }
            obj.stopUsing();
        }
        _queue.clear();
    }

}
