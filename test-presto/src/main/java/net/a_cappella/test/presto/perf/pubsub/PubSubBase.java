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

package net.a_cappella.test.presto.perf.pubsub;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.utils.StatsLogger;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.EmbeddedMediaDriver;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.MyEnum;
import net.a_cappella.presto.obj.PingObj;
import net.a_cappella.presto.obj.TestObj;
import net.a_cappella.presto.ps.PrestoClient;
import net.a_cappella.test.presto.perf.StatsTestParams;
import net.a_cappella.test.presto.perf.StatsTestsParams;
import org.HdrHistogram.Histogram;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class PubSubBase {
    private static final Logger log = LoggerFactory.getLogger(PubSubBase.class);

    protected static final String TAB = StatsLogger.TAB;

    protected static final int BEFORE_WARMUP_WAIT_MILLIS = 500;
    protected static final int BEFORE_TEST_WAIT_MILLIS = 100;

    protected static final int ONE_IN_N = 4;
    protected static final int WUP_SIZE = 1_000_000;
    protected static final int TST_SIZE = 1_000_000;

    protected static final String _localhost = Utils._localhost;
    protected static String _channelType;
    protected static String _mediaDriverType;

    protected enum TestMsgType {
    	PING, TEST
    }
    protected enum SelectorIn {
    	NO, HEADER, KEYS, BODY
    }

    protected EmbeddedMediaDriver _mediaDriver;
    public void setMediaDriver(EmbeddedMediaDriver mediaDriver) {
    	_mediaDriver = mediaDriver;
    }

    protected TightLoopThread _tightLoopThread;
    public void setTightLoopThread(TightLoopThread tightLoopThread) {
    	_tightLoopThread = tightLoopThread;
    }

    protected static TestMsgType _tstMsgType;
    protected static boolean _useMapMsg = false;
    protected static boolean _useAdHocs = false;
    protected static SelectorIn _selIn = SelectorIn.NO;
    protected static boolean _useGenericGetters = false;

    protected static String _pingSubject = "ping";
    protected static String _testSubject = "test";

    protected static String _sqlPingNoSel = "select * from ping";
    protected static String _sqlPingSelInHeader = "select * from ping where mine=0";
    protected static String _sqlPingSelInKeys = "select * from ping where id=0";
    protected static String _sqlPingSelInBody = "select * from ping where payload=0";

    protected static String _sqlTestNoSel = "select * from test";
    protected static String _sqlTestSelInHeader = "select * from test where mine=0";
    protected static String _sqlTestSelInKeys = "select * from test where anInt=0";
    protected static String _sqlTestSelInBody = "select * from test where aLong=0";

    protected static PingObj _pingObj = new PingObj();
    protected static TestObj _testObj = new TestObj();
    protected static MapObj _pingMap = new MapObj();
    protected static MapObj _testMap = new MapObj();

    protected static PingObj _pingObjAdHocs = new PingObj();
    protected static TestObj _testObjAdHocs = new TestObj();
    protected static MapObj _pingMapAdHocs = new MapObj();
    protected static MapObj _testMapAdHocs = new MapObj();

    protected static Map<String, Object> _adHocs = new HashMap<>();

    static {
    	_pingMap.setSubject(_pingSubject);
    	_pingMapAdHocs.setSubject(_pingSubject);
    	_testMap.setSubject(_testSubject);
    	_testMapAdHocs.setSubject(_testSubject);

        long timeMillis = System.currentTimeMillis();
        int date = PDate.fromMillis(timeMillis);
        int time = PTime.fromMillis(timeMillis);

        _testMap.setBoolean("aBoolean", true);
    	_testMap.setChar("aChar", 'c');
    	_testMap.setDouble("aDouble", Math.PI);
    	_testMap.setFloat("aFloat", (float) Math.PI);
    	_testMap.setString("aString", "test");
    	_testMap.setEnum("anEnum", MyEnum.ONE);
    	_testMap.setLong("aLong", Long.MAX_VALUE);
    	_testMap.setInt("anInt", Integer.MAX_VALUE);
    	_testMap.setShort("aShort", Short.MAX_VALUE);
    	_testMap.setTimestamp("aTimestamp", timeMillis);
    	_testMap.setDate("aDate", date);
    	_testMap.setTime("aTime", time);

    	_testMapAdHocs.setBoolean("aBoolean", true);
    	_testMapAdHocs.setChar("aChar", 'c');
    	_testMapAdHocs.setDouble("aDouble", Math.PI);
    	_testMapAdHocs.setFloat("aFloat", (float) Math.PI);
    	_testMapAdHocs.setString("aString", "test");
    	_testMapAdHocs.setEnum("anEnum", MyEnum.ONE);
    	_testMapAdHocs.setLong("aLong", Long.MAX_VALUE);
    	_testMapAdHocs.setInt("anInt", Integer.MAX_VALUE);
    	_testMapAdHocs.setShort("aShort", Short.MAX_VALUE);
    	_testMapAdHocs.setTimestamp("aTimestamp", timeMillis);
    	_testMapAdHocs.setDate("aDate", date);
    	_testMapAdHocs.setTime("aTime", time);

    	_adHocs.put("foo", "bar");
	    _adHocs.put("pi", 3.1415926);
	    _adHocs.put("ha", 4);
	    _adHocs.put("haha", 'c');
	    _adHocs.put("boo", true);

	    _pingObjAdHocs.setAdHocs(_adHocs);
	    _testObjAdHocs.setAdHocs(_adHocs);
	    _pingMapAdHocs.setAdHocs(_adHocs);
	    _testMapAdHocs.setAdHocs(_adHocs);
    }

    protected Histogram _h = new Histogram(TimeUnit.SECONDS.toNanos(100), 3);
    protected StatsLogger _statsLogger = new StatsLogger(log);

    protected long _subsId;
    protected int _i;
    protected Obj _msg;

    protected PrestoClient _client;

    public PubSubBase(PrestoClient client, String channelType, String mediaDriverType) {
    	_client = client;
    	_channelType = channelType;
    	_mediaDriverType = mediaDriverType;
    }

	protected void recordLatency(Obj obj) throws Exception {
		long endNanoTime = System.nanoTime();
		long startNanoTime = getStartNanoTime(obj);
		if (startNanoTime>0) {
			long latency = endNanoTime - startNanoTime;
			try {
				_h.recordValue(latency);
			} catch (Exception x) {
				log.info("Error logging value " + latency, x);
			}
		}
	}

	private long getStartNanoTime(Obj obj) throws Exception {
		return (_useGenericGetters) ? obj.getLong("tsNanos") : obj.getTsNanos();
	}



    protected String getSql() {
    	if (_tstMsgType == TestMsgType.PING) {
    		switch (_selIn) {
    		case HEADER:
    			return _sqlPingSelInHeader;
    		case KEYS:
    			return _sqlPingSelInKeys;
    		case BODY:
    			return _sqlPingSelInBody;
    		default: // including NO
    			return _sqlPingNoSel;
    		}
    	} else {
    		switch (_selIn) {
    		case HEADER:
    			return _sqlTestSelInHeader;
    		case KEYS:
    			return _sqlTestSelInKeys;
    		case BODY:
    			return _sqlTestSelInBody;
    		default: // including NO
    			return _sqlTestNoSel;
    		}
    	}
    }

    protected Obj getObj() {
    	if (_tstMsgType == TestMsgType.PING) {
    		if (_useMapMsg) {
    			return (_useAdHocs) ? _pingMapAdHocs : _pingMap;
    		} else {
    			return (_useAdHocs) ? _pingObjAdHocs : _pingObj;
    		}
    	} else {
    		if (_useMapMsg) {
    			return (_useAdHocs) ? _testMapAdHocs : _testMap;
    		} else {
    			return (_useAdHocs) ? _testObjAdHocs : _testObj;
    		}
    	}
    }

	protected void setTestFields(int id, long startNanoTime) {
    	if (_tstMsgType == TestMsgType.PING) {
    		if (_useMapMsg) {
    			MapObj pingMap = (_useAdHocs) ? _pingMapAdHocs : _pingMap;
        		pingMap.setTsNanos(startNanoTime);
        		pingMap.setMine((short) id);
        		pingMap.setInt("id", id);
        		pingMap.setLong("payload", id);
    		} else {
    			PingObj pingObj = (_useAdHocs) ? _pingObjAdHocs : _pingObj;
        		pingObj.setTsNanos(startNanoTime);
        		pingObj.setMine((short) id);
        		pingObj.setId(id);
        		pingObj.setPayload(id);
    		}
    	} else {
    		if (_useMapMsg) {
    			MapObj testMap = (_useAdHocs) ? _testMapAdHocs : _testMap;
        		testMap.setTsNanos(startNanoTime);
        		testMap.setMine((short) id);
        		testMap.setInt("anInt", id);
        		testMap.setLong("aLong", id);
    		} else {
    			TestObj testObj = (_useAdHocs) ? _testObjAdHocs : _testObj;
        		testObj.setTsNanos(startNanoTime);
        		testObj.setMine((short) id);
        		testObj._anInt = id;
        		testObj._aLong = id;
    		}
    	}
	}



	@SuppressWarnings("unused")
	protected void logObj(Obj obj) {
		if (_i<0) {
			if (WUP_SIZE<=1000 && _i%200==0 || WUP_SIZE<=10) {
				log.info("onSubscriptionMessage "+obj);
			}
		} else {
			if (TST_SIZE<=1000 && _i%200==0 || TST_SIZE<=10) {
				log.info("onSubscriptionMessage "+obj);
			}
		}
	}




	public String configHeader() {
		return "host" + TAB + "chType" + TAB + "mdType" + TAB;
	}
	public String currentConfigValues() {
		return _localhost + TAB + _channelType + TAB + _mediaDriverType + TAB;
	}

	protected StatsTestsParams _statsTestsParams = new StatsTestsParams(
		new TestParams[] {
//			TestParams(msgType, useMapMsg, useGenericGetters, useAdHocs, selIn)

			// warmup
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.NO),
			new TestParams(TestMsgType.TEST, false, false, false, SelectorIn.NO),
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.NO),

			// tests
			new TestParams(TestMsgType.TEST, false, false, false, SelectorIn.NO),
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.NO),
			new TestParams(TestMsgType.TEST, true,  false, false, SelectorIn.NO),
			new TestParams(TestMsgType.PING, true,  false, false, SelectorIn.NO),
			new TestParams(TestMsgType.TEST, false, true,  false, SelectorIn.NO),
			new TestParams(TestMsgType.PING, false, true,  false, SelectorIn.NO),
			new TestParams(TestMsgType.TEST, false, false, true,  SelectorIn.NO),
			new TestParams(TestMsgType.PING, false, false, true,  SelectorIn.NO),
			new TestParams(TestMsgType.TEST, true,  false, true,  SelectorIn.NO),
			new TestParams(TestMsgType.PING, true,  false, true,  SelectorIn.NO),
			new TestParams(TestMsgType.TEST, false, true,  true,  SelectorIn.NO),
			new TestParams(TestMsgType.PING, false, true,  true,  SelectorIn.NO),

			new TestParams(TestMsgType.TEST, false, false, false, SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.HEADER),
			new TestParams(TestMsgType.TEST, true,  false, false, SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, true,  false, false, SelectorIn.HEADER),
			new TestParams(TestMsgType.TEST, false, true,  false, SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, false, true,  false, SelectorIn.HEADER),
			new TestParams(TestMsgType.TEST, false, false, true,  SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, false, false, true,  SelectorIn.HEADER),
			new TestParams(TestMsgType.TEST, true,  false, true,  SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, true,  false, true,  SelectorIn.HEADER),
			new TestParams(TestMsgType.TEST, false, true,  true,  SelectorIn.HEADER),
			new TestParams(TestMsgType.PING, false, true,  true,  SelectorIn.HEADER),

			new TestParams(TestMsgType.TEST, false, false, false, SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.KEYS),
			new TestParams(TestMsgType.TEST, true,  false, false, SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, true,  false, false, SelectorIn.KEYS),
			new TestParams(TestMsgType.TEST, false, true,  false, SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, false, true,  false, SelectorIn.KEYS),
			new TestParams(TestMsgType.TEST, false, false, true,  SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, false, false, true,  SelectorIn.KEYS),
			new TestParams(TestMsgType.TEST, true,  false, true,  SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, true,  false, true,  SelectorIn.KEYS),
			new TestParams(TestMsgType.TEST, false, true,  true,  SelectorIn.KEYS),
			new TestParams(TestMsgType.PING, false, true,  true,  SelectorIn.KEYS),

			new TestParams(TestMsgType.TEST, false, false, false, SelectorIn.BODY),
			new TestParams(TestMsgType.PING, false, false, false, SelectorIn.BODY),
			new TestParams(TestMsgType.TEST, true,  false, false, SelectorIn.BODY),
			new TestParams(TestMsgType.PING, true,  false, false, SelectorIn.BODY),
			new TestParams(TestMsgType.TEST, false, true,  false, SelectorIn.BODY),
			new TestParams(TestMsgType.PING, false, true,  false, SelectorIn.BODY),
			new TestParams(TestMsgType.TEST, false, false, true,  SelectorIn.BODY),
			new TestParams(TestMsgType.PING, false, false, true,  SelectorIn.BODY),
			new TestParams(TestMsgType.TEST, true,  false, true,  SelectorIn.BODY),
			new TestParams(TestMsgType.PING, true,  false, true,  SelectorIn.BODY),
			new TestParams(TestMsgType.TEST, false, true,  true,  SelectorIn.BODY),
			new TestParams(TestMsgType.PING, false, true,  true,  SelectorIn.BODY),
		}
	);



	private static class TestParams implements StatsTestParams {
	    TestMsgType _tstMsgType;
		boolean _useMapMsg;
		boolean _useGenericGetters; // only if _useMapMsg==false
	    boolean _useAdHocs;
		SelectorIn _selIn;

		TestParams(TestMsgType tstMsgType, boolean useMapMsg, boolean useGenericGetters, boolean useAdHocs, SelectorIn selIn) {
			_tstMsgType = tstMsgType;
			_useMapMsg = useMapMsg;
			_useGenericGetters = useGenericGetters;
			_useAdHocs = useAdHocs;
			_selIn = selIn;
		}

		public void updateTestParams() {
			PubSubBase._tstMsgType = _tstMsgType;
			PubSubBase._useMapMsg = _useMapMsg;
			PubSubBase._useGenericGetters = _useGenericGetters;
			PubSubBase._useAdHocs = _useAdHocs;
			PubSubBase._selIn = _selIn;
		}
		public String header() {
			return "msgType"+TAB+"mapMsg"+TAB+"genGet"+TAB+"adHocs"+TAB+"selIn"+TAB;
		}
		public String toString() {
			return _tstMsgType+TAB+_useMapMsg+TAB+_useGenericGetters+TAB+_useAdHocs+TAB+_selIn+TAB;
		}
	}
}
