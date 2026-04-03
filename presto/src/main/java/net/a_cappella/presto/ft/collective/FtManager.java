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

package net.a_cappella.presto.ft.collective;

import net.a_cappella.presto.ft.beans.GroupAndInstance;
import net.a_cappella.presto.ft.beans.InstanceStatus;
import net.a_cappella.presto.ft.beans.MemAndKey;
import net.a_cappella.presto.ft.beans.MonAndKeys;
import net.a_cappella.presto.ft.collective.CollectiveMember.ClientPipe;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.msg.FtMemberMsg;
import net.a_cappella.presto.msg.FtMonitorMsg;
import net.a_cappella.presto.msg.FtMsg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.channels.SelectionKey;
import java.util.*;

import static net.a_cappella.continuo.PrestoConstants.NO;
import static net.a_cappella.continuo.PrestoConstants.YES;
import static net.a_cappella.continuo.utils.Utils.keyHash;
import static net.a_cappella.presto.ft.constants.FtMsgOp.*;
import static net.a_cappella.presto.ft.constants.FtMsgType.REQUEST;
import static net.a_cappella.presto.ft.constants.FtMsgType.RESPONSE;
import static net.a_cappella.presto.ft.constants.FtStatus.ACTIVE;
import static net.a_cappella.presto.ft.constants.FtStatus.INACTIVE;

public class FtManager {
    private static final Logger log = LoggerFactory.getLogger(FtManager.class);

    private final String _cmId;

    private final CollectiveMember _member;

    // first request establishes the goal
    private final Map<String, Integer> _goalsByGroup = new HashMap<>();
    // accumulated requests are sent to core members on core member connect
    private final Map<String, MonAndKeys> _activeMonRequests = new HashMap<>();
    private final Map<GroupAndInstance, MemAndKey> _activeMemRequests = new HashMap<>();

    // used for FT computations
    private final Map<String, List<InstanceStatus>> _statusesByGroup = new HashMap<>();

    private String memberStructsToString() {
        return
                "\n  goalsByGroup="+_goalsByGroup+
                        "\n  activeMonRequests="+_activeMonRequests+
                        "\n  activeMemRequests="+_activeMemRequests+
                        "\n  statusesByGroup="+_statusesByGroup;
    }

    public FtManager(CollectiveMember member) {
        _member = member;
        _cmId = member.getCmId();
    }

    // REQUESTs go from pipe to sink
    public void sinkOnFtMsgFromPipe(SelectionKey key, FtMsg msg) {
        if (log.isDebugEnabled()) log.info("{}sinkOnFtMsgFromPipe {} from {}", _cmId, msg, keyHash(key));

        char fromApp = msg._fromApp;
        if (msg._type == REQUEST) {
            FtMsgOp op = msg._op;
            if (op == REGISTER) {
                if (registerRequest(key, msg) == DUPLICATE) {
                    msg.set(RESPONSE, DUPLICATE, NO);
                    _member.sendMsg(key, msg);
                    return;
                }
            } else if (op == UNREGISTER) {
                unregisterRequest(key, msg);
            }
            if (fromApp == YES) {
                msg._type = REQUEST;
                msg._op = op; // original request type
                msg._fromApp = NO;
                _member.sendMsgToOtherCores(msg);
            }
        } else {
            log.info("{}Received {} is not a REQUEST. Ignoring...", _cmId, msg);
        }

        if (log.isTraceEnabled()) log.trace("{}{}", _cmId, memberStructsToString());
    }

