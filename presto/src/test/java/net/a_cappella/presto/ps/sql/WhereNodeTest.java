package net.a_cappella.presto.ps.sql;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.MyEnum;
import net.a_cappella.presto.obj.TestObj;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class WhereNodeTest {

    static Map<String, Object> _adHocs = new HashMap<>();
    static {
        _adHocs.put("foo", "bar");
        _adHocs.put("pi", 3.1415926);
        _adHocs.put("ha", 4);
        _adHocs.put("haha", 'H');
        _adHocs.put("boo", true);
        _adHocs.put("start", 1457276311423L);
        _adHocs.put("end", 145831423);
        _adHocs.put("day", 20160306);
    }

    static {
        try {
            MsgInstantiator testInstantiator = new MsgInstantiator(TestObj.class.getName());

            ObjectManager _objectManager = ObjectManager.getInstance();
            _objectManager.setMsgInstantiators(Arrays.asList(testInstantiator));
            _objectManager.setMsgPools(Arrays.asList(new Pool<Msg>(testInstantiator, 10, 10)));

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    @Test
    public void testCharEq() throws Exception {
        String sql = "select * from test where aChar='c'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());

        assertTrue(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {{aChar,CHAR}=[{string c}]}}", res.toString());

        Obj obj = new TestObj();
        obj.setChar("aChar", 'c');
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setChar("aChar", 'd');
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testCharNe() throws Exception {
        String sql = "select * from test where aChar!='c'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setChar("aChar", 'c');
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setChar("aChar", 'd');
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testShortEq() throws Exception {
        String sql = "select * from test where aShort=123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertTrue(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {{aShort,SHORT}=[{number 123.0}]}}", res.toString());

        Obj obj = new TestObj();
        obj.setShort("aShort", (short) 123);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setShort("aShort", (short) 124);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testShortLt() throws Exception {
        String sql = "select * from test where aShort<123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setShort("aShort", (short) 122);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setShort("aShort", (short) 123);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testIntLe() throws Exception {
        String sql = "select * from test where anInt<=123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertTrue(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {{anInt,INT}<=[{number 123.0}]}}", res.toString());

        Obj obj = new TestObj();
        obj.setInt("anInt", 122);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setInt("anInt", 123);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setInt("anInt", 124);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testIntGt() throws Exception {
        String sql = "select * from test where anInt>123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setInt("anInt", 123);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setInt("anInt", 124);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testTimestampLt() throws Exception {
        String sql = "select * from test where aTimestamp<'2016-03-06 14:58:31.423'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {{aTimestamp,TIMESTAMP}<[{timestamp 1457276311423}]}}", res.toString());

        Obj obj = new TestObj();
        obj.setTimestamp("aTimestamp", 1457276311422L);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setTimestamp("aTimestamp", 1457276311423L);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testTimestampGe() throws Exception {
        String sql = "select * from test where aTimestamp>='2016-03-06 14:58:31.423'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setTimestamp("aTimestamp", 1457276311422L);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setTimestamp("aTimestamp", 1457276311423L);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testDateLt() throws Exception {
        String sql = "select * from test where aDate<'2016-03-06'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setDate("aDate", 20160305);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setDate("aDate", 20160306);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testDateGt() throws Exception {
        String sql = "select * from test where aDate>'2016-03-06'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setDate("aDate", 20160307);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setDate("aDate", 20160306);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testBooleanEq() throws Exception {
        String sql = "select * from test where aBoolean=true";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setBoolean("aBoolean", true);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setBoolean("aBoolean", false);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testBooleanNe() throws Exception {
        String sql = "select * from test where aBoolean!=true";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setBoolean("aBoolean", true);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testEnumEq() throws Exception {
        String sql = "select * from test where anEnum=ONE";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setEnum("anEnum", MyEnum.ZERO);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testEnumNe() throws Exception {
        String sql = "select * from test where anEnum!=ONE";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        Obj obj = new TestObj();
        obj.setEnum("anEnum", MyEnum.ZERO);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testMineEq() throws Exception {
        String sql = "select * from test where mine=123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertTrue(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertTrue(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {{mine,SHORT}=[{number 123.0}]}}", res.toString());

        Obj obj = new TestObj();
        obj.setMine((short) 123);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 124);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocIsNull() throws Exception {
        String sql = "select * from test where alpha is null";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {alpha:{null,UNKNOWN} is null}}", res.toString());

        Obj obj = new TestObj();
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocIsNotNull() throws Exception {
        String sql = "select * from test where foo is not null";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {foo:{null,UNKNOWN} is not null}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }
    @Test
    public void testAdHocStringEq() throws Exception {
        String sql = "select * from test where foo='bar'";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {foo:{null,UNKNOWN}=[{string bar}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocCharLt() throws Exception {
        String sql = "select * from test where haha<'K'";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {haha:{null,UNKNOWN}<[{string K}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocBooleanEq() throws Exception {
        String sql = "select * from test where boo=true";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {boo:{null,UNKNOWN}=[{boolean true}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocDoubleEq() throws Exception {
        String sql = "select * from test where pi<4";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {pi:{null,UNKNOWN}<[{number 4.0}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocIntegerNe() throws Exception {
        String sql = "select * from test where ha!=3";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {ha:{null,UNKNOWN}!=[{number 3.0}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocTimestampEq() throws Exception {
        String sql = "select * from test where start='2016-03-06 14:58:31.423'";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {start:{null,UNKNOWN}=[{timestamp 1457276311423}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocTimeEq() throws Exception {
        String sql = "select * from test where end='14:58:31.423'";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {end:{null,UNKNOWN}=[{time 145831423}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAdHocDateGe() throws Exception {
        String sql = "select * from test where day>='2016-03-06'";

        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {day:{null,UNKNOWN}>=[{date 20160306}]}}", res.toString());

        Obj obj = new TestObj();
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setAdHocs(_adHocs);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }





    @Test
    public void testHeaderAndKey() throws Exception {
        String sql = "select * from test where mine=123 and aShort=123";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields()); // requires keys as well
        assertTrue(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {AND({{mine,SHORT}=[{number 123.0}]},{{aShort,SHORT}=[{number 123.0}]})}}", res.toString());

        Obj obj = new TestObj();
        obj.setMine((short) 123);
        obj.setShort("aShort", (short) 123);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 123);
        obj.setShort("aShort", (short) 124);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 124);
        obj.setShort("aShort", (short) 123);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 124);
        obj.setShort("aShort", (short) 124);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testHeaderAndKeyAndNonKey() throws Exception { // TODO
        String sql = "select * from test where mine=123 and aShort=123 and aFloat<10.5";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {AND({AND({{mine,SHORT}=[{number 123.0}]},{{aShort,SHORT}=[{number 123.0}]})},{{aFloat,FLOAT}<[{number 10.5}]})}}", res.toString());

        Obj obj = new TestObj();
        obj.setMine((short) 123);
        obj.setShort("aShort", (short) 123);
        obj.setFloat("aFloat", 10.0F);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 123);
        obj.setShort("aShort", (short) 124);
        obj.setFloat("aFloat", 10.0F);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 124);
        obj.setShort("aShort", (short) 123);
        obj.setFloat("aFloat", 10.0F);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setMine((short) 124);
        obj.setShort("aShort", (short) 124);
        obj.setFloat("aFloat", 10.0F);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAndAnd() throws Exception {
        String sql = "select * from test where anEnum=ONE and aString=STRING and aBoolean=false";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {AND({AND({{anEnum,ENUM}=[{string ONE}]},{{aString,STRING}=[{string STRING}]})},{{aBoolean,BOOLEAN}=[{boolean false}]})}}", res.toString());

        Obj obj = new TestObj();

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ZERO);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "string");
        obj.setBoolean("aBoolean", false);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", true);
        assertFalse(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAndOr() throws Exception {
        String sql = "select * from test where (anEnum=ONE and aString=STRING) or aBoolean=false";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {OR({AND({{anEnum,ENUM}=[{string ONE}]},{{aString,STRING}=[{string STRING}]})},{{aBoolean,BOOLEAN}=[{boolean false}]})}}", res.toString());

        Obj obj = new TestObj();

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ZERO);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "string");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", true);
        assertTrue(evalTree.satisfiesWhereClause(obj));
    }

    @Test
    public void testAndOrWithParens() throws Exception {
        String sql = "select * from test where anEnum=ONE and (aString=STRING or aBoolean=false)";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        WhereNode evalTree = res.getEvalTree();
        evalTree.updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        assertFalse(evalTree.whereClauseRequiresOnlyHeaderFields());
        assertFalse(evalTree.whereClauseRequiresOnlyHeaderOrKeyFields());
        assertEquals("{[*] test {AND({{anEnum,ENUM}=[{string ONE}]},{OR({{aString,STRING}=[{string STRING}]},{{aBoolean,BOOLEAN}=[{boolean false}]})})}}", res.toString());

        Obj obj = new TestObj();

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ZERO);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", false);
        assertFalse(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "string");
        obj.setBoolean("aBoolean", false);
        assertTrue(evalTree.satisfiesWhereClause(obj));

        obj.setEnum("anEnum", MyEnum.ONE);
        obj.setString("aString", "STRING");
        obj.setBoolean("aBoolean", true);
        assertTrue(evalTree.satisfiesWhereClause(obj));

//    	System.out.println(res);
    }
}
