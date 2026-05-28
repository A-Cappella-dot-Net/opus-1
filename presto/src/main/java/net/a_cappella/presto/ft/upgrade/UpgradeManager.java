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

package net.a_cappella.presto.ft.upgrade;

import net.a_cappella.continuo.collective.ConnInfo;
import net.a_cappella.presto.ft.collective.CollectiveMember;
import net.a_cappella.presto.ft.collective.CollectiveMember.ClientPipe;
import net.a_cappella.presto.msg.VersionedStringMsg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

public class UpgradeManager {
    private static final Logger log = LoggerFactory.getLogger(UpgradeManager.class);

    private String _cmId;

    private final CollectiveMember _member;

    private int _version;
    private String _coreList;
    private VersionedStringMsg _coreMembersListMsg;
    private VersionedParamsCache _versionedParamsCache;

    public UpgradeManager(CollectiveMember member, int version, String coreList) {
        _member = member;
        _version = version;
        _coreList = coreList;
    }

    public void init() {
        _cmId = _member.getCmId();
        _coreMembersListMsg = new VersionedStringMsg(CollectiveMember.VSM_NAME, _version, _coreList);
        log.info("{}Initial core list is {}", _cmId, _coreMembersListMsg);
    }

    public String getCoreList() {
        return _coreList;
    }

    public int getVersion() {
        return _version;
    }

    public VersionedStringMsg getCoreMembersListMsg() {
        return _coreMembersListMsg;
    }

    public void setVersionedParamsCache(VersionedParamsCache versionedParamsCache) {
        _versionedParamsCache = versionedParamsCache;
    }



    public void upgrade(VersionedStringMsg vsm) {
        log.info("{}Upgrading {}core CollectiveMember. All v.{} core members are {}", _cmId, _member.iAmCore()?"":"non-", getVersion(), _member.getPipes());
        // save the new version details in the 'upgrade' file
        vsm = new VersionedStringMsg(vsm);
        if (_versionedParamsCache!=null) {
            _versionedParamsCache.add(vsm);
        }

        _coreList = vsm._string;
        _coreMembersListMsg = vsm;

        upgrade(getCoreList().split(","));

        _version = vsm._version;
        log.info("{}   ... to {}core CollectiveMember. All v.{} core members are {}", _cmId, _member.iAmCore()?"":"non-", getVersion(), _member.getPipes());
    }
    private void upgrade(String[] newComps) {
        List<ClientPipe> oldPipes = _member.getPipes();
        List<ClientPipe> newPipes = new ArrayList<>();
        List<ConnInfo> newConnInfos = new ArrayList<>();
        for (String compInfoStr : newComps) {
            String compInfo = compInfoStr.trim();
            ConnInfo connInfo = new ConnInfo(compInfo);
            newConnInfos.add(connInfo);
            ClientPipe pipe = getPipeForInfo(oldPipes, connInfo);
            if (pipe == null) {
                if (log.isDebugEnabled()) log.debug("{}core member was added {}", _cmId, compInfo);
                pipe = _member.createAndStartPipe(compInfo);
                _member.addSinkToPipeLinkage(new ConnInfo(compInfo), pipe);
            } else {
                if (log.isDebugEnabled()) log.debug("{}core member was preserved {}", _cmId, compInfo);
            }
            newPipes.add(pipe);
        }
        for (ClientPipe pipe : oldPipes) {
            if (!newConnInfos.contains(pipe.getConnInfo())) {
                if (log.isDebugEnabled()) log.debug("{}core member was removed {}", _cmId, pipe.getConnInfo());
                _member.removeSinkToPipeLinkage(pipe.getConnInfo());
                pipe.stopPipe();
            }
        }
        _member.calculateIAmCore(newPipes);
        _member.setPipes(newPipes);
    }
    private ClientPipe getPipeForInfo(List<ClientPipe> pipes, ConnInfo connInfo) {
        for (ClientPipe pipe : pipes) {
            if (pipe.getConnInfo().equals(connInfo)) return pipe;
        }
        return null;
    }
}
