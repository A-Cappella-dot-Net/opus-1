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
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;

import java.util.List;

public class WhereInternalNode extends WhereNode {
    private final SqlTokenEnum _op;
    private final WhereNode _leftChild;
    private final WhereNode _rightChild;

    public WhereInternalNode(SqlTokenEnum op, WhereNode leftChild, WhereNode rightChild) {
        _op = op;
        _leftChild = leftChild;
        _rightChild = rightChild;
    }

    public String toString() {
        return "{"+_op.name()+"("+_leftChild+","+_rightChild+")}";
    }

    @Override
    public boolean satisfiesWhereClause(Obj obj) {
        boolean leftChildTest = _leftChild.satisfiesWhereClause(obj);
        if (_op==SqlTokenEnum.AND) {
            if (!leftChildTest) return false;
            return _rightChild.satisfiesWhereClause(obj);
        } else if (_op==SqlTokenEnum.OR) {
            if (leftChildTest) return true;
            return _rightChild.satisfiesWhereClause(obj);
        }
        return false;
    }

    protected boolean evalWhereClauseRequiresOnlyHeaderOrKeyFields(List<FieldMetaInfo> keys) {
        return _leftChild.evalWhereClauseRequiresOnlyHeaderOrKeyFields(keys) && _rightChild.evalWhereClauseRequiresOnlyHeaderOrKeyFields(keys);
    }
    protected boolean evalWhereClauseRequiresOnlyHeaderFields() {
        return _leftChild.evalWhereClauseRequiresOnlyHeaderFields() && _rightChild.evalWhereClauseRequiresOnlyHeaderFields();
    }

    protected void setMetaInfo(ObjMetaInfo metaInfo) {
        _leftChild.setMetaInfo(metaInfo);
        _rightChild.setMetaInfo(metaInfo);
    }

    public List<Object> getFilter(String fieldName) {
        List<Object> filter = _leftChild.getFilter(fieldName);
        filter.addAll(_rightChild.getFilter(fieldName));
        return filter;
    }
}
