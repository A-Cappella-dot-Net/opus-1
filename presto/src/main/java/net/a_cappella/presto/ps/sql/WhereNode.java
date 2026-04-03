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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.function.Predicate;

public abstract class WhereNode {
    private static final Logger log = LoggerFactory.getLogger(WhereNode.class);

    @FunctionalInterface
    public interface ThrowingPredicate<T> {
        boolean test(T t) throws Exception;
    }

    static <T> Predicate<T> predicateWrapper(ThrowingPredicate<T> throwingPredicate, WhereNode node) {
        return (T t) -> {
            try {
                return throwingPredicate.test(t);
            } catch (Exception ex) {
                log.warn("Error evaluating expression "+node+" => "+ex.getMessage());
                return false;
            }
        };
    }

    public abstract boolean satisfiesWhereClause(Obj obj);
    protected abstract boolean evalWhereClauseRequiresOnlyHeaderOrKeyFields(List<FieldMetaInfo> keys);
    protected abstract boolean evalWhereClauseRequiresOnlyHeaderFields();
    protected abstract void setMetaInfo(ObjMetaInfo metaInfo);

    private boolean _whereClauseRequiresOnlyHeaderFields = false;
    private boolean _whereClauseRequiresOnlyHeaderOrKeyFields = false;

    public boolean whereClauseRequiresOnlyHeaderFields() {
        return _whereClauseRequiresOnlyHeaderFields;
    }
    public boolean whereClauseRequiresOnlyHeaderOrKeyFields() {
        return _whereClauseRequiresOnlyHeaderOrKeyFields;
    }

    public void updateEvalSupportingFields(String subject, ObjMetaInfo metaInfo) {
        setMetaInfo(metaInfo);
        if (metaInfo!=null && metaInfo.getKeys()!=null) {
            _whereClauseRequiresOnlyHeaderOrKeyFields = evalWhereClauseRequiresOnlyHeaderOrKeyFields(metaInfo.getKeys());
        }
        _whereClauseRequiresOnlyHeaderFields = evalWhereClauseRequiresOnlyHeaderFields();
        log.debug("whereClauseRequiresOnly keys={} headers={} {} {}", _whereClauseRequiresOnlyHeaderOrKeyFields, _whereClauseRequiresOnlyHeaderFields, subject, this);
    }

    public abstract List<Object> getFilter(String fieldName);
}
