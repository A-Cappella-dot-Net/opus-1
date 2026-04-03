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

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.continuo.ps.ISnSHandler;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.obj.SnapRequestObj;
import net.a_cappella.presto.obj.SnapTimeoutObj;
import net.a_cappella.presto.ps.SnSManager.SnSOpType;
import net.a_cappella.presto.ps.sql.SqlParserResult;
import net.a_cappella.presto.ps.sql.WhereNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

public class SnSHandler implements ISnSHandler {
    private static final Logger log = LoggerFactory.getLogger(SnSHandler.class);

    private final SnapTimeoutObj _snapTimeoutObj = new SnapTimeoutObj();

    private PubSubClient _client;
    private final SnSManager _mgr;

    private final String _sql;
    private String _subject;
    private final WhereNode _evalTree;
    private long _subId;
    private final SnSOpType _opType;

    private final ISubscriptionListener _subListener;
    private ISnapCompleteListener _snapCompleteListener;
    private ISnapRequestListener _snapRequestListener;

    private SnapPhase _snapPhase;

    public SnSHandler(PubSubClient client, SnSManager mgr, SqlParserResult sqlComps, long subId, SnSManager.SnSOpType opType, ISubscriptionListener subListener) {
        _client = client;
        _mgr = mgr;

        _sql = sqlComps.getSql();
        _subject = sqlComps.getFromTable();
        _evalTree = sqlComps.getEvalTree();
        if (_evalTree!=null) {
            _evalTree.updateEvalSupportingFields(_subject, ObjectManager.getInstance().getSubjectMetaInfo(_subject));
        }
        _subId = subId;
        _opType = opType;

        _subListener = subListener;
        if (_subListener instanceof ISnapCompleteListener) {
            _snapCompleteListener = (ISnapCompleteListener) _subListener;
        }
        if (_subListener instanceof ISnapRequestListener) {
            _snapRequestListener = (ISnapRequestListener) _subListener;
        }
    }

    @Override
    public String getSubject() {
        return _subject;
    }
    @Override
    public ISubscriptionListener getSubListener() {
        return _subListener;
    }
    @Override
    public long getSubId() {
        return _subId;
    }

    public WhereNode getEvalTree() {
        return _evalTree;
    }

    public void initiateSnap(long fromInitMillis, long fromLatestMillis, IMergeManager mergeManager) {
        if (mergeManager != null) mergeManager.setHandler(this);
        // start timer (in case there is no snap service for this subscription)
        log.debug("Snapping from the cache on <{}>", _sql);
        _snapPhase = new SnapPhase(fromInitMillis, fromLatestMillis, mergeManager);
    }
    private void completeSnap() {
        _snapPhase = null;

        if (_opType == SnSOpType.SNAP) { // snap with no subscription
            _mgr.unsubscribe(_subId);
            log.debug("unsubscribed {}", _subject);
        }
        if (_snapCompleteListener!=null) {
            log.debug("completeSnap {}", _subject);
            _snapCompleteListener.onSnapComplete(_subId);
        }
    }

    public void onMsg(Obj obj) {
        obj.startUsing();
        try {
            PubType pubType = obj.getPubType();
            switch (pubType) {
                case PUB:
                    if (_opType == SnSOpType.SNAP) return; // received a PUB but I only SNAPed, so ignore this message
                    if (_snapPhase == null) _subListener.onSubscriptionMessage(obj, _subId); // received a PUB after timer expiration
                    else _snapPhase.onPub(obj); // received a PUB while in SnS phase => merge manager will decide what to do
                    break;
                case SNP: // snap request received by a managed cache
                    // a managed cache only issues subscribe or snapSubscribe requests to build the cache otherwise it would be a static cache
                    if (_opType != SnSOpType.SNAP && _snapRequestListener != null) {
                        _snapRequestListener.onSnapRequest((SnapRequestObj) obj, _subId);
                    }
                    break;
                case SNP_BEGIN:
                    if (_snapPhase == null) log.info("Dropping SNP_BEGIN received AFTER timer expiration");
                    else _snapPhase.onSnpBegin();
                    break;
                case SNP_MSG:
                    if (_snapPhase == null) log.info("Dropping SNP_MSG received AFTER timer expiration {}", obj);
                    else _snapPhase.onSnpMsg(obj);
                    break;
                case SNP_END:
                    if (_snapPhase == null) log.info("Dropping SNP_END received AFTER timer expiration");
                    else _snapPhase.onSnpEnd();
                    break;
                case SNP_TIMEOUT:
                    SnapTimeoutObj snapTimeout = (SnapTimeoutObj) obj;
                    log.debug("loopbackDelayNanos = {}", System.nanoTime() - snapTimeout.getTs());
                    _snapPhase.onTimerExpiry();
                    break;
                case SNP_HWM:
                    if (_snapPhase == null) log.info("Dropping SNP_HWM received AFTER timer expiration {}", obj);
                    else _snapPhase.onSnpHwm(obj);
                    break;
                default:
            }
        } catch (Exception x) {
            log.error(x.getMessage(), x);
        } finally {
            obj.stopUsing();
        }
    }

