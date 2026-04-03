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
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISnSHandler;
import net.a_cappella.continuo.ps.ISubscriptionListener;

public abstract class AbstractMergeManager implements IMergeManager {
    protected ISubscriptionListener _subListener;
    protected String _subject;
    protected long _subId;

    @Override
    public void setHandler(ISnSHandler handler) {
        _subListener = handler.getSubListener();
        _subject = handler.getSubject();
        _subId = handler.getSubId();
    }

    abstract public void onSnpMsg(Obj obj);
    abstract public void onPub(Obj obj);
    abstract public void onSnapComplete();
}
