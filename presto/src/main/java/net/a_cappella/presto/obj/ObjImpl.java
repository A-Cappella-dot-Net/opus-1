package net.a_cappella.presto.obj;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.managed.Poolable;
import net.a_cappella.continuo.msg.Rtg;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.ObjKey;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.ps.IMergeManager;
import net.a_cappella.presto.ps.KeyBasedMergeManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.*;

public abstract class ObjImpl extends Poolable implements Obj {
    private static final Logger log = LoggerFactory.getLogger(ObjImpl.class);

    public static final List<FieldMetaInfo> _headerFields = new ArrayList<>(ObjMetaInfo._headerFieldsMap.values());

    protected static volatile Constructor<? extends Rtg> _rtgCtor;
    private Rtg _rtg;

    protected PubType _pubType;
    protected String _subject;
    protected ObjMetaInfo _metaInfo;
    protected long _requestId;
    private long _tsNanos;
    private long _serialId;
    private long _seqNo;
    private short _mine;
    private boolean _backPressured;
    private boolean _onLoopback;

    protected String _key;
    protected ObjKey _objKey;

    private Map<String, Object> _adHocs = new HashMap<>();

    static {
        setRtgCtor("net.a_cappella.presto.ps.RtgImpl"); // TODO can this be done in a different way?
    }

    public static void setRtgCtor(String rtgClassName) {
        try {
            Class<?> clazz = Class.forName(rtgClassName);
            _rtgCtor = (Constructor<? extends Rtg>) clazz.getConstructor();
        } catch (ClassNotFoundException | NoSuchMethodException x) {
            log.error("Could not instantiate rtg constructor for {}", rtgClassName, x);
        }
    }

    public ObjImpl() {
        _pubType = PubType.UNK;
        _subject = getDefaultSubject();
        _metaInfo = getObjMetaInfo();
        _objKey = new ObjKeyImpl(this);

        try {
            if (_rtgCtor == null) {
                log.info("Could not instantiate rtg: rtgCtor is null {} {}", getMsgType(), _subject);
            } else {
                _rtg = _rtgCtor.newInstance();
            }
        } catch (InstantiationException | IllegalAccessException | IllegalArgumentException |
                 InvocationTargetException x) {
            log.error("Could not instantiate rtg {} {}", getMsgType(), _subject, x);
        }
    }

    public ObjImpl(ObjImpl obj) {
        this();
        _pubType = obj._pubType;
        _adHocs = obj._adHocs;
    }

    @Override
    public void reset() {
        _key = null;
        _adHocs.clear();
        _backPressured = false;
        _onLoopback = false;
    }

    @Override
    public void setPubType(PubType pubType) {
        _pubType = pubType;
    }
    @Override
    public PubType getPubType() {
        return _pubType;
    }

    // publication