    public void sinkOnPipeDisconnect(SelectionKey key) {
        if (log.isDebugEnabled()) log.info("{}sinkOnPipeDisconnect {}", _cmId, keyHash(key));

        // identify the GI registrations affected by the pipe disconnect
        Set<String> affectedGroups = new HashSet<>();
        List<GroupAndInstance> registeredGIsToRemove = new ArrayList<>();
        for (Map.Entry<GroupAndInstance, MemAndKey> entry : _activeMemRequests.entrySet()) {
            GroupAndInstance gi = entry.getKey();
            MemAndKey mk = entry.getValue();
            FtMemberMsg mem = mk._mem;
            if (mk._key.equals(key)) {
                // the disconnected key had an active Mem registration
                if (mk._fromApp == YES) { // first degree registration
                    // propagate the disconnect to the other cores
                    mem.set(REQUEST, UNREGISTER, NO);
                    _member.sendMsgToOtherCores(mem);
                }
                affectedGroups.add(gi._groupName);
                registeredGIsToRemove.add(gi);
            }
        }
        for (GroupAndInstance gi : registeredGIsToRemove) {
            _activeMemRequests.remove(gi);
            removeStruct(gi);
        }

        // identify the monitor group registrations affected by the pipe disconnect
        Set<String> monitoredGroupsToRemove = new HashSet<>();
        for (Map.Entry<String, MonAndKeys> entry : _activeMonRequests.entrySet()) {
            String group = entry.getKey();
            MonAndKeys mk = entry.getValue();
            FtMonitorMsg mon = mk._mon;
            Map<SelectionKey, Character> keys = mk._keys;
            for (Map.Entry<SelectionKey, Character> e : keys.entrySet()) {
                if (e.getKey().equals(key)) {
                    // the disconnected key had an active Mon registration
                    if (e.getValue() == YES) { // first degree registration
                        // propagate the disconnect to the other cores
                        mon.set(REQUEST, UNREGISTER, NO);
                        mon._actives = CollectiveClient.NONE;
                        _member.sendMsgToOtherCores(mon);
                    }
                    keys.remove(key);
                    break; // the disconnected key appears at most once in the map
                }
            }
            if (keys.isEmpty()) {
                // no monitor remaining for group
                monitoredGroupsToRemove.add(group);
            }
        }
        for (String groupName : monitoredGroupsToRemove) {
            _activeMonRequests.remove(groupName);
        }

        for (String groupName : affectedGroups) {
            evalMembership(groupName);
        }

        if (log.isTraceEnabled()) log.trace("{}{}", _cmId, memberStructsToString());
    }

    // RESPONSEs go from sink to pipe
    public void pipeOnFtMsgFromSink(FtMsg msg) {
        if (log.isDebugEnabled()) log.info("{}pipeOnFtMsgFromSink {}", _cmId, msg);
        if (msg instanceof FtMemberMsg) {
            FtMemberMsg mem = (FtMemberMsg) msg;
            String groupName = mem._groupName;
            GroupAndInstance gi = new GroupAndInstance(groupName, mem._instance);
            MemAndKey mk = _activeMemRequests.get(gi);
            if (mk == null) return;
            SelectionKey key = mk._key;
            _member.sendMsg(key, mem); // pass reply message back to source
            if (mem._op == DISCONNECT) { // core sends a DISCONNECT to App
                _activeMemRequests.remove(gi);
            }
        } else if (msg instanceof FtMonitorMsg) {
            FtMonitorMsg mon = (FtMonitorMsg) msg;
            String groupName = mon._groupName;
            MonAndKeys mk = _activeMonRequests.get(groupName);
            if (mk != null) {
                Map<SelectionKey, Character> keys = mk._keys;
                for (SelectionKey key : keys.keySet()) {
                    _member.sendMsg(key, mon); // pass reply message back to source
                }
            }
        }

        if (log.isTraceEnabled()) log.trace("{}{}", _cmId, memberStructsToString());
    }

    public void pipeOnSinkConnect(ClientPipe pipe) {
        if (log.isDebugEnabled()) log.info("{}pipeOnSinkConnect {}", _cmId, pipe);

        for (Map.Entry<GroupAndInstance, MemAndKey> entry : _activeMemRequests.entrySet()) {
            MemAndKey mk = entry.getValue();
            if (mk._fromApp == YES) {
                FtMemberMsg mem = mk._mem;
                mem.set(REQUEST, REGISTER, NO);
                _member.sendMsgToCore(mem, pipe);
            }
        }

        for (MonAndKeys mk : _activeMonRequests.values()) {
            FtMonitorMsg mon = mk._mon;
            mon.set(REQUEST, REGISTER, NO);
            mon._actives = CollectiveClient.NONE;
            for (Map.Entry<SelectionKey, Character> e : mk._keys.entrySet()) {
                if (e.getValue() == YES) {
                    _member.sendMsgToCore(mon, pipe);
                }
            }
        }

        if (log.isTraceEnabled()) log.trace("{}{}", _cmId, memberStructsToString());
    }

