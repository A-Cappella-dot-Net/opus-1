package net.a_cappella.presto.obj;

import gnu.trove.procedure.TObjectCharProcedure;
import gnu.trove.procedure.TObjectDoubleProcedure;
import gnu.trove.procedure.TObjectLongProcedure;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.utils.Utils;
import org.agrona.DirectBuffer;
import org.agrona.MutableDirectBuffer;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import sbe.generated.CombinedSbePrestoHeaderEncoder;
import sbe.generated.MapObjDecoder;
import sbe.generated.MapObjEncoder;

import java.util.List;
import java.util.Map;

import static org.agrona.BitUtil.*;

public class MapCoder extends AeronCoderImpl<MapObj> {
    private static final Logger log = LoggerFactory.getLogger(MapCoder.class);

    private final MapObjEncoder ENCODER = new MapObjEncoder();
    private static final MapObjDecoder DECODER = new MapObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    private int position = 0; // temporary to pass info from keys to body methods

    public MapCoder() {
    }

    @Override
    public void encodeKeys() {
        int len = 0;
        position = CombinedSbePrestoHeaderEncoder.ENCODED_LENGTH + encodedLength();
        if (_obj.getObjMetaInfo() != null) {
            len = writeList(encoderBuffer(), position, _obj.getObjMetaInfo().getKeys());
        }
        position += len;
    }
    @Override
    public void encodeBody() {
        int len;
        int limit;
        if (_obj.getObjMetaInfo() == null) {
            len = writeMap(encoderBuffer(), position);
        } else {
            len = writeList(encoderBuffer(), position, _obj.getObjMetaInfo().getNonKeys());
        }
        limit = position + len;
        ENCODER.limit(limit);
    }

    private int writeList(MutableDirectBuffer out, int offset, List<FieldMetaInfo> list) {
        int index = offset;
        for (int i=0; i<list.size(); i++) {
            FieldMetaInfo fmi = list.get(i);
            String fieldName = fmi.getName();
            FieldType fieldType = fmi.getType();
            try {
                if (fieldType==FieldType.SHORT) {
                    out.putShort(index, _obj.getShort(fieldName)); index += SIZE_OF_SHORT;
                } else if (fieldType==FieldType.INT) {
                    out.putInt(index, _obj.getInt(fieldName)); index += SIZE_OF_INT;
                } else if (fieldType==FieldType.LONG) {
                    out.putLong(index, _obj.getLong(fieldName)); index += SIZE_OF_LONG;
                } else if (fieldType==FieldType.FLOAT) {
                    out.putFloat(index, _obj.getFloat(fieldName)); index += SIZE_OF_FLOAT;
                } else if (fieldType==FieldType.DOUBLE) {
                    out.putDouble(index, _obj.getDouble(fieldName)); index += SIZE_OF_DOUBLE;
                } else if (fieldType==FieldType.BOOLEAN) {
                    out.putShort(index, _obj.getBoolean(fieldName) ? (short)1 : (short)0); index += SIZE_OF_SHORT;
                } else if (fieldType==FieldType.TIMESTAMP) {
                    out.putLong(index, _obj.getTimestamp(fieldName)); index += SIZE_OF_LONG;
                } else if (fieldType==FieldType.NANOS) {
                    out.putLong(index, _obj.getNanos(fieldName)); index += SIZE_OF_LONG;
                } else if (fieldType==FieldType.TIME) {
                    out.putInt(index, _obj.getTime(fieldName)); index += SIZE_OF_INT;
                } else if (fieldType==FieldType.DATE) {
                    out.putInt(index, _obj.getDate(fieldName)); index += SIZE_OF_INT;
                } else if (fieldType==FieldType.CHAR) {
                    out.putChar(index, _obj.getChar(fieldName)); index += SIZE_OF_CHAR;
                } else if (fieldType==FieldType.STRING) {
                    index += out.putStringAscii(index, _obj.getString(fieldName));
                } else if (fieldType==FieldType.ENUM) {
                    Enum<?> enumVal = _obj.getEnum(fieldName);
                    index += out.putStringAscii(index,  enumVal.getClass().getName());
                    index += out.putStringAscii(index,  enumVal.name());
                }
            } catch (Exception e) {
                log.error("", e);
            }
        }
        return index - offset;
    }

    public static class EnCoder implements TObjectLongProcedure<String>, TObjectDoubleProcedure<String>, TObjectCharProcedure<String> {
        private MutableDirectBuffer _out;
        private int _index;

