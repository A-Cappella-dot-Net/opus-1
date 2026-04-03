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

package net.a_cappella.presto.ps.sql;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

public class SqlParserTest {

    @Test
    public void testNoWhereClause() throws Exception {
        String sql = "select * from tab";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab}", res.toString());
    }

    @Test
    public void testExplicitColumn() throws Exception {
        String sql = "select a,* from tab";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[a, *] tab}", res.toString());
    }

    @Test
    public void testSimpleWhereClause() throws Exception {
        String sql = "select * from tab where key=value";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {key=[{string value}]}}", res.toString());
    }

    @Test
    public void testSpecialIdInWhereClause() throws Exception {
        String sql = "select * from tab where key.1=value";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {key.1=[{string value}]}}", res.toString());
    }

    @Test
    public void testNoParensWhereClause() throws Exception {
        String sql = "select * from tab where k1=v1 and k2=v2 or k3=v3";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {OR({AND({k1=[{string v1}]},{k2=[{string v2}]})},{k3=[{string v3}]})}}", res.toString());
    }

    @Test
    public void testRedundantParensWhereClause() throws Exception {
        String sql = "select * from tab where (k1=v1 and k2=v2) or k3=v3";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {OR({AND({k1=[{string v1}]},{k2=[{string v2}]})},{k3=[{string v3}]})}}", res.toString());
    }

    @Test
    public void testParensWhereClause() throws Exception {
        String sql = "select * from tab where k1=v1 and (k2=v2 or k3=v3)";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {AND({k1=[{string v1}]},{OR({k2=[{string v2}]},{k3=[{string v3}]})})}}", res.toString());
    }




    @Test
    public void testCharExpression() throws Exception {
        String sql = "select * from tab where k1='c'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{string c}]}}", res.toString());
    }

    @Test
    public void testStringInSingleQuotesExpression() throws Exception {
        String sql = "select * from tab where k1='foo bar'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{string foo bar}]}}", res.toString());
    }

    @Test
    public void testStringInDoubleQuotesExpression() throws Exception {
        String sql = "select * from tab where k1=\"foo bar\"";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{string foo bar}]}}", res.toString());
    }

    @Test
    public void testSingleQuotedStringContainingSingleQuote() throws Exception {
        String sql = "select * from tab where k1='foo''s bar'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{string foo's bar}]}}", res.toString());
    }

    @Test
    public void testDoubleQuotedStringContainingSingleQuote() throws Exception {
        String sql = "select * from tab where k1=\"foo's bar\"";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{string foo's bar}]}}", res.toString());
    }

    @Test
    public void testNumberExpression() throws Exception {
        String sql = "select * from tab where k1=12";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{number 12.0}]}}", res.toString());
    }

    @Test
    public void testNumberWExponentExpression() throws Exception {
        String sql = "select * from tab where k1=-.5E-5";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{number -5.0E-6}]}}", res.toString());
    }

    @Test
    public void testBoolExpression() throws Exception {
        String sql = "select * from tab where k1=true";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{boolean true}]}}", res.toString());
    }

    @Test
    public void testTimestampExpression() throws Exception {
        String sql = "select * from tab where k1='2016-03-06 14:58:31.423'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{timestamp 1457276311423}]}}", res.toString());
    }

    @Test
    public void testTimeExpression() throws Exception {
        String sql = "select * from tab where k1='14:58:31.423'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{time 145831423}]}}", res.toString());
    }

    @Test
    public void testDateExpression() throws Exception {
        String sql = "select * from tab where k1='2016-03-06'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{date 20160306}]}}", res.toString()); // does it depend on Time Zone?
    }

    @Test
    public void testInExpression() throws Exception {
        String sql = "select * from tab where k1 in ('2016-03-06', '2016-03-07')";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1 in [{date 20160306}, {date 20160307}]}}", res.toString());
    }

    @Test
    public void testInExpressionStrings() throws Exception {
        String sql = "select * from tab where k1 in ('ecn', '$ecn')";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1 in [{string ecn}, {string $ecn}]}}", res.toString());
    }

    @Test
    public void testNotInExpression() throws Exception {
        String sql = "select * from tab where k1 not in (ALPHA, BETA)";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1 not in [{string ALPHA}, {string BETA}]}}", res.toString());
    }

    @Test
    public void testIsNullExpression() throws Exception {
        String sql = "select * from tab where k1 is null";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1 is null}}", res.toString());
    }

    @Test
    public void testIsNotNullExpression() throws Exception {
        String sql = "select * from tab where k1 is not null";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1 is not null}}", res.toString());
    }

    @Test
    public void testBoolEqExpression() throws Exception {
        String sql = "select * from tab where k1=true";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1=[{boolean true}]}}", res.toString());
    }

    @Test
    public void testBoolNeExpression() throws Exception {
        String sql = "select * from tab where k1!=true";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1!=[{boolean true}]}}", res.toString());
    }

    @Test
    public void testNeExpression() throws Exception {
        String sql = "select * from tab where k1!=3";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1!=[{number 3.0}]}}", res.toString());
    }

    @Test
    public void testLtExpression() throws Exception {
        String sql = "select * from tab where k1<3.1415926";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1<[{number 3.1415926}]}}", res.toString());
    }

    @Test
    public void testLeExpression() throws Exception {
        String sql = "select * from tab where k1<=3.1415926";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1<=[{number 3.1415926}]}}", res.toString());
    }

    @Test
    public void testGtExpression() throws Exception {
        String sql = "select * from tab where k1>3.1415926";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1>[{number 3.1415926}]}}", res.toString());
    }

    @Test
    public void testGeExpression() throws Exception {
        String sql = "select * from tab where k1>=3.1415926";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {k1>=[{number 3.1415926}]}}", res.toString());
    }




    @Test
    public void testComplexExpression() throws Exception {
        String sql = "select * from tab where key1=val1 and key2<2 or key3!='y''s space' and d='2013-01-12'";
        SqlParserResult res = SqlParser.parseSql(sql);
        assertEquals("{[*] tab {AND({OR({AND({key1=[{string val1}]},{key2<[{number 2.0}]})},{key3!=[{string y's space}]})},{d=[{date 20130112}]})}}", res.toString());
    }

    @Test
    public void testParseError() {
        Exception exception = assertThrows(Exception.class, () -> {
            String sql = "select * from tab where k1=v1 k2=v2";
            SqlParser.parseSql(sql);
        });
        assertEquals("Malformed SQL: select * from tab where k1=v1>>> k2=v2", exception.getMessage());
    }
}
