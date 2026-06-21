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

package net.a_cappella.test.presto.sns;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.MyEnum;
import net.a_cappella.presto.obj.TestObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TypesTest {
    private static final Logger log = LoggerFactory.getLogger(TypesTest.class);
    private static final boolean USE_MAP_MSG = false;

    private final PrestoClient _client;
	private final Obj _testMsg = (USE_MAP_MSG) ? new MapObj() : new TestObj();

    public TypesTest(PrestoClient client) {
    	_client = client;
    }

	public void start() throws Exception {
		String sql = "select * from test";
//		String sql = "select * from test where aDate in ('"+presto.utils.Utils.format("yyyy-MM-dd", new Date())+"')";
//		String sql = "select * from test where aTime > '"+presto.utils.Utils.format("HH:mm:ss.SSS", new Date())+"'";
//		String sql = "select * from test where aTimestamp >= '"+presto.utils.Utils.format("yyyy-MM-dd HH:mm:ss.SSS", new Date())+"'";
//		String sql = "select * from test where aChar <= 'c'";
//		String sql = "select * from test where aFloat>3.1415926 and aDouble>3.1415926";
//		String sql = "select * from test where anEnum=ONE";
//		String sql = "select * from test where aBoolean=true";
		log.info("--> "+sql);

		_client.waitUntilInitialized();

		_client.subscribe(sql, (obj, subsId) -> {
			try {
				obj.startUsing();
				log.info("received: "+obj);
			} catch (Exception x) {
				log.error("", x);
			} finally {
				obj.stopUsing();
			}
		});

		Thread.sleep(1000);

		boolean b = true;
        char c = 'c';
        double d = Math.PI;
        float f = (float) Math.PI;
        long l = Long.MAX_VALUE;
        long n = System.nanoTime();
        int i = Integer.MAX_VALUE;
        short s = Short.MAX_VALUE;
        String str = "test";
        long timeMillis = System.currentTimeMillis();
        int date = PDate.fromMillis(timeMillis);
        int time = PTime.fromMillis(timeMillis);
        MyEnum anEnum = MyEnum.ONE;

        if (USE_MAP_MSG) {
			MapObj map = (MapObj) _testMsg;
			map.setSubject(PrestoConstants.SUBJ_TEST);
			map.setBoolean("aBoolean", b);
			map.setChar("aChar", c);
			map.setDouble("aDouble", d);
			map.setFloat("aFloat", f);
			map.setLong("aLong", l);
			map.setLong("aNanos", n);
			map.setInt("anInt", i);
			map.setShort("aShort", s);
			map.setString("aString", str);
			map.setTimestamp("aTimestamp", timeMillis);
			map.setInt("aDate", date);
			map.setInt("aTime", time);
			map.setEnum("anEnum", anEnum);
		} else {
			TestObj tst = (TestObj) _testMsg;
	        tst.set(s, i, l, c, str, timeMillis, n, time, date, f, d, b, anEnum);
		}
		log.info("publishing test: "+_testMsg);
		_client.publish(_testMsg);

    }
}