        public void setOut(MutableDirectBuffer out) {
            _out = out;
        }
        public void setIndex(int index) {
            _index = index;
        }
        public int getIndex() {
            return _index;
        }

        @Override
        public boolean execute(String key, long value) {
            _index += _out.putStringAscii(_index, key);
            _out.putLong(_index, value); _index += SIZE_OF_LONG;
            return true;
        }
        @Override
        public boolean execute(String key, double value) {
            _index += _out.putStringAscii(_index, key);
            _out.putDouble(_index, value); _index += SIZE_OF_DOUBLE;
            return true;
        }
        @Override
        public boolean execute(String key, char value) {
            _index += _out.putStringAscii(_index, key);
            _out.putChar(_index, value); _index += SIZE_OF_CHAR;
            return true;
        }
    }

    private final EnCoder _enCoder = new EnCoder();

    private int writeMap(MutableDirectBuffer out, int offset) {
        int index = offset;

        _enCoder.setOut(out);
        MapObj map = (MapObj) _obj;

        short count = (short) ((map._longMap == null) ? 0 : map._longMap.size());
        out.putShort(index, count); index += SIZE_OF_SHORT;
        if (count>0) {
            _enCoder.setIndex(index);
            map._longMap.forEachEntry(_enCoder);
            index = _enCoder.getIndex();
        }
        count = (short) ((map._doubleMap == null) ? 0 : map._doubleMap.size());
        out.putShort(index, count); index += SIZE_OF_SHORT;
        if (count>0) {
            _enCoder.setIndex(index);
            map._doubleMap.forEachEntry(_enCoder);
            index = _enCoder.getIndex();
        }
        count = (short) ((map._charMap == null) ? 0 : map._charMap.size());
        out.putShort(index, count); index += SIZE_OF_SHORT;
        if (count>0) {
            _enCoder.setIndex(index);
            map._charMap.forEachEntry(_enCoder);
            index = _enCoder.getIndex();
        }

        count = (short) ((map._stringMap == null) ? 0 : map._stringMap.size());
        out.putShort(index, count); index += SIZE_OF_SHORT;
        if (count>0) {
            for (Map.Entry<String, String> e : map._stringMap.entrySet()) {
                index += out.putStringAscii(index, e.getKey());
                index += out.putStringAscii(index, e.getValue());
            }
        }

        count = (short) ((map._enumMap == null) ? 0 : map._enumMap.size());
        out.putShort(index, count); index += SIZE_OF_SHORT;
        if (count>0) {
            for (Map.Entry<String, Enum<?>> e : map._enumMap.entrySet()) {
                index += out.putStringAscii(index, e.getKey());
                Enum<?> enumVal = e.getValue();
                index += out.putStringAscii(index, enumVal.getClass().getName());
                index += out.putStringAscii(index, enumVal.name());
            }
        }

        return index - offset;
    }

