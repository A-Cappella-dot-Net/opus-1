package net.a_cappella.presto.managed;

import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.obj.MapCoder;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.obj.TestCoder;
import net.a_cappella.presto.obj.TestObj;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class MsgInstantiatorTest {

    @Test
    public void mapTest() throws Exception {
        MsgInstantiator instantiator = new MsgInstantiator(MapObj.class.getName(), MapCoder.class.getName(), null);
        assertTrue(instantiator.allGood());
        assertEquals(PrestoConstants.TYPE_MAP, instantiator.getObjType());
        MapObj obj = instantiator.newInstance();
        assertTrue(obj.getCoderConstructor().equals(MapCoder.class.getConstructor()));
        assertNull(obj.getObjMetaInfo());
    }

    @Test
    public void testTest() throws Exception {
        MsgInstantiator instantiator = new MsgInstantiator(TestObj.class.getName(), TestCoder.class.getName(), null);
        assertTrue(instantiator.allGood());
        assertEquals(PrestoConstants.TYPE_TEST, instantiator.getObjType());

        TestObj obj = instantiator.newInstance();
        assertTrue(obj.getCoderConstructor().equals(TestCoder.class.getConstructor()));

        ObjMetaInfo objMetaInfo = obj.getObjMetaInfo();
        assertEquals(PrestoConstants.TYPE_TEST, objMetaInfo.getObjType());

        List<FieldMetaInfo> keys = objMetaInfo.getKeys();
        assertEquals("[{aShort,SHORT}, {anInt,INT}, {aChar,CHAR}]", keys.toString());
        assertEquals("short", keys.get(0).getField().getGenericType().getTypeName());
        assertEquals("int",   keys.get(1).getField().getGenericType().getTypeName());
        assertEquals("char",  keys.get(2).getField().getGenericType().getTypeName());

        List<FieldMetaInfo> nonKeys = objMetaInfo.getNonKeys();
        assertEquals("[{aBoolean,BOOLEAN}, {aLong,LONG}, {aFloat,FLOAT}, {aDouble,DOUBLE}, {aString,STRING}, {anEnum,ENUM}, {aTimestamp,TIMESTAMP}, {aNanos,NANOS}, {aTime,TIME}, {aDate,DATE}]", nonKeys.toString());
        assertEquals("boolean",                  nonKeys.get(0).getField().getGenericType().getTypeName());
        assertEquals("long",                     nonKeys.get(1).getField().getGenericType().getTypeName());
        assertEquals("float",                    nonKeys.get(2).getField().getGenericType().getTypeName());
        assertEquals("double",                   nonKeys.get(3).getField().getGenericType().getTypeName());
        assertEquals("java.lang.String",         nonKeys.get(4).getField().getGenericType().getTypeName());
        assertEquals("net.a_cappella.presto.obj.MyEnum", nonKeys.get(5).getField().getGenericType().getTypeName());
        assertEquals("long",                     nonKeys.get(6).getField().getGenericType().getTypeName());
        assertEquals("long",                     nonKeys.get(7).getField().getGenericType().getTypeName());
        assertEquals("int",                      nonKeys.get(8).getField().getGenericType().getTypeName());
        assertEquals("int",                      nonKeys.get(9).getField().getGenericType().getTypeName());
    }

    @Test
    public void noGood1Test() {
        MsgInstantiator instantiator = new MsgInstantiator(MapObj.class.getName(), "presto.obj.Foo", null);
        assertFalse(instantiator.allGood());
    }

    @Test
    public void noGood2Test() {
        MsgInstantiator instantiator = new MsgInstantiator("presto.obj.Foo", MapCoder.class.getName(), null);
        assertFalse(instantiator.allGood());
    }

}