    public void pipeOnSinkDisconnect(ClientPipe pipe, boolean isCoreUp, boolean iBecamePrimary) {
        if (log.isDebugEnabled()) log.info("{}pipeOnSinkDisconnect {} isCoreUp={} iBecamePrimary={}", _cmId, pipe, isCoreUp, iBecamePrimary);

        if (isCoreUp) {
            if (iBecamePrimary) { // only the primary needs to handle the disconnect...

                // mem
                Set<String> affectedGroups = new HashSet<>();
                for (GroupAndInstance gi : _activeMemRequests.keySet()) {
                    affectedGroups.add(gi._groupName);
                }
                for (String groupName : affectedGroups) {
                    evalMembership(groupName, iBecamePrimary);
                }

                // mon - re-send reply to all sources
                for (String groupName : _activeMonRequests.keySet()) {
                    notifyFtMonitors(groupName, true);
                }
            }
        } else { // I am a pass thru and the core is not up; send DISCONNECT to the app
            // mem - disconnect all clients
            List<MemAndKey> list = new ArrayList<>(_activeMemRequests.values());
            for (int i=0; i<list.size(); i++) {
                MemAndKey mk = list.get(i);
                SelectionKey key = mk._key;
                FtMemberMsg mem = mk._mem;
                mem.set(RESPONSE, DISCONNECT, NO, 0, 0);
                _member.sendMsg(key, mem);
            }

            // mon
            for (MonAndKeys mk : _activeMonRequests.values()) {
                FtMonitorMsg mon = mk._mon;
                mon.set(RESPONSE, DISCONNECT, NO);
                mon._actives = CollectiveClient.NONE;
                for (SelectionKey key : mk._keys.keySet()) {
                    _member.sendMsg(key, mon);
                }
            }
        }

        if (log.isTraceEnabled()) log.trace("{}{}", _cmId, memberStructsToString());
    }







    private FtMsgOp registerRequest(SelectionKey key, FtMsg msg) {
        log.info("{}registerRequest {} {}", _cmId, keyHash(key), msg);
        FtMsgOp result = NONE;
        if (msg instanceof FtMonitorMsg) {
            FtMonitorMsg mon = (FtMonitorMsg) msg;
            String groupName = mon._groupName;
            MonAndKeys mk = _activeMonRequests.get(groupName);
            if (mk == null) {
                mk = new MonAndKeys(mon);
                _activeMonRequests.put(groupName, mk);
                result = REGISTER;
            }
            mk._keys.put(key, msg._fromApp);
            notifyFtMonitors(msg._groupName, true); // send the reply right back
        } else if (msg instanceof FtMemberMsg) {
            FtMemberMsg mem = (FtMemberMsg) msg;
            String groupName = mem._groupName;
            int instance = mem._instance;
            GroupAndInstance gi = new GroupAndInstance(groupName, instance);
            MemAndKey mk = _activeMemRequests.get(gi);
            if (mk == null) {
                mk = new MemAndKey(mem);
                _activeMemRequests.put(gi, mk);
                mk._key = key;
                mk._fromApp = msg._fromApp;
            } else if (!mk._key.equals(key)) {
                return DUPLICATE;
            } // else same key

            if (_member.iAmCore()) {
                addStruct(key, mem);
                evalMembership(mem._groupName);
            } else if (!_member.isCoreUp()) {
                mem.set(RESPONSE, DISCONNECT, NO, 0, 0);
                _member.sendMsg(key, mem);
            }
        }

        return result;
    }

    private void unregisterRequest(SelectionKey key, FtMsg msg) {
        String groupName = msg._groupName;
        if (msg instanceof FtMonitorMsg) {
            MonAndKeys mk = _activeMonRequests.get(groupName);
            if (mk != null) {
                mk._keys.remove(key);
                if (mk._keys.isEmpty()) {
                    _activeMonRequests.remove(groupName);
                }
            }
        } else if (msg instanceof FtMemberMsg) {
            FtMemberMsg mem = (FtMemberMsg) msg;
            int instance = mem._instance;
            GroupAndInstance gi = new GroupAndInstance(groupName, instance);
            MemAndKey mk = _activeMemRequests.get(gi);
            if (mk != null && mk._key.equals(key)) {
                mk._mem = mem;
                if (mem._fromApp == YES) {
                    mem.set(RESPONSE, DISCONNECT, NO, 0, 0);
                    _member.sendMsg(key, mem);
                }
                _activeMemRequests.remove(gi);
            }

            removeStruct(key, mem);
            evalMembership(mem._groupName);
        }
    }

    private void notifyFtMonitors(String groupName, boolean iBecamePrimary) {
        int actives = getActivesAsBitMask(groupName);
        MonAndKeys mk = _activeMonRequests.get(groupName);
        if (mk != null) {
            FtMonitorMsg msg = mk._mon;
            if (actives!=msg._actives || iBecamePrimary) {
                msg._actives = actives;
                msg._type = RESPONSE;
                msg._fromApp = NO;
                if (_member.iAmPrimary()) {
                    for (SelectionKey key : mk._keys.keySet()) {
                        _member.sendMsg(key, msg);
                    }
                }
            }
        }
    }
    private int getActivesAsBitMask(String groupName) {
        List<InstanceStatus> structsForGroup = _statusesByGroup.get(groupName);
        if (structsForGroup==null) {
            return 0;
        }
        int bitMask = 0;
        for (InstanceStatus ms : structsForGroup) {
            if (ms.getStatus()==ACTIVE) {
                bitMask |= 1 << ms.getInstance();
            }
        }
        return bitMask;
    }