    @Override
    public void setSubject(String subject) {
        _subject = subject;
    }
    @Override
    public String getSubject() {
        return _subject;
    }

    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _metaInfo;
    }
    @Override
    public void setObjMetaInfo(ObjMetaInfo metaInfo) {
        _metaInfo = metaInfo;
    }

    // routing

    @Override
    public void copyRoutingFields(Obj obj) {
        setRequestId(obj.getRequestId());
        _rtg.setOriginClient(obj.getRtg().getOriginClient());
        _rtg.copyRoutingFields(obj.getRtg());
    }
    @Override
    public Rtg getRtg() {
        return _rtg;
    }
    public void setRtg(Rtg rtg) {
        _rtg = rtg;
    }

    @Override
    public void setRequestId(long requestId) {
        _requestId = requestId;
    }
    @Override
    public long getRequestId() {
        return _requestId;
    }

    @Override
    public long getSerialId() {
        return _serialId;
    }
    @Override
    public void setSerialId(long serialId) {
        _serialId = serialId;
    }

    @Override
    public long getSeqNo() {
        return _seqNo;
    }
    @Override
    public void setSeqNo(long seqNo) {
        _seqNo = seqNo;
    }

    // performance fields

    @Override
    public long getTsNanos() {
        return _tsNanos;
    }
    @Override
    public void setTsNanos(long tsNanos) {
        _tsNanos = tsNanos;
    }
    @Override
    public short getMine() {
        return _mine;
    }
    @Override
    public short setMine(short mine) {
        return _mine = mine;
    }
    @Override
    public boolean isBackPressured() {
        return _backPressured;
    }
    @Override
    public boolean setBackPressured(boolean backPressured) {
        return _backPressured = backPressured;
    }
    @Override
    public boolean isOnLoopback() {
        return _onLoopback;
    }
    @Override
    public boolean setOnLoopback(boolean onLoopback) {
        return _onLoopback = onLoopback;
    }






    // unique identifier
    @Override
    public ObjKey getObjKey() {
        return _objKey;
    }


    // typed accessors used in SnS sql evaluation; less efficient than named accessors

    @Override
    public char getChar(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getChar(this);
    }
    @Override
    public void setChar(String fieldName, char value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setChar(this, value);
    }

    @Override
    public short getShort(String fieldName) throws Exception {
        if ("mine".equalsIgnoreCase(fieldName)) return _mine;
        return _metaInfo.fieldMetaInfo(fieldName).getField().getShort(this);
    }
    @Override
    public void setShort(String fieldName, short value) throws Exception {
        if ("mine".equalsIgnoreCase(fieldName)) _mine = value;
        _metaInfo.fieldMetaInfo(fieldName).getField().setShort(this, value);
    }

    @Override
    public int getInt(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getInt(this);
    }
    @Override
    public void setInt(String fieldName, int value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setInt(this, value);
    }

    @Override
    public long getLong(String fieldName) throws Exception {
        if ("serialId".equalsIgnoreCase(fieldName)) return _serialId;
        if ("seqNo".equalsIgnoreCase(fieldName)) return _seqNo;
        if ("tsNanos".equalsIgnoreCase(fieldName)) return _tsNanos;
        return _metaInfo.fieldMetaInfo(fieldName).getField().getLong(this);
    }
    @Override
    public void setLong(String fieldName, long value) throws Exception {
        if ("serialId".equalsIgnoreCase(fieldName)) _serialId = value;
        if ("seqNo".equalsIgnoreCase(fieldName)) _seqNo = value;
        if ("tsNanos".equalsIgnoreCase(fieldName)) _tsNanos = value;
        _metaInfo.fieldMetaInfo(fieldName).getField().setLong(this, value);
    }

    @Override
    public float getFloat(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getFloat(this);
    }
    @Override
    public void setFloat(String fieldName, float value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setFloat(this, value);
    }

    @Override
    public double getDouble(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getDouble(this);
    }
    @Override
    public void setDouble(String fieldName, double value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setDouble(this, value);
    }

    @Override
    public boolean getBoolean(String fieldName) throws Exception {
        if ("backPressured".equalsIgnoreCase(fieldName)) return _backPressured;
        if ("onLoopback".equalsIgnoreCase(fieldName)) return _onLoopback;
        return _metaInfo.fieldMetaInfo(fieldName).getField().getBoolean(this);
    }
    @Override
    public void setBoolean(String fieldName, boolean value) throws Exception {
        if ("backPressured".equalsIgnoreCase(fieldName)) _backPressured = value;
        if ("onLoopback".equalsIgnoreCase(fieldName)) _onLoopback = value;
        _metaInfo.fieldMetaInfo(fieldName).getField().setBoolean(this, value);
    }

    @Override
    public long getTimestamp(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getLong(this);
    }
    @Override
    public void setTimestamp(String fieldName, long value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setLong(this, value);
    }

    @Override
    public long getNanos(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getLong(this);
    }
    @Override
    public void setNanos(String fieldName, long value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setLong(this, value);
    }

    @Override
    public int getTime(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getInt(this);
    }
    @Override
    public void setTime(String fieldName, int value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setInt(this, value);
    }

    @Override
    public int getDate(String fieldName) throws Exception {
        return _metaInfo.fieldMetaInfo(fieldName).getField().getInt(this);
    }
    @Override
    public void setDate(String fieldName, int value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().setInt(this, value);
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("subject".equalsIgnoreCase(fieldName)) return getSubject();
        return (String) _metaInfo.fieldMetaInfo(fieldName).getField().get(this);
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("subject".equalsIgnoreCase(fieldName)) _subject = value;
        _metaInfo.fieldMetaInfo(fieldName).getField().set(this, value);
    }

    @Override
    public Enum<?> getEnum(String fieldName) throws Exception {
        return (Enum<?>) _metaInfo.fieldMetaInfo(fieldName).getField().get(this);
    }
    @Override
    public void setEnum(String fieldName, Enum<?> value) throws Exception {
        _metaInfo.fieldMetaInfo(fieldName).getField().set(this, value);
    }

    @Override
    public Object getAdHoc(String key) {
        return _adHocs.get(key);
    }
    @Override
    public void setAdHoc(String key, Object value) {
        _adHocs.put(key, value);
    }

    // uniform accessors used in graphical tools; less efficient than typed accessors
    @Override
    public int getNumFields() {
        ObjMetaInfo metaInfo = getObjMetaInfo();
        if (metaInfo==null) return 0;
        return metaInfo.getKeys().size()+metaInfo.getNonKeys().size();
    }

    @Override
    public FieldMetaInfo getFieldMetaInfo(int i) {
        ObjMetaInfo metaInfo = getObjMetaInfo();
        if (metaInfo==null) return null;
        int keysCount = metaInfo.getKeys().size();
        if (i<keysCount) {
            return metaInfo.getKeys().get(i);
        }
        int nonKeysCount = metaInfo.getNonKeys().size();
        if (i<keysCount+nonKeysCount) {
            return metaInfo.getNonKeys().get(i-keysCount);
        }
        return null;
    }

    @Override
    public Object get(String fieldName) {
        ObjMetaInfo metaInfo = getObjMetaInfo();
        if (metaInfo==null) return _adHocs.get(fieldName);
        FieldMetaInfo fieldMetaInfo = metaInfo.getFieldMetaInfo(fieldName);
        if (fieldMetaInfo==null) return _adHocs.get(fieldName);
        return get(fieldMetaInfo, fieldName);
    }

    @Override
    public Object get(int i) {
        FieldMetaInfo fieldMetaInfo = getFieldMetaInfo(i);
        return get(fieldMetaInfo, fieldMetaInfo.getName());
    }

    protected Object get(FieldMetaInfo fieldMetaInfo, String fieldName) {
        try {
            switch (fieldMetaInfo.getType()) {
                case CHAR:
                    return getChar(fieldName);
                case STRING:
                    return getString(fieldName);
                case SHORT:
                    return getShort(fieldName);
                case INT:
                    return getInt(fieldName);
                case LONG:
                    return getLong(fieldName);
                case FLOAT:
                    return getFloat(fieldName);
                case DOUBLE:
                    return getDouble(fieldName);
                case BOOLEAN:
                    return getBoolean(fieldName);
                case TIMESTAMP:
                    return new PTimestamp(getTimestamp(fieldName));
                case NANOS:
                    return new PNanos(getNanos(fieldName));
                case TIME:
                    return new PTime(getTime(fieldName));
                case DATE:
                    return new PDate(getDate(fieldName));
                case ENUM:
                    return getEnum(fieldName);
                case UNKNOWN:
                    return null;
            }
        } catch (Exception e) {
            if (log.isDebugEnabled()) {
                log.debug(fieldName, e);
            } else {
                log.warn(fieldName + " " + e.getMessage());
            }
        }
        return null;
    }

    @SuppressWarnings("incomplete-switch")
    @Override
    public void set(Map<String, Object> map) throws Exception {
        ObjMetaInfo metaInfo = getObjMetaInfo();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            Object value = entry.getValue();
            String field = entry.getKey();
            FieldMetaInfo fieldMetaInfo = (metaInfo==null) ? null : metaInfo.getFieldMetaInfo(field);
            if (fieldMetaInfo==null) {
                _adHocs.put(field, value);
            } else {
                switch (fieldMetaInfo.getType()) {
                    case CHAR:
                        setChar(field, (Character) value);
                        break;
                    case STRING:
                        setString(field, value.toString());
                        break;
                    case SHORT:
                        setShort(field, ((Number)value).shortValue());
                        break;
                    case INT:
                        setInt(field, ((Number)value).intValue());
                        break;
                    case LONG:
                        setLong(field, ((Number)value).longValue());
                        break;
                    case FLOAT:
                        setFloat(field, ((Number)value).floatValue());
                        break;
                    case DOUBLE:
                        setDouble(field, ((Number)value).doubleValue());
                        break;
                    case BOOLEAN:
                        setBoolean(field, ((Boolean)value).booleanValue());
                        break;
                    case TIMESTAMP:
                        setTimestamp(field, ((PTimestamp)value).getTimestamp());
                        break;
                    case NANOS:
                        setNanos(field, ((PNanos)value).getNanos());
                        break;
                    case TIME:
                        setTime(field, ((PTime)value).getTime());
                        break;
                    case DATE:
                        setDate(field, ((PDate)value).getDate());
                        break;
                    case ENUM:
                        setEnum(field, (Enum<?>)value);
                        break;
                }
            }
        }
    }

    @Override
    public boolean hasAdHocs() {
        return !_adHocs.isEmpty();
    }
    @Override
    public void setAdHocs(Map<String, Object> adHocs) {
        _adHocs.clear();
        if (adHocs != null) {
            _adHocs.putAll(adHocs);
        }
    }
    @Override
    public Map<String, Object> getAdHocs() {
        return _adHocs;
    }
    @Override
    public void addAdHocs(Map<String, Object> adHocs) {
        if (adHocs != null) {
            _adHocs.putAll(adHocs);
        }
    }
    @Override
    public Set<String> getAdHocFields() {
        return _adHocs.keySet();
    }

    @Override
    public IMergeManager newMergeManager() {
        return new KeyBasedMergeManager();
    }


    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((_adHocs == null) ? 0 : _adHocs.hashCode());
        result = prime * result + _mine;
        result = prime * result + ((_pubType == null) ? 0 : _pubType.hashCode());
        result = prime * result + (int) (_requestId ^ (_requestId >>> 32));
        result = prime * result + ((_subject == null) ? 0 : _subject.hashCode());
        result = prime * result + (int) (_tsNanos ^ (_tsNanos >>> 32));
        result = prime * result + (int) (_serialId ^ (_serialId >>> 32));
        result = prime * result + (int) (_seqNo ^ (_seqNo >>> 32));
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        ObjImpl other = (ObjImpl) obj;
        if (_adHocs == null) {
            if (other._adHocs != null)
                return false;
        } else if (!_adHocs.equals(other._adHocs))
            return false;
        if (_mine != other._mine)
            return false;
        if (_pubType != other._pubType)
            return false;
        if (_requestId != other._requestId)
            return false;
        if (_subject == null) {
            if (other._subject != null)
                return false;
        } else if (!_subject.equals(other._subject))
            return false;
        if (_tsNanos != other._tsNanos)
            return false;
        if (_serialId != other._serialId)
            return false;
        if (_seqNo != other._seqNo)
            return false;
        return true;
    }

    @Override
    public String toString() {
        String str = "(" + _mine + " " + _tsNanos + " " + _onLoopback + ") " + _pubType + " " + _serialId + " " + _seqNo;
        if (_adHocs==null) return str;
        return str + " " + _adHocs;
    }
}
