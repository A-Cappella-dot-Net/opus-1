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