    private boolean addStruct(SelectionKey key, FtMemberMsg mem) {
        log.info("{}addStruct {} {}", _cmId, keyHash(key), mem);
        String groupName = mem._groupName;
        int instance = mem._instance;
        InstanceStatus is = new InstanceStatus(instance);

        List<InstanceStatus> structsForGroup = _statusesByGroup.get(groupName);

        if (structsForGroup == null) {
            structsForGroup = new ArrayList<>();
            structsForGroup.add(is);
            _statusesByGroup.put(groupName, structsForGroup);
            _goalsByGroup.put(groupName, mem._activeGoal);
            return true;
        }

        ListIterator<InstanceStatus> iterator = structsForGroup.listIterator();
        while (iterator.hasNext()) {
            InstanceStatus itMs = iterator.next();
            if (itMs.getInstance() == instance) {
                return false;
            } else if (instance < itMs.getInstance()) {
                iterator.previous();
                break;
            }
        }

        iterator.add(is);
        return true;
    }
    private boolean removeStruct(SelectionKey key, FtMemberMsg mem) {
        String groupName = mem._groupName;
        int instance = mem._instance;
        List<InstanceStatus> structsForGroup = _statusesByGroup.get(groupName);
        if (structsForGroup == null) {
            return false;
        }
        for (InstanceStatus ms : structsForGroup) {
            if (instance > ms.getInstance()) {
                // continue searching
            } else if (ms.getInstance() == instance) {
                structsForGroup.remove(ms);
                if (structsForGroup.isEmpty()) {
                    _statusesByGroup.remove(groupName);
                    _goalsByGroup.remove(groupName);
                }
                return true;
            } else {
                return false;
            }
        }
        return false;
    }
    private void removeStruct(GroupAndInstance gi) {
        List<InstanceStatus> list = _statusesByGroup.get(gi._groupName);
        if (list == null) return;
        ListIterator<InstanceStatus> lit = list.listIterator();
        while (lit.hasNext()) {
            InstanceStatus is = lit.next();
            if (is.getInstance() == gi._instance) {
                lit.remove();
                break;
            }
        }
        if (list.isEmpty()) {
            _statusesByGroup.remove(gi._groupName);
        }
    }

    private void evalMembership(String groupName) {
        evalMembership(groupName, false);
    }
    private void evalMembership(String groupName, boolean iBecamePrimary) {
        List<InstanceStatus> structsForGroup = _statusesByGroup.get(groupName);
        if (structsForGroup==null || structsForGroup.isEmpty()) {
            log.info("{}evalMembership {} {}", _cmId, groupName, structsForGroup);
            notifyFtMonitors(groupName, false);
            return;
        }

        if (_member.iAmCore()) {
            int goal = _goalsByGroup.get(groupName);
            inactivateTail(groupName, structsForGroup, goal, iBecamePrimary);
            activateHead(groupName, structsForGroup, goal, iBecamePrimary);
        }
        log.info("{}evalMembership {} {}", _cmId, groupName, structsForGroup);
        notifyFtMonitors(groupName, false);
    }
    private void inactivateTail(String groupName, List<InstanceStatus> list, int goal, boolean iBecamePrimary) {
        for (int i=goal; i<list.size(); i++) {
            InstanceStatus is = list.get(i);
            if (is.getStatus()!=INACTIVE || iBecamePrimary) {
                is.set(INACTIVE, 0, 0);
                GroupAndInstance gi = new GroupAndInstance(groupName, is.getInstance());
                MemAndKey mk = _activeMemRequests.get(gi);
                FtMemberMsg msg = mk._mem;
                msg.set(RESPONSE, DEACTIVATE, NO, 0, 0);

                if (_member.iAmPrimary()) {
                    _member.sendMsg(mk._key, msg);
                }
            }
        }
    }
    private void activateHead(String groupName, List<InstanceStatus> list, int goal, boolean iBecamePrimary) {
        int maxActives = Math.min(list.size(), goal);
        for (int i=0; i<maxActives; i++) {
            InstanceStatus is = list.get(i);
            if (!is.already(ACTIVE, i, maxActives) || iBecamePrimary) {
                is.set(ACTIVE, i, maxActives);
                GroupAndInstance gi = new GroupAndInstance(groupName, is.getInstance());
                MemAndKey mk = _activeMemRequests.get(gi);
                FtMemberMsg msg = mk._mem;
                msg.set(RESPONSE, ACTIVATE, NO, i, maxActives);

                if (_member.iAmPrimary()) {
                    try {
                        _member.sendMsg(mk._key, msg);
                    } catch (Exception x) {
                        log.error("Could not send message to " + keyHash(mk._key), x);
                    }
                }

            }
        }
    }
}
