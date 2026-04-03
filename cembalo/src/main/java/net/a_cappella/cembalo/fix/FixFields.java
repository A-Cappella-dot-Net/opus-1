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

import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_FIELDS;
import static net.a_cappella.cembalo.constants.ExchangeConstants.TYPE_FIX_REPEATING_GROUP;

import java.nio.ByteBuffer;
import java.util.Arrays;

import net.a_cappella.cembalo.generated.FixConstants;
import net.a_cappella.cembalo.generator.Dictionary;
import gnu.trove.map.TIntCharMap;
import gnu.trove.map.TIntDoubleMap;
import gnu.trove.map.TIntLongMap;
import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.hash.TIntCharHashMap;
import gnu.trove.map.hash.TIntDoubleHashMap;
import gnu.trove.map.hash.TIntLongHashMap;
import gnu.trove.map.hash.TIntObjectHashMap;
import gnu.trove.procedure.TIntCharProcedure;
import gnu.trove.procedure.TIntDoubleProcedure;
import gnu.trove.procedure.TIntLongProcedure;
import gnu.trove.procedure.TIntObjectProcedure;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.msg.Msg;

public class FixFields extends Msg {

    public TIntLongMap _intFields = new TIntLongHashMap();
    public TIntDoubleMap _floatFields = new TIntDoubleHashMap();
    public TIntCharMap _charFields = new TIntCharHashMap();
    public TIntObjectMap<String> _stringFields = new TIntObjectHashMap<>();
    public TIntObjectMap<FixRepeatingGroup> _repeatingGroups = new TIntObjectHashMap<>();

    private static Dictionary _dictionary = new Dictionary();
    public static void setDictionary(Dictionary dictionary) {
        _dictionary = dictionary;
        _orderIdTagOverride = (dictionary.isOrderIdTagTypeOverride()) ? FixConstants.Tag_OrderID : 0;
    }

    private static int _orderIdTagOverride;

    public FixFields() {}

    @Override
    public int getMsgType() {
        return TYPE_FIX_FIELDS;
    }

    private final EncodeField _encodeField = new EncodeField();
    private static class EncodeField implements TIntLongProcedure, TIntDoubleProcedure, TIntCharProcedure, TIntObjectProcedure<String> {
        private ByteBuffer _buffer;
        public void setBuffer(ByteBuffer buffer) {
            _buffer = buffer;
        }
        public boolean execute(int tag, long value) {
            if (tag != _orderIdTagOverride) {
                _buffer.putInt(tag);
                _buffer.putLong(value);
            }
            return true;
        }
        public boolean execute(int tag, double value) {
            _buffer.putInt(tag);
            _buffer.putDouble(value);
            return true;
        }
        public boolean execute(int tag, char value) {
            _buffer.putInt(tag);
            _buffer.putChar(value);
            return true;
        }
        public boolean execute(int tag, String value) {
            _buffer.putInt(tag);
            Msg.putString(_buffer, value);
            return true;
        }
    }

    private final EncodeRepeatingGroup _encodeRepeatingGroup = new EncodeRepeatingGroup();
    private static class EncodeRepeatingGroup implements TIntObjectProcedure<FixRepeatingGroup> {
        private ByteBuffer _buffer;
        public void setBuffer(ByteBuffer buffer) {
            _buffer = buffer;
        }
        public boolean execute(int tag, FixRepeatingGroup fixRepeatingGroup) {
            _buffer.putInt(tag);
            fixRepeatingGroup.encode(_buffer);
            return true;
        }
    }

    private final StopUsingRepeatingGroup _stopUsingRepeatingGroup = new StopUsingRepeatingGroup();
    private static class StopUsingRepeatingGroup implements TIntObjectProcedure<FixRepeatingGroup> {
        public boolean execute(int tag, FixRepeatingGroup fixRepeatingGroup) {
            fixRepeatingGroup.stopUsing();
            return true;
        }
    }

    @Override
    public void reset() {
        int groupSize = _repeatingGroups.size();
        if (groupSize>0) {
            _repeatingGroups.forEachEntry(_stopUsingRepeatingGroup);
        }

        _intFields.clear();
        _floatFields.clear();
        _charFields.clear();
        _stringFields.clear();
        _repeatingGroups.clear();
    }

