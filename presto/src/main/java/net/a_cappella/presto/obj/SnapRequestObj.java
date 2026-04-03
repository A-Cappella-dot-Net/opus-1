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

package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.PubType;

import java.lang.reflect.Constructor;

public class SnapRequestObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_SNP; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_SNP; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) {
        _codCtor = codCtor;
    }

    private static Constructor<? extends Coder> _codCtor;
    @Override
    public Constructor<? extends Coder> getCoderConstructor() {
        return _codCtor;
    }

    @Override
    public ObjPriority getPriority() {
        return ObjPriority.REG_PRI;
    }

    public SnapRequestObj() {
        _pubType = PubType.SNP;
    }

    private String _sql;

    @Override // IPoolable
    public void reset() {
        super.reset();
        _sql = null;
    }

    public void set(String subject, String sql, long requestId) {
        _pubType = PubType.SNP;
        _subject = subject;
        _sql = sql;
        _requestId = requestId;
    }

    public String getSql() {
        return _sql;
    }

    public void setSql(String sql) {
        _sql = sql;
    }

    public String toString() {
        return super.toString()+" sql=<"+_sql+">";
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("sql".equalsIgnoreCase(fieldName)) return _sql;
        return super.getString(fieldName); // throws exception
    }
}
