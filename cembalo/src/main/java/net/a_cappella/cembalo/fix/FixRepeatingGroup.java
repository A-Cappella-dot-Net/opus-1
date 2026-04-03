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

package net.a_cappella.cembalo.fix;

import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.Msg;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_FIELDS;
import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_REPEATING_GROUP;

public class FixRepeatingGroup extends Msg {
    public int _tag;
    public int _numElements;
    public List<FixFields> _elements = new ArrayList<>();

    public FixRepeatingGroup() {}

    @Override
    public int getMsgType() {
        return TYPE_FIX_REPEATING_GROUP;
    }

    public void encode(ByteBuffer buffer) {
        buffer.putInt(_tag);
        buffer.putInt(_numElements);
        for (int i=0; i<_numElements; i++) {
            FixFields fixFields = _elements.get(i);
            fixFields.encode(buffer);
        }
    }
    public FixRepeatingGroup decode(ByteBuffer buffer, int len) {
        _tag = buffer.getInt();
        _numElements = buffer.getInt();
        for (int i=0; i<_numElements; i++) {
            try {
                FixFields fixFields = ObjectManager.getInstance().acquire(TYPE_FIX_FIELDS);
                fixFields.decode(buffer, len);
                _elements.add(fixFields);
            } catch (Exception x) {
                x.printStackTrace();
            }
        }

        return this;
    }

    public void toString(StringBuilder sb) {
        sb.append(_tag).append('=').append(_numElements).append(FixMessage.SOH);
        for (int i=0; i<_numElements; i++) {
            FixFields element = _elements.get(i);
            element.toString(sb);
        }
    }



    @Override
    public void reset() {
        for (int i=0; i<_numElements; i++) {
            FixFields fields = _elements.get(i);
            fields.stopUsing();
        }

        _numElements = 0;
        _elements.clear();
    }
}