    public void encode(ByteBuffer buffer) {
        int intSize = _intFields.size();
        int floatSize = _floatFields.size();
        int charSize = _charFields.size();
        int stringSize = _stringFields.size();
        if (intSize>0 || floatSize>0 || charSize>0 || stringSize>0) {
            _encodeField.setBuffer(buffer);
        }
        if (_orderIdTagOverride != 0 && _intFields.containsKey(_orderIdTagOverride)) {
            intSize--;
            stringSize++;
        }
        buffer.putInt(intSize);
        if (intSize>0) {
            _intFields.forEachEntry(_encodeField);
        }
        buffer.putInt(floatSize);
        if (floatSize>0) {
            _floatFields.forEachEntry(_encodeField);
        }
        buffer.putInt(charSize);
        if (charSize>0) {
            _charFields.forEachEntry(_encodeField);
        }
        buffer.putInt(stringSize);
        if (stringSize>0) {
            _stringFields.forEachEntry(_encodeField);
            if (_orderIdTagOverride != 0 && _intFields.containsKey(_orderIdTagOverride)) {
                buffer.putInt(_orderIdTagOverride);
                long orderID = _intFields.get(_orderIdTagOverride);
                Msg.encodeLongAsString(buffer, orderID);
            }
        }

        int groupSize = _repeatingGroups.size();
        buffer.putInt(groupSize);
        if (groupSize>0) {
            _encodeRepeatingGroup.setBuffer(buffer);
            _repeatingGroups.forEachEntry(_encodeRepeatingGroup);
        }
    }
    public FixFields decode(ByteBuffer buffer, int len) {
        int size = buffer.getInt();
        for (int i=0; i<size; i++) {
            int tag = buffer.getInt();
            long value = buffer.getLong();
            _intFields.put(tag, value);
        }
        size = buffer.getInt();
        for (int i=0; i<size; i++) {
            int tag = buffer.getInt();
            double value = buffer.getDouble();
            _floatFields.put(tag, value);
        }
        size = buffer.getInt();
        for (int i=0; i<size; i++) {
            int tag = buffer.getInt();
            char value = buffer.getChar();
            _charFields.put(tag, value);
        }
        size = buffer.getInt();
        for (int i=0; i<size; i++) {
            int tag = buffer.getInt();
            if (tag == _orderIdTagOverride) {
                long value = Msg.decodeLongFromString(buffer);
                _intFields.put(tag, value);
            } else {
                String value = (_dictionary.isInternable(tag)) ? Msg.getInternedString(buffer) : Msg.getString(buffer);
                _stringFields.put(tag, value);
            }
        }
        size = buffer.getInt();
        for (int i=0; i<size; i++) {
            try {
                int tag = buffer.getInt();
                FixRepeatingGroup fixRepeatingGroup = ObjectManager.getInstance().acquire(TYPE_FIX_REPEATING_GROUP);
                fixRepeatingGroup.decode(buffer, 0);
                _repeatingGroups.put(tag, fixRepeatingGroup);
            } catch (Exception x) {
                x.printStackTrace();
            }
        }

        return this;
    }

    public long getInt(int tag) {
        return _intFields.get(tag);
    }
    public void putInt(int tag, long value) {
        _intFields.put(tag, value);
    }
    public double getFloat(int tag) {
        return _floatFields.get(tag);
    }
    public void putFloat(int tag, double value) {
        _floatFields.put(tag, value);
    }
    public char getChar(int tag) {
        return _charFields.get(tag);
    }
    public void putChar(int tag, char value) {
        _charFields.put(tag, value);
    }
    public String getString(int tag) {
        return _stringFields.get(tag);
    }
    public void putString(int tag, String value) {
        _stringFields.put(tag, value);
    }

    public String toString() {
        String[] strs = new String[4];
        strs[0] = (_intFields.isEmpty())?null:_intFields.toString();
        strs[1] = (_floatFields.isEmpty())?null:_floatFields.toString();
        strs[2] = (_charFields.isEmpty())?null:_charFields.toString();
        strs[3] = (_stringFields.isEmpty())?null:_stringFields.toString();
        String str = null;
        for (int i=0; i<4; i++) {
            if (strs[i]!=null) {
                if (str==null ) {
                    str = strs[i];
                } else {
                    str += " "+strs[i];
                }
            }
        }
        String grp = _repeatingGroups.isEmpty()?null:Arrays.toString(_repeatingGroups.values());
        if (str==null && grp==null) return "";
        if (str==null) return grp;
        if (grp==null) return str;
        return str+" "+grp;
    }

    private final ToStringField _toStringField = new ToStringField();
    private static class ToStringField implements TIntLongProcedure, TIntDoubleProcedure, TIntCharProcedure, TIntObjectProcedure<String> {
        private StringBuilder _sb;
        public void setBuilder(StringBuilder sb) {
            _sb = sb;
        }

        public boolean execute(int tag, long value) {
            if (tag != _orderIdTagOverride) {
                _sb.append(tag).append('=').append(value).append(FixMessage.SOH);
            }
            return true;
        }
        public boolean execute(int tag, double value) {
            if (!Double.isNaN(value)) _sb.append(tag).append('=').append(value).append(FixMessage.SOH);
            return true;
        }
        public boolean execute(int tag, char value) {
            _sb.append(tag).append('=').append(value).append(FixMessage.SOH);
            return true;
        }
        public boolean execute(int tag, String value) {
            _sb.append(tag).append('=').append(value).append(FixMessage.SOH);
            return true;
        }
    }

    private final ToStringRepeatingGroup _toStringRepeatingGroup = new ToStringRepeatingGroup();
    private static class ToStringRepeatingGroup implements TIntObjectProcedure<FixRepeatingGroup> {
        private StringBuilder _sb;
        public void setBuilder(StringBuilder sb) {
            _sb = sb;
        }

        public boolean execute(int tag, FixRepeatingGroup fixRepeatingGroup) {
            fixRepeatingGroup.toString(_sb);
            return true;
        }
    }

    public void toString(StringBuilder sb) {
        _toStringField.setBuilder(sb);

        int intSize = _intFields.size();
        int floatSize = _floatFields.size();
        int charSize = _charFields.size();
        int stringSize = _stringFields.size();
        if (intSize>0) {
            _intFields.forEachEntry(_toStringField);
        }
        if (floatSize>0) {
            _floatFields.forEachEntry(_toStringField);
        }
        if (charSize>0) {
            _charFields.forEachEntry(_toStringField);
        }
        if (stringSize>0) {
            _stringFields.forEachEntry(_toStringField);
        }

        int groupSize = _repeatingGroups.size();
        if (groupSize>0) {
            _toStringRepeatingGroup.setBuilder(sb);
            _repeatingGroups.forEachEntry(_toStringRepeatingGroup);
        }
    }
}
