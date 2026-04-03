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

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.TypeMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.presto.ps.AeronCoder;
import org.agrona.DirectBuffer;
import org.agrona.MutableDirectBuffer;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import sbe.generated.CombinedSbePrestoHeaderDecoder;
import sbe.generated.CombinedSbePrestoHeaderEncoder;
import sbe.generated.SbeBoolean;
import sbe.generated.SbePubType;

import java.util.Map;

import static org.agrona.BitUtil.*;


public abstract class AeronCoderImpl <T extends Obj> implements AeronCoder {
    private static final Logger log = LoggerFactory.getLogger(AeronCoderImpl.class);

    protected final CombinedSbePrestoHeaderEncoder HEADER_ENCODER = new CombinedSbePrestoHeaderEncoder();

    public AeronCoderImpl() {
    }

    protected T _obj;

    @Override
    public Obj getObj() {
        return _obj;
    }

    @SuppressWarnings("unchecked")
    @Override
    public void setObj(Obj obj) {
        _obj = (T) obj;
    }

    public DirectBuffer decoderBuffer() {
        return getDecoder().buffer();
    }

    public MutableDirectBuffer encoderBuffer() {
        return getEncoder().buffer();
    }

    public int encodedLength() {
        return getEncoder().encodedLength();
    }

    private int _objType;
    private String _subject;
    private PubType _pubType;
    private long _requestId;
    private String _originClient;
    private short _mine;
    private long _tsNanos;
    private long _serialId;
    private long _seqNo;
    private boolean _backPressured;
    private boolean _onLoopback;
    private int _version;

    public void setObjType(int objType) {
        _objType = objType;
    }

    public int getObjType() {
        return _objType;
    }

    public int getVersion() {
        return _version;
    }

    public String getSubject() {
        return _subject;
    }

    public PubType getPubType() {
        return _pubType;
    }

    public long getRequestId() {
        return _requestId;
    }

    public String getOriginClient() {
        return _originClient;
    }

    public short getMine() {
        return _mine;
    }

    public long getTsNanos() {
        return _tsNanos;
    }

    public long getSerialId() {
        return _serialId;
    }

    public long getSeqNo() {
        return _seqNo;
    }

    public boolean isBackPressured() {
        return _backPressured;
    }

    public boolean isOnLoopback() {
        return _onLoopback;
    }

    public int encodeObj(final MutableDirectBuffer directBuffer, int offset) {
        String originClient = _obj.getRtg().getOriginClient();
        MessageEncoderFlyweight encoder = getEncoder();
        HEADER_ENCODER
                // SBE Header
                .wrap(directBuffer, offset)
                .blockLength(CombinedSbePrestoHeaderEncoder.ENCODED_LENGTH)
                .templateId(encoder.sbeTemplateId())
                .schemaId(encoder.sbeSchemaId())
                .version(encoder.sbeSchemaVersion())
                // Presto Header
                .subject(_obj.getSubject())
                .backPressured(_obj.isBackPressured() ? SbeBoolean.TRUE : SbeBoolean.FALSE)
                .onLoopback(_obj.isOnLoopback() ? SbeBoolean.TRUE : SbeBoolean.FALSE)
                .pubType(convert(_obj.getPubType()))
                .requestId(_obj.getRequestId())
                .originClient(originClient == null ? "" : originClient)
                .mine(_obj.getMine())
                .tsNanos(_obj.getTsNanos())
                .serialId(_obj.getSerialId())
                .seqNo(_obj.getSeqNo())
        ;

        encoder.wrap(directBuffer, offset + CombinedSbePrestoHeaderEncoder.ENCODED_LENGTH);
        encodeKeys();
        encodeBody();
        int adHocsLen = encodeAdHocs();

        int len = CombinedSbePrestoHeaderEncoder.ENCODED_LENGTH + encodedLength() + adHocsLen;

        if (log.isDebugEnabled()) log.error(net.a_cappella.presto.ps.Utils.hexDump(directBuffer, offset, len));

        return len;
    }

    public int encodeAdHocs() {
        return writeAdHocs(encoderBuffer(), CombinedSbePrestoHeaderEncoder.ENCODED_LENGTH + encodedLength());
    }

