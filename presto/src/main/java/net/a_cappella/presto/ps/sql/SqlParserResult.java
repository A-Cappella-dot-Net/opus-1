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

import net.a_cappella.continuo.obj.Obj;

import java.util.List;

public class SqlParserResult {
    private final String _sql; // original sql
    private final List<String> _selectFields;
    private final String _fromTable;
    private final WhereNode _evalTree;

    public SqlParserResult(String sql, List<String> selectFields, String fromTable, WhereNode rootWhereNode) {
        _sql = sql;
        _selectFields = selectFields;
        _fromTable = fromTable;
        _evalTree = rootWhereNode;
    }

    public SqlParserResult(Obj obj) {
        _sql = _fromTable = obj.getSubject();
        _selectFields = null;
        _evalTree = null;
    }

    public String getSql() {
        return _sql;
    }
    public List<String> getSelectFields() {
        return _selectFields;
    }
    public String getFromTable() {
        return _fromTable;
    }
    public WhereNode getEvalTree() {
        return _evalTree;
    }

    public String toString() {
        return "{"+_selectFields+" "+_fromTable+((_evalTree==null)?"":(" "+_evalTree))+"}";
    }
}
