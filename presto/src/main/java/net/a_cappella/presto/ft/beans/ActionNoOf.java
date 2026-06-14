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

package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.ft.constants.FtMsgOp;

public class ActionNoOf {
    public FtMsgOp _op;
    public int _stripeNo;
    public int _ofStripes;

    public ActionNoOf(FtMsgOp op, int stripeNo, int ofStripes) {
        _op = op;
        _stripeNo = stripeNo;
        _ofStripes = ofStripes;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + _ofStripes;
        result = prime * result + ((_op == null) ? 0 : _op.hashCode());
        result = prime * result + _stripeNo;
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null) return false;
        if (getClass() != obj.getClass()) return false;
        ActionNoOf other = (ActionNoOf) obj;
        if (_ofStripes != other._ofStripes) return false;
        if (_op != other._op) return false;
        if (_stripeNo != other._stripeNo) return false;
        return true;
    }

    @Override
    public String toString() {
        return "{"+_op+" "+ _stripeNo +"/"+ _ofStripes +"}";
    }

}
