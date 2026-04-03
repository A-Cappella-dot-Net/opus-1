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

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.ps.ISubscriptionListener;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.MyEnum;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.TestObj;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BooleanSupplier;

import static net.a_cappella.continuo.utils.Utils.sleep;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class AeronClientTest {
    private static final Logger log = LoggerFactory.getLogger(AeronClientTest.class);

    // test multicast address does not interfere with PROD address
    private static final AeronClient _client = new ClientInstantiator("aeronClientTest@:8410", true, "ipc").getClient();

    Map<String, Object> _adHocs = new HashMap<>();
    {
        _adHocs.put("foo", "bar");
        _adHocs.put("pi", 3.1415926);
        _adHocs.put("ha", 4);
        _adHocs.put("haha", 'H');
        _adHocs.put("boo", true);
    }

    @BeforeEach
    public void setUp(TestInfo testInfo) {
        log.info("--------------------------------------------- "+testInfo.getDisplayName());
    }

    @AfterEach
    public void tearDown(TestInfo testInfo) {
        log.info("============================================= "+testInfo.getDisplayName());
    }

    @Test
    public void allTypesAndAdHocsTest() throws Exception {
        SubscriptionListener listener = new SubscriptionListener();

        long subId = _client.subscribe("select * from test", listener);

        long timeMillis = System.currentTimeMillis();

        TestObj obj = new TestObj();
        obj.set(Short.MIN_VALUE, Integer.MAX_VALUE, Long.MAX_VALUE, 'x', "testy", timeMillis, System.nanoTime(), PTime.fromMillis(timeMillis), PDate.fromMillis(timeMillis), (float) Math.PI, Math.PI, false, MyEnum.THREE);
        obj.setAdHocs(_adHocs);

        log.info(">>> "+obj);
        _client.publish(obj);

        eventually("", () -> listener.verify(obj));

        _client.unsubscribe(subId);
    }

    @Test
    public void simplePingTest() throws Exception {
        SubscriptionListener listener = new SubscriptionListener();

        long subId = _client.subscribe("select * from ping", listener);

        PingObj obj = new PingObj();
        obj.setId(1);
        obj.setPayload(7);

        log.info(">>> "+obj);
        _client.publish(obj);

        eventually("", () -> listener.verify(obj));

        _client.unsubscribe(subId);
    }

    @Test
    public void pingMapAndAdHocsTest() throws Exception {
        SubscriptionListener listener = new SubscriptionListener();

        long subId = _client.subscribe("select * from ping", listener);

        MapObj map = new MapObj();
        map.setSubject("ping");
        map.setInt("id", 17);
        map.setInt("payload", 13);

        map.setAdHocs(_adHocs);

        log.info(">>> "+map);
        _client.publish(map);

        eventually("", () -> listener.verify(map));

        _client.unsubscribe(subId);
    }

    @Test
    public void whereClauseSubscriptionTest() throws Exception {
        SubscriptionListener listener = new SubscriptionListener();

        long subId = _client.subscribe("select * from test where anInt < 5 and aChar='c'", listener);

        long timeMillis = System.currentTimeMillis();

        TestObj obj = new TestObj();
        obj.set(Short.MIN_VALUE, Integer.MAX_VALUE, Long.MAX_VALUE, 'c', "testy", timeMillis, System.nanoTime(), PTime.fromMillis(timeMillis), PDate.fromMillis(timeMillis), (float) Math.PI, Math.PI, true, MyEnum.THREE);

        obj.setAdHocs(_adHocs);

        log.info(">>> "+obj);
        _client.publish(obj);

        List<TestObj> selected = new ArrayList<>(10);

        for (int j=0; j<10; j++) {
            obj._anInt = j;
            obj._aChar = (j<3) ? 'd' : 'c';
            log.info(">>> "+obj);
            _client.publish(obj);

            if (obj._anInt < 5 && obj._aChar == 'c') {
                selected.add(new TestObj(obj));
            }
        }

        for (int i=0; i<selected.size(); i++) {
            final int j = i;
            eventually(""+i, () -> listener.verify(selected.get(j)));
        }

        _client.unsubscribe(subId);
    }





    protected static final int GIVEUP_INTERVAL_MILLIS = 2_000;
    protected static final int VERIFY_FREQUENCY_MILLIS = 10;

    protected void eventually(String str, BooleanSupplier supplier) {
        long giveUpTime = System.currentTimeMillis() + GIVEUP_INTERVAL_MILLIS;
        while (giveUpTime >= System.currentTimeMillis()) {
            sleep(VERIFY_FREQUENCY_MILLIS);
            if (supplier.getAsBoolean()) return;
        }
        assertTrue(supplier.getAsBoolean(), str);
    }


    private static class SubscriptionListener implements ISubscriptionListener {
        private final List<Obj> _received = new ArrayList<>(10);

        @Override // ISubscriptionListener
        public void onSubscriptionMessage(Obj obj, long subsId) {
            synchronized (_received) {
                obj.startUsing();
                _received.add(obj);
                log.info("<<< "+obj);
            }
        }

        public boolean verify(Obj obj) {
            synchronized (_received) {
                if (_received.isEmpty()) return false;
                Obj rec = _received.get(0);
                boolean same = obj.equals(rec);
                log.debug("obj={}    rec={}", obj, rec);
                if (same) {
                    _received.remove(0);
                    rec.stopUsing();
                }
                return same;
            }
        }
    }
}