    public void shutdown() {
        if (log.isDebugEnabled() && _opType != SnSOpType.SNAP) log.debug("shutting down {} {} => {}", _opType, _sql, _subId);
        if (_snapPhase!=null) {
            _snapPhase.onSnapComplete();
        }
    }

    private final Runnable _schedulerRunnable = () -> {
        try {
            _snapTimeoutObj.set(_subject, _subId, System.nanoTime());
            _client.loopback(_snapTimeoutObj);
        } catch (Exception e) {
            log.error("Could not loop back {}", _snapTimeoutObj, e);
        }
    };

    private class SnapPhase {
        private final long _fromLatestMillis;
        private IMergeManager _mergeManager;

        private ScheduledFuture<?> _future;
        private int _snpCount;

        public SnapPhase(long fromInitMillis, long fromLatestMillis, IMergeManager mergeManager) {
            _fromLatestMillis = fromLatestMillis;
            if (mergeManager != null) _mergeManager = mergeManager;
            log.debug("scheduling {} delay {}", _subject, fromInitMillis);
            _future = _mgr.getScheduler().schedule(_schedulerRunnable, fromInitMillis, TimeUnit.MILLISECONDS);
        }

        private void onSnpBegin() {
            if (_future!=null) {
                _future.cancel(false);
                log.debug("re-scheduling {} delay {}", _subject, _fromLatestMillis);
                _future = _mgr.getScheduler().schedule(_schedulerRunnable, _fromLatestMillis, TimeUnit.MILLISECONDS);
            } else {
                log.info("Dropping SNP_BEGIN received AFTER timer expiration");
            }
        }
        private void onSnpMsg(Obj obj) {
            log.debug("on snap msg {}", _subject);
            if (_opType == SnSOpType.SNAP) { // SNAP only
                _subListener.onSubscriptionMessage(obj, _subId);
            } else { // SNAP_SUBSCRIBE
                updateMergeManager(obj);
                _mergeManager.onSnpMsg(obj);
            }
            _snpCount++;
        }
        private void onSnpHwm(Obj obj) {
            log.debug("on snap hwm {}", _subject);
            if (_mergeManager != null) _mergeManager.onSnpHwm(obj);
        }
        private void onSnpEnd() {
            if (_future!=null) {
                _future.cancel(false);
                _future = null;
            } else {
                log.info("Dropping SNP_END received AFTER timer expiration");
            }
            log.debug("done snapping (marker) {}", _subject);
            onSnapComplete();
        }
        private void onPub(Obj obj) {
            updateMergeManager(obj);
            _mergeManager.onPub(obj);
        }
        private void updateMergeManager(Obj obj) {
            if (_mergeManager == null) {
                _mergeManager = obj.newMergeManager();
                _mergeManager.setHandler(SnSHandler.this);
            }
        }

        private void onTimerExpiry() {
            if (_snpCount > 0) {
                log.debug("re-scheduling {} delay {}", _subject, _fromLatestMillis);
                _future = _mgr.getScheduler().schedule(_schedulerRunnable, _fromLatestMillis, TimeUnit.MILLISECONDS);
                _snpCount = 0;
            } else { // no replies in the prior interval
                log.debug("done snapping (expired) {}", _subject);
                log.warn("Did not get a snap END message. Is a Snap Service running for subject '{}'?", _subject);
                onSnapComplete();
            }
        }

        private void onSnapComplete() {
            if (_mergeManager != null) _mergeManager.onSnapComplete(); // _mergeManager is null for snap only
            completeSnap();
        }
    }


    @Override
    public String toString() {
        return "{subId="+_subId+", subject="+_subject+"}";
    }

}
