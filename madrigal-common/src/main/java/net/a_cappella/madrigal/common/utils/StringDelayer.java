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

package net.a_cappella.madrigal.common.utils;

import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.utils.DelayQueue;
import net.a_cappella.continuo.utils.DelayedObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class StringDelayer {
    private static final Logger log = LoggerFactory.getLogger(StringDelayer.class);

    private int _queueSize = 100;
    private long _delayInMillis = 1000;

    public StringDelayer() {}
    public StringDelayer(int queueSize) {
    	_queueSize = queueSize;
    }
    public StringDelayer(long delayInMillis) {
    	_delayInMillis = delayInMillis;
    }
    public StringDelayer(int queueSize, long delayInMillis) {
    	_queueSize = queueSize;
    	_delayInMillis = delayInMillis;
    }

    public void start() {
    	new StringDelayerThread().start();
    }

	public void add(String str) {
		_delayQueue.add(_delayInMillis, str);
	}
	public void add(long delayInMillis, String str) {
		_delayQueue.add(delayInMillis, str);
	}

	public abstract void execute(String str);

    private class StringDelayerThread extends Thread {
    	private final StringDelayedObj _obj = new StringDelayedObj();

    	public void run() {
            ShutdownHook.registerShutdownAction(() -> signalStop());
    		log.debug("Starting StringDelayerThread");
            while (true) {
                try {
                    _delayQueue.take(_obj);
                    if (_obj.isPoisonPill()) break;
                    if (log.isDebugEnabled()) {
                        log.info("delayed removing "+_obj._str);
                    }
                    execute(_obj._str);
                } catch (Exception e) {
                    log.error("", e);
                }
            }
    		log.debug("StringDelayerThread Stopped");
        }

    	private void signalStop() {
    		log.debug("Stopping StringDelayerThread");
    		_delayQueue.addPoisonPill();
    	}
    }

    private final StringDelayQueue _delayQueue = new StringDelayQueue(new StringDelayedObj());

    private class StringDelayQueue extends DelayQueue<StringDelayedObj> {
    	public StringDelayQueue(StringDelayedObj clone) {
			super(_queueSize, clone);
		}

		public StringDelayedObj add(long delayInMillis, String str) {
    		StringDelayedObj obj = add(delayInMillis);
			obj._str = str;
    		return obj;
    	}

		@Override
		public void updateFrom(StringDelayedObj dst, StringDelayedObj src) {
        	super.updateFrom(dst, src);
        	dst._str = src._str;
        }
    }

    private static class StringDelayedObj extends DelayedObj {
        private String _str;

    	private StringDelayedObj() {}
        public StringDelayedObj newInstance() { // only invoked to replenish the pool if exhausted
        	return new StringDelayedObj();
        }
    }
}
