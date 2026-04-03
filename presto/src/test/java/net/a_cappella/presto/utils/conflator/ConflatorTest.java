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

import org.junit.jupiter.api.Test;

import static net.a_cappella.continuo.utils.Utils.sleep;
import static net.a_cappella.presto.ft.collective.CollectiveClient.*;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class ConflatorTest extends ConflatorTestBase {
    private static final int CONF = 300;
    private static final int QUICK = 10;
    private static final int SLOW = 400;
    private static final String GRP1 = "GRP1";
    private static final String GRP2 = "GRP2";

    @Test
    public void noConflationSingleMessageTest() {
        MonConflator monConflator = monConflator(0);
        MemConflator memConflator = memConflator(0);

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon(mon(GRP1, ZERO));

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));
    }

    @Test
    public void noConflationNoDupMessageTest() {
        MonConflator monConflator = monConflator(0);
        MemConflator memConflator = memConflator(0);

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon(mon(GRP1, ZERO));

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon();

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        _notifier.verifyMem();
    }

    @Test
    public void noConflationForcedMessageTest() {
        MonConflator monConflator = monConflator(0);
        MemConflator memConflator = memConflator(0);

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon(mon(GRP1, ZERO));

        monConflator.conflate(GRP1, ZERO, true);	// forced
        _notifier.verifyMon(mon(GRP1, ZERO));		// dup sent

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1, true);	// forced
        _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));		// dup sent
    }

    @Test
    public void withConflationSingleMessageTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

    }

    @Test
    public void withConflationNoDupMessageTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, ZERO);
        sleep(SLOW); _notifier.verifyMon();				// dup not notified

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(SLOW); _notifier.verifyMem();								// dup not notified
    }

    @Test
    public void withConflationForcedMessageTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, ZERO, true);			// forced
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// dup sent

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1, true);			// forced
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// dup sent
    }

    @Test
    public void withConflationForcedMessageCornerCaseTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO, true);			// forced
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// dup sent overriding everything else

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

        memConflator.conflate(GRP1, 1, DEACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1, true);			// forced
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// dup sent overriding everything else
    }

    @Test
    public void withConflationConflatedMessageTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO|ONE);					// TODO in quick sequence
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO|ONE));	// TODO only the latest message is sent

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 2);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        memConflator.conflate(GRP1, 1, ACTIVATE, 1, 2);					// in quick sequence
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 1, 2));	// only the latest message is sent
    }

    @Test
    public void withConflationConflatedMessageCornerCaseTest() {
        MonConflator monConflator = monConflator(CONF);
        MemConflator memConflator = memConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, NONE);
        sleep(QUICK); _notifier.verifyMon();	// not released yet
        monConflator.conflate(GRP1, ZERO);			// in quick sequence
        sleep(SLOW); _notifier.verifyMon();		// was just a blip, nothing sent

        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();							// not released yet
        sleep(SLOW); _notifier.verifyMem(mem(GRP1, 1, ACTIVATE, 0, 1));	// released

        memConflator.conflate(GRP1, 1, DEACTIVATE, 0, 1);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        memConflator.conflate(GRP1, 1, ACTIVATE, 0, 1);	// in quick sequence
        sleep(SLOW); _notifier.verifyMem();				// was just a blip, nothing sent
    }

    @Test
    public void noConflationTest() {
        MonConflator monConflator = monConflator(0);

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon(mon(GRP1, ZERO));		// get the notification right away for GRP1

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon();					// do not get a duplicate notification

        monConflator.conflate(GRP2, ZERO);
        _notifier.verifyMon(mon(GRP2, ZERO));		// get the notification right away for GRP2

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon();					// do not get a duplicate notification

        monConflator.conflate(GRP2, ZERO);
        _notifier.verifyMon();					// do not get a duplicate notification

        monConflator.conflate(GRP1, ONE);
        _notifier.verifyMon(mon(GRP1, ONE));		// get the notification right away for GRP1

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon(mon(GRP1, ZERO));		// get the notification right away for GRP1

        monConflator.conflate(GRP1, ZERO);
        _notifier.verifyMon();					// do not get a duplicate notification

        monConflator.conflate(GRP1, ZERO, true);
        _notifier.verifyMon(mon(GRP1, ZERO));		// get the forced notification right away for GRP1

    }

    @Test
    public void conflationTest() {
        MonConflator monConflator = monConflator(CONF);

        monConflator.conflate(GRP1, ZERO);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO));	// released

        monConflator.conflate(GRP1, ZERO);
        sleep(SLOW); _notifier.verifyMon();				// do not get a duplicate notification

        monConflator.conflate(GRP1, ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO);				// it was a blip
        sleep(SLOW); _notifier.verifyMon();				// conflation results in no message out

        monConflator.conflate(GRP1, ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO|ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO);				// it was a blip
        sleep(SLOW); _notifier.verifyMon();				// conflation results in no message out

        monConflator.conflate(GRP1, ONE);
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        monConflator.conflate(GRP1, ZERO|ONE);			// conflated
        sleep(QUICK); _notifier.verifyMon();			// not released yet
        sleep(SLOW); _notifier.verifyMon(mon(GRP1, ZERO|ONE));	// only the latest is released

    }

}
