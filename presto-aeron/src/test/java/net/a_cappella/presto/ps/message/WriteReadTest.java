package net.a_cappella.presto.ps.message;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.obj.*;
import net.a_cappella.presto.ps.AeronCoder;
import net.a_cappella.presto.ps.AeronObjCoder;
import net.a_cappella.presto.ps.SharedAeronCoders;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class WriteReadTest {
    private static final Logger log = LoggerFactory.getLogger(WriteReadTest.class);

    static {
        ObjImpl.setRtgCtor("net.a_cappella.presto.msg.RtgImpl");
        try {
            ObjectManager objectManager = ObjectManager.getInstance();
            objectManager.setMsgInstantiators(
                    Arrays.asList(
                            new MsgInstantiator(MapObj.class.getName(), MapCoder.class.getName(), null),
                            new MsgInstantiator(TestObj.class.getName(), TestCoder.class.getName(), null)
                    )
            );
        } catch (Exception e) {
            log.error("", e);
        }
    }

    private final Map<String, Object> _adHocs = new HashMap<>();
    {
        _adHocs.put("foo", "bar");
        _adHocs.put("pi", 3.1415926);
        _adHocs.put("ha", 4);
        _adHocs.put("haha", 'H');
        _adHocs.put("boo", true);
        _adHocs.put("enum", MyEnum.TWO);
    }

    private final AeronObjCoder _objCoder = new AeronObjCoder("myOriginClient");

    @Test
    public void writeReadObjTest() {
        long timeMillis = System.currentTimeMillis();

        TestObj tst = new TestObj();
        tst.setPubType(PubType.PUB);
        tst.setMine((short) 3);
        tst.setBackPressured(true);
        tst.setOnLoopback(false);

        tst.set(Short.MAX_VALUE, Integer.MIN_VALUE, Long.MIN_VALUE, 'c', "testy", timeMillis, System.nanoTime(), PTime.fromMillis(timeMillis), PDate.fromMillis(timeMillis), (float) Math.PI, Math.PI, true, MyEnum.ONE);
        tst.setAdHocs(_adHocs);

        SharedAeronCoders sharedCoders = _objCoder.encode(tst);
        log.info(">>> "+tst);

        AeronCoder cod = _objCoder.decodeHeader(sharedCoders.getBuffer(), 0, sharedCoders.getLen(), 0);
        _objCoder.acquireObj(cod);
        cod.decodeKeys();
        cod.decodeBody();
        cod.decodeAdHocs();

        Obj obj = cod.getObj();
        log.info("<<< "+obj);

        cod.setObj(null);

        assertEquals(tst, obj);
    }

    @Test
    public void writeReadTypedMapTest() {
        long timeMillis = System.currentTimeMillis();

        MapObj map = new MapObj();
        map.setPubType(PubType.PUB);

        map.setSubject(PrestoConstants.SUBJ_TEST);
        ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(map.getSubject());
        map.setObjMetaInfo(metaInfo);

        map.setBoolean("aBoolean", true);
        map.setChar("aChar", 'c');
        map.setDouble("aDouble", Math.PI);
        map.setFloat("aFloat", (float) Math.PI);
        map.setLong("aLong", Long.MAX_VALUE);
        map.setLong("aNanos", System.nanoTime());
        map.setInt("anInt", Integer.MIN_VALUE);
        map.setShort("aShort", Short.MAX_VALUE);
        map.setString("aString", "testy");
        map.setTimestamp("aTimestamp", timeMillis);
        map.setInt("aDate", PDate.fromMillis(timeMillis));
        map.setInt("aTime", PTime.fromMillis(timeMillis));
        map.setEnum("anEnum", MyEnum.ONE);

        map.setAdHocs(_adHocs);

        SharedAeronCoders sharedCoders = _objCoder.encode(map);
        log.info(">>> "+map);

        AeronCoder cod = _objCoder.decodeHeader(sharedCoders.getBuffer(), 0, sharedCoders.getLen(), 0);
        _objCoder.acquireObj(cod);
        cod.decodeKeys();
        cod.decodeBody();
        cod.decodeAdHocs();

        Obj obj = cod.getObj();
        log.info("<<< "+obj);

        cod.setObj(null);

        assertEquals(map, obj);
    }


    @Test
    public void writeReadUntypedMapTest() {
        long timeMillis = System.currentTimeMillis();

        MapObj map = new MapObj();
        map.setPubType(PubType.PUB);

        map.setSubject("foo");
        ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(map.getSubject());
        map.setObjMetaInfo(metaInfo);

        map.setBoolean("aBoolean", true);
        map.setChar("aChar", 'c');
        map.setDouble("aDouble", Math.PI);
        map.setFloat("aFloat", (float) Math.PI);
        map.setLong("aLong", Long.MAX_VALUE);
        map.setLong("aNanos", System.nanoTime());
        map.setInt("anInt", Integer.MIN_VALUE);
        map.setShort("aShort", Short.MAX_VALUE);
        map.setString("aString", "testy");
        map.setTimestamp("aTimestamp", timeMillis);
        map.setInt("aDate", PDate.fromMillis(timeMillis));
        map.setInt("aTime", PTime.fromMillis(timeMillis));
        map.setEnum("anEnum", MyEnum.ONE);

        map.setAdHocs(_adHocs);

        SharedAeronCoders sharedCoders = _objCoder.encode(map);
        log.info(">>> "+map);

        AeronCoder cod = _objCoder.decodeHeader(sharedCoders.getBuffer(), 0, sharedCoders.getLen(), 0);
        _objCoder.acquireObj(cod);
        cod.decodeKeys();
        cod.decodeBody();
        cod.decodeAdHocs();

        Obj obj = cod.getObj();
        log.info("<<< "+obj);

        cod.setObj(null);

        assertEquals(map, obj);
    }
}