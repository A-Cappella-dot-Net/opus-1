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

public class SqlToken {
    protected SqlTokenEnum _type;
    protected String _sValue;
    protected double _nValue;
    protected long _tsValue;
    protected boolean _bValue;

    public SqlToken(SqlTokenEnum type) {
        if (type==SqlTokenEnum.TRUE) {
            _type = SqlTokenEnum.BOOLEAN;
            _bValue = true;
        } else if (type==SqlTokenEnum.FALSE) {
            _type = SqlTokenEnum.BOOLEAN;
            _bValue = false;
        } else {
            _type = type;
        }
    }

    public SqlToken(String str) {
        _type = SqlTokenEnum.STRING;
        _sValue = str;
    }

    public SqlToken(double nv) {
        _type = SqlTokenEnum.NUMBER;
        _nValue = nv;
    }

    public SqlToken(SqlTokenEnum type, long val) {
        _type = type;
        if (type==SqlTokenEnum.TIMESTAMP || type==SqlTokenEnum.TIME || type==SqlTokenEnum.DATE) {
            _tsValue = val;
        } else {
            _nValue = val;
        }
    }

    public SqlToken(SqlTokenEnum type, String value) {
        _type = type;
        _sValue = value;
    }

    public SqlTokenEnum getType() {
        return _type;
    }

    public String getString() {
        return _sValue;
    }

    public Object getValue() {
        if (_type == SqlTokenEnum.STRING) {
            return _sValue;
        } else if (_type == SqlTokenEnum.NUMBER) {
            return _nValue;
        } else if (_type == SqlTokenEnum.TIMESTAMP || _type == SqlTokenEnum.TIME || _type == SqlTokenEnum.DATE) {
            return _tsValue;
        } else if (_type == SqlTokenEnum.BOOLEAN) {
            return _bValue;
        }
        return null;
    }

    public String toString() {
        return "{" + _type + " " + getValue() + "}";
    }
}
