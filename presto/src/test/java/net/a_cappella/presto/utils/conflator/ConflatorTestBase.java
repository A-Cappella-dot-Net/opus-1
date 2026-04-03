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

package net.a_cappella.presto.utils.conflator;

import net.a_cappella.presto.ft.collective.IFtMsgListenerNotifier;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static net.a_cappella.continuo.utils.Utils.sleep;
import static org.junit.jupiter.api.Assertions.assertEquals;

public class ConflatorTestBase {
    protected static Logger log = LoggerFactory.getLogger(ConflatorTestBase.class);

    protected static final int INTER_TEST_DELAY_MILLIS = 10;

    protected ConflatorTestListenerNotifier _notifier = new ConflatorTestListenerNotifier();

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        log.info("--------------------------------- "+testInfo.getDisplayName());
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        _notifier.verifyMon();
        log.info("================================= "+testInfo.getDisplayName());
        sleep(INTER_TEST_DELAY_MILLIS);
    }




    protected MonConflator monConflator(long conflationInterval) {
        return new MonConflator(conflationInterval, _notifier);
    }
    protected MonStruct mon(String groupName, int actives) {
        return new MonStruct(groupName, actives);
    }
    protected static class MonStruct {
        String _groupName;
        int _actives;

        MonStruct(String groupName, int actives) {
            _groupName = groupName;
            _actives = actives;
        }
        @Override
        public String toString() {
            return "{"+_groupName+", "+_actives+"}";
        }
    }

    protected MemConflator memConflator(long conflationInterval) {
        return new MemConflator(conflationInterval, _notifier);
    }
    protected MemStruct mem(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices) {
        return new MemStruct(groupName, instance, op, sliceNo, ofSlices);
    }
    protected static class MemStruct {
        String _groupName;
        int _instance;
        FtMsgOp _op;
        int _sliceNo;
        int _ofSlices;

        MemStruct(String groupName, int instance, FtMsgOp op, int sliceNo, int ofSlices) {
            _groupName = groupName;
            _instance = instance;
            _op = op;
            _sliceNo = sliceNo;
            _ofSlices = ofSlices;
        }
        @Override
        public String toString() {
            return "{"+_groupName+"-"+_instance+" "+_op+" "+_sliceNo+"/"+_ofSlices+"}";
        }
    }

    protected class ConflatorTestListenerNotifier implements IFtMsgListenerNotifier {
        private final List<MonStruct> _monList = new ArrayList<>();
        private final List<MemStruct> _memList = new ArrayList<>();

        public void verifyMon(MonStruct... expected) {
            try {
                assertEquals(Arrays.asList(expected).toString(), _monList.toString());
            } finally {
                _monList.clear();
            }
        }

        public void verifyMem(MemStruct... expected) {
            try {
                assertEquals(Arrays.asList(expected).toString(), _memList.toString());
            } finally {
                _memList.clear();
            }
        }

        @Override
        public void notifyFtMemberListeners(String groupName, int instance, FtMsgOp action, int sliceNo, int ofSlices) {
            log.info("onFtMemMsg("+groupName+"-"+instance+" '"+action+"'"+sliceNo+"/"+ofSlices+")");
            _memList.add(new MemStruct(groupName, instance, action, sliceNo, ofSlices));
        }
        @Override
        public void notifyFtMonitorListeners(String groupName, int actives) {
            log.info("notifyFtMonitorListeners("+groupName+" "+actives+")");
            _monList.add(new MonStruct(groupName, actives));
        }

        @Override
        public String getNotifierId() {
            return "";
        }
    }
}