    private int writeAdHocs(MutableDirectBuffer out, int offset) {
        int index = offset;
        short adHocsCount = (short) _obj.getAdHocs().size();
        out.putShort(index, adHocsCount);
        index += SIZE_OF_SHORT;
        if (adHocsCount > 0) {
            for (Map.Entry<String, Object> entry : _obj.getAdHocs().entrySet()) {
                String field = entry.getKey();
                index += out.putStringAscii(index, field);
                Object value = entry.getValue();
                if (value instanceof Short) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_SHORT);
                    index += SIZE_OF_SHORT;
                    out.putShort(index, ((Short) value).shortValue());
                    index += SIZE_OF_SHORT;
                } else if (value instanceof Integer) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_INT);
                    index += SIZE_OF_SHORT;
                    out.putInt(index, ((Integer) value).intValue());
                    index += SIZE_OF_INT;
                } else if (value instanceof Long) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_LONG);
                    index += SIZE_OF_SHORT;
                    out.putLong(index, ((Long) value).longValue());
                    index += SIZE_OF_LONG;
                } else if (value instanceof Float) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_FLOAT);
                    index += SIZE_OF_SHORT;
                    out.putFloat(index, ((Float) value).floatValue());
                    index += SIZE_OF_FLOAT;
                } else if (value instanceof Double || value instanceof Number) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_DOUBLE);
                    index += SIZE_OF_SHORT;
                    out.putDouble(index, ((Number) value).doubleValue());
                    index += SIZE_OF_DOUBLE;
                } else if (value instanceof Boolean) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_BOOLEAN);
                    index += SIZE_OF_SHORT;
                    out.putShort(index, ((Boolean) value).booleanValue() ? (short) 1 : (short) 0);
                    index += SIZE_OF_SHORT;
                } else if (value instanceof PTimestamp) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_TIMESTAMP);
                    index += SIZE_OF_SHORT;
                    out.putLong(index, ((PTimestamp) value).getTimestamp());
                    index += SIZE_OF_LONG;
                } else if (value instanceof PNanos) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_NANOS);
                    index += SIZE_OF_SHORT;
                    out.putLong(index, ((PNanos) value).getNanos());
                    index += SIZE_OF_LONG;
                } else if (value instanceof PDate) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_DATE);
                    index += SIZE_OF_SHORT;
                    out.putInt(index, ((PDate) value).getDate());
                    index += SIZE_OF_INT;
                } else if (value instanceof PTime) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_TIME);
                    index += SIZE_OF_SHORT;
                    out.putInt(index, ((PTime) value).getTime());
                    index += SIZE_OF_INT;
                } else if (value instanceof Character) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_CHAR);
                    index += SIZE_OF_SHORT;
                    out.putChar(index, ((Character) value).charValue());
                    index += SIZE_OF_CHAR;
                } else if (value instanceof Enum) {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_ENUM);
                    index += SIZE_OF_SHORT;
                    Enum<?> enumVal = (Enum<?>) value;
                    index += out.putStringAscii(index, enumVal.getClass().getName());
                    index += out.putStringAscii(index, enumVal.name());
                } else {
                    out.putShort(index, (short) TypeMetaInfo.TYPE_STRING);
                    index += SIZE_OF_SHORT;
                    index += out.putStringAscii(index, value.toString());
                }
            }
        }
        return index - offset;
    }

    public void decodeHeader(CombinedSbePrestoHeaderDecoder headerDecoder) {
        _version = headerDecoder.sbeSchemaVersion();
        StringBuilder sb = Utils.getThreadLocalStringBuilder();
        headerDecoder.getSubject(sb);
        _subject = Utils.intern(sb);
        _pubType = convert(headerDecoder.pubType());
        _requestId = headerDecoder.requestId();
        sb.setLength(0);
        headerDecoder.getOriginClient(sb);
        _originClient = Utils.intern(sb);
        if ("".equals(_originClient)) _originClient = null;
        _mine = headerDecoder.mine();
        _tsNanos = headerDecoder.tsNanos();
        _serialId = headerDecoder.serialId();
        _seqNo = headerDecoder.seqNo();
        _backPressured = headerDecoder.backPressured() == SbeBoolean.TRUE;
        _onLoopback = headerDecoder.onLoopback() == SbeBoolean.TRUE;
    }

    public void decodeAdHocs() {
        MessageDecoderFlyweight decoder = getDecoder();
        readAdHocs(decoderBuffer(), decoder.offset() + decoder.encodedLength());
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private int readAdHocs(DirectBuffer in, int offset) {
        int index = offset;
        short adHocsCount = in.getShort(index);
        index += SIZE_OF_SHORT;
        if (adHocsCount > 0) {
            StringBuilder sb = Utils.getThreadLocalStringBuilder();
            for (int i = 0; i < adHocsCount; i++) {
                sb.setLength(0);
                in.getStringAscii(index, sb);
                String field = Utils.intern(sb);
                index += field.length() + SIZE_OF_INT;
                Object value = null;
                short type = in.getShort(index);
                index += SIZE_OF_SHORT;
                switch (type) {
                    case TypeMetaInfo.TYPE_CHAR:
                        value = in.getChar(index);
                        index += SIZE_OF_CHAR;
                        break;
                    case TypeMetaInfo.TYPE_STRING:
                        String str = in.getStringAscii(index);
                        index += str.length() + SIZE_OF_INT;
                        value = str;
                        break;
                    case TypeMetaInfo.TYPE_SHORT:
                        value = in.getShort(index);
                        index += SIZE_OF_SHORT;
                        break;
                    case TypeMetaInfo.TYPE_INT:
                        value = in.getInt(index);
                        index += SIZE_OF_INT;
                        break;
                    case TypeMetaInfo.TYPE_LONG:
                        value = in.getLong(index);
                        index += SIZE_OF_LONG;
                        break;
                    case TypeMetaInfo.TYPE_FLOAT:
                        value = in.getFloat(index);
                        index += SIZE_OF_FLOAT;
                        break;
                    case TypeMetaInfo.TYPE_DOUBLE:
                        value = in.getDouble(index);
                        index += SIZE_OF_DOUBLE;
                        break;
                    case TypeMetaInfo.TYPE_BOOLEAN:
                        value = in.getShort(index) == (short) 1;
                        index += SIZE_OF_SHORT;
                        break;
                    case TypeMetaInfo.TYPE_TIMESTAMP:
                        value = new PTimestamp(in.getLong(index));
                        index += SIZE_OF_LONG;
                        break;
                    case TypeMetaInfo.TYPE_NANOS:
                        value = new PNanos(in.getLong(index));
                        index += SIZE_OF_LONG;
                        break;
                    case TypeMetaInfo.TYPE_DATE:
                        value = new PDate(in.getInt(index));
                        index += SIZE_OF_INT;
                        break;
                    case TypeMetaInfo.TYPE_TIME:
                        value = new PTime(in.getInt(index));
                        index += SIZE_OF_INT;
                        break;
                    case TypeMetaInfo.TYPE_ENUM:
                        sb.setLength(0);
                        in.getStringAscii(index, sb);
                        String enumClass = Utils.intern(sb);
                        index += enumClass.length() + SIZE_OF_INT;
                        sb.setLength(0);
                        in.getStringAscii(index, sb);
                        String enumVal = Utils.intern(sb);
                        index += enumVal.length() + SIZE_OF_INT;
                        try {
                            value = Enum.valueOf((Class<Enum>) Class.forName(enumClass), enumVal);
                        } catch (ClassNotFoundException e) {
                            log.error("", e);
                        }
                        break;
                }
                if (value != null) {
                    _obj.getAdHocs().put(field, value);
                }
            }
        }
        return index;
    }

    public String toString() {
        if (_obj == null) return "_obj has not been set";
        String str = _obj.getSubject() + ":" + _obj.getPubType();
        if (_obj.getPubType() != PubType.PUB && _obj.getPubType() != PubType.UNK) {
            if (_obj.getPubType() == PubType.SNP) {
                str += "(" + _obj.getRequestId() + " " + _obj.getRtg().getOriginClient() + ")";
            } else { // RPL
                str += "(" + _obj.getRequestId() + " " + _obj.getRtg().getOriginClient() + ")";
            }
        }
        str += "(" + _obj.getMine() + ":" + _obj.getTsNanos() + ")";
        if (!_obj.getAdHocs().isEmpty()) str += " " + _obj.getAdHocs();
        return str;
    }


    private SbePubType convert(PubType pubType) {
        switch (pubType) {
            case PUB:
                return SbePubType.PUB;
            case SNP:
                return SbePubType.SNP;
            case SNP_MSG:
                return SbePubType.SNP_MSG;
            case SNP_BEGIN:
                return SbePubType.SNP_BEGIN;
            case SNP_END:
                return SbePubType.SNP_END;
            case SNP_TIMEOUT:
                return SbePubType.SNP_TIMEOUT;
            case SNP_HWM:
                return SbePubType.SNP_HWM;
            default:
                return SbePubType.UNK;
        }
    }

    public static PubType convert(SbePubType sbePubType) {
        switch (sbePubType) {
            case PUB:
                return PubType.PUB;
            case SNP:
                return PubType.SNP;
            case SNP_MSG:
                return PubType.SNP_MSG;
            case SNP_BEGIN:
                return PubType.SNP_BEGIN;
            case SNP_END:
                return PubType.SNP_END;
            case SNP_TIMEOUT:
                return PubType.SNP_TIMEOUT;
            case SNP_HWM:
                return PubType.SNP_HWM;
            default:
                return PubType.UNK;
        }
    }
}