    @Override
    public void decodeKeys() {
        int len = 0;
        position = DECODER.offset() + DECODER.encodedLength();
        if (_obj.getObjMetaInfo() != null) {
            len = readList(decoderBuffer(), position, _obj.getObjMetaInfo().getKeys());
        }
        position += len;
    }
    @Override
    public void decodeBody() {
        int len;
        if (_obj.getObjMetaInfo() == null) {
            len = readMap(decoderBuffer(), position);
        } else {
            len = readList(decoderBuffer(), position, _obj.getObjMetaInfo().getNonKeys());
        }
        position += len;
        DECODER.limit(position);
    }
    private int readList(DirectBuffer in, int offset, List<FieldMetaInfo> list) {
        int index = offset;
        StringBuilder sb = null;
        for (int i=0; i<list.size(); i++) {
            FieldMetaInfo fmi = list.get(i);
            String fieldName = fmi.getName();
            FieldType fieldType = fmi.getType();
            if (fieldType==FieldType.SHORT) {
                short val = in.getShort(index); index += SIZE_OF_SHORT;
                _obj.setShort(fieldName, val);
            } else if (fieldType==FieldType.INT) {
                int val = in.getInt(index); index += SIZE_OF_INT;
                _obj.setInt(fieldName, val);
            } else if (fieldType==FieldType.LONG) {
                long val = in.getLong(index); index += SIZE_OF_LONG;
                _obj.setLong(fieldName, val);
            } else if (fieldType==FieldType.FLOAT) {
                float val = in.getFloat(index); index += SIZE_OF_FLOAT;
                _obj.setFloat(fieldName, val);
            } else if (fieldType==FieldType.DOUBLE) {
                double val = in.getDouble(index); index += SIZE_OF_DOUBLE;
                _obj.setDouble(fieldName, val);
            } else if (fieldType==FieldType.BOOLEAN) {
                boolean val = in.getShort(index) == (short)1; index += SIZE_OF_SHORT;
                _obj.setBoolean(fieldName, val);
            } else if (fieldType==FieldType.TIMESTAMP) {
                long val = in.getLong(index); index += SIZE_OF_LONG;
                _obj.setTimestamp(fieldName, val);
            } else if (fieldType==FieldType.NANOS) {
                long val = in.getLong(index); index += SIZE_OF_LONG;
                _obj.setNanos(fieldName, val);
            } else if (fieldType==FieldType.TIME) {
                int val = in.getInt(index); index += SIZE_OF_INT;
                _obj.setTime(fieldName, val);
            } else if (fieldType==FieldType.DATE) {
                int val = in.getInt(index); index += SIZE_OF_INT;
                _obj.setDate(fieldName, val);
            } else if (fieldType==FieldType.CHAR) {
                char val = in.getChar(index); index += SIZE_OF_CHAR;
                _obj.setChar(fieldName, val);
            } else if (fieldType==FieldType.STRING) {
                String val = in.getStringAscii(index); index += val.length() + SIZE_OF_INT;
                _obj.setString(fieldName, val);
            } else if (fieldType==FieldType.ENUM) { // TODO intern
                if (sb==null) sb = Utils.getThreadLocalStringBuilder();

                sb.setLength(0);
                in.getStringAscii(index, sb);
                String enumClass = Utils.intern(sb); index += enumClass.length() + SIZE_OF_INT;
                sb.setLength(0);
                in.getStringAscii(index, sb);
                String enumVal = Utils.intern(sb); index += enumVal.length() + SIZE_OF_INT;
                try {
                    Enum<?> val = Enum.valueOf((Class<Enum>) Class.forName(enumClass), enumVal);
                    _obj.setEnum(fieldName, val);
                } catch (ClassNotFoundException e) {
                    log.error("", e);
                }
            }
        }
        return index - offset;
    }

    private int readMap(DirectBuffer in, int offset) {
        int index = offset;
        MapObj map = (MapObj) _obj;
        StringBuilder sb = Utils.getThreadLocalStringBuilder();

        short count = in.getShort(index); index += SIZE_OF_SHORT;
        if (count>0) map.initLongMap(count);
        for (int i=0; i<count; i++) {
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String key = Utils.intern(sb); index += key.length() + SIZE_OF_INT;
            long val = in.getLong(index); index += SIZE_OF_LONG;
            map._longMap.put(key, val);
        }
        count = in.getShort(index); index += SIZE_OF_SHORT;
        if (count>0) map.initDoubleMap(count);
        for (int i=0; i<count; i++) {
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String key = Utils.intern(sb); index += key.length() + SIZE_OF_INT;
            double val = in.getDouble(index); index += SIZE_OF_DOUBLE;
            map._doubleMap.put(key, val);
        }
        count = in.getShort(index); index += SIZE_OF_SHORT;
        if (count>0) map.initCharMap(count);
        for (int i=0; i<count; i++) {
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String key = Utils.intern(sb); index += key.length() + SIZE_OF_INT;
            char val = in.getChar(index); index += SIZE_OF_CHAR;
            map._charMap.put(key, val);
        }
        count = in.getShort(index); index += SIZE_OF_SHORT;
        if (count>0) map.initStringMap(count);
        for (int i=0; i<count; i++) {
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String key = Utils.intern(sb); index += key.length() + SIZE_OF_INT;
            String val = in.getStringAscii(index); index += val.length() + SIZE_OF_INT;
            map._stringMap.put(key, val);
        }
        count = in.getShort(index); index += SIZE_OF_SHORT;
        if (count>0) map.initEnumMap(count);
        for (int i=0; i<count; i++) {
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String key = Utils.intern(sb); index += key.length() + SIZE_OF_INT;
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String enumClass = Utils.intern(sb); index += enumClass.length() + SIZE_OF_INT;
            sb.setLength(0);
            in.getStringAscii(index, sb);
            String enumVal = Utils.intern(sb); index += enumVal.length() + SIZE_OF_INT;
            try {
                Enum<?> val = Enum.valueOf((Class<Enum>) Class.forName(enumClass), enumVal);
                map._enumMap.put(key, val);
            } catch (ClassNotFoundException e) {
                log.error("", e);
            }
        }

        return index - offset;
    }
}
