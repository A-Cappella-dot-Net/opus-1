package net.a_cappella.presto.obj;

import gnu.trove.map.TObjectCharMap;
import gnu.trove.map.TObjectDoubleMap;
import gnu.trove.map.TObjectLongMap;
import gnu.trove.map.hash.TObjectCharHashMap;
import gnu.trove.map.hash.TObjectDoubleHashMap;
import gnu.trove.map.hash.TObjectLongHashMap;
import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class MapObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(MapObj.class);

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_MAP; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_MAP; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) throws Exception {
        _codCtor = codCtor;
        _staticMetaInfo.updateMetaInfoFromInstance(this);
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

    private static final ObjMetaInfo _staticMetaInfo = new ObjMetaInfo(
            Collections.emptyList(),
            Collections.emptyList());

    protected TObjectLongMap<String> _longMap;
    protected TObjectDoubleMap<String> _doubleMap;
    protected TObjectCharMap<String> _charMap;
    protected Map<String, String> _stringMap;
    protected Map<String, Enum<?>> _enumMap;

    public void reset() {
        super.reset();
        if (_longMap!=null) _longMap.clear();
        if (_doubleMap!=null) _doubleMap.clear();
        if (_charMap!=null) _charMap.clear();
        if (_stringMap!=null) _stringMap.clear();
        if (_enumMap!=null) _enumMap.clear();
    }

    public void setSubjectMetaInfo(String subject, ObjMetaInfo metaInfo) {
        _subject = subject;
        _metaInfo = metaInfo;
    }

    public void initLongMap(int initialCapacity) {
        _longMap = new TObjectLongHashMap<>(initialCapacity);
    }
    public void initLongMap(int initialCapacity, float loadFactor) {
        _longMap = new TObjectLongHashMap<>(initialCapacity, loadFactor);
    }

    public void initDoubleMap(int initialCapacity) {
        _doubleMap = new TObjectDoubleHashMap<>(initialCapacity);
    }
    public void initDoubleMap(int initialCapacity, float loadFactor) {
        _doubleMap = new TObjectDoubleHashMap<>(initialCapacity, loadFactor);
    }

    public void initCharMap(int initialCapacity) {
        _charMap = new TObjectCharHashMap<>(initialCapacity);
    }
    public void initCharMap(int initialCapacity, float loadFactor) {
        _charMap = new TObjectCharHashMap<>(initialCapacity, loadFactor);
    }

    public void initStringMap(int initialCapacity) {
        _stringMap = new HashMap<>(initialCapacity);
    }
    public void initStringMap(int initialCapacity, float loadFactor) {
        _stringMap = new HashMap<>(initialCapacity, loadFactor);
    }

    public void initEnumMap(int initialCapacity) {
        _enumMap = new HashMap<>(initialCapacity);
    }
    public void initEnumMap(int initialCapacity, float loadFactor) {
        _enumMap = new HashMap<>(initialCapacity, loadFactor);
    }


    @Override
    public short getShort(String key) {
        if ("mine".equals(key)) return getMine();
        if (_longMap == null) {
            log.warn("Missing short field " + key);
            return 0;
        }
        return (short) _longMap.get(key);
    }
    @Override
    public void setShort(String key, short value) {
        if ("mine".equals(key)) setMine(value);
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public int getInt(String key) throws Exception {
        if (_longMap == null) {
            log.warn("Missing int field " + key);
            return 0;
        }
        return (int) _longMap.get(key);
    }
    @Override
    public void setInt(String key, int value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public long getLong(String key) throws Exception {
        if (_longMap == null) {
            log.warn("Missing long field " + key);
            return 0;
        }
        return _longMap.get(key);
    }
    @Override
    public void setLong(String key, long value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public float getFloat(String key) {
        if (_doubleMap == null) {
            log.warn("Missing float field " + key);
            return (float) Double.NaN;
        }
        return (float) _doubleMap.get(key);
    }
    @Override
    public void setFloat(String key, float value) {
        if (_doubleMap==null) {
            _doubleMap = new TObjectDoubleHashMap<>();
        }
        _doubleMap.put(key, value);
    }

    @Override
    public double getDouble(String key) {
        if (_doubleMap == null) {
            log.warn("Missing double field " + key);
            return Double.NaN;
        }
        return _doubleMap.get(key);
    }
    @Override
    public void setDouble(String key, double value) {
        if (_doubleMap==null) {
            _doubleMap = new TObjectDoubleHashMap<>();
        }
        _doubleMap.put(key, value);
    }

    @Override
    public boolean getBoolean(String key) {
        if ("backPressured".equals(key)) return isBackPressured();
        if ("onLoopback".equals(key)) return isOnLoopback();
        if (_longMap == null) {
            log.warn("Missing boolean field " + key);
            return false;
        }
        return _longMap.get(key)!=0;
    }
    @Override
    public void setBoolean(String key, boolean value) {
//		if ("backPressured".equals(key)) setBackPressured(value); is not settable
//		if ("onLoopback".equals(key)) setOnLoopback(value); is not settable
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, (value)?1:0);
    }

    @Override
    public long getTimestamp(String key) {
        if (_longMap == null) {
            log.warn("Missing timestamp field " + key);
            return 0;
        }
        return _longMap.get(key);
    }
    @Override
    public void setTimestamp(String key, long value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public long getNanos(String key) {
        if (_longMap == null) {
            log.warn("Missing nanos field " + key);
            return 0;
        }
        return _longMap.get(key);
    }
    @Override
    public void setNanos(String key, long value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public int getTime(String key) {
        if (_longMap == null) {
            log.warn("Missing time field " + key);
            return 0;
        }
        return (int) _longMap.get(key);
    }
    @Override
    public void setTime(String key, int value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public int getDate(String key) {
        if (_longMap == null) {
            log.warn("Missing date field " + key);
            return 0;
        }
        return (int) _longMap.get(key);
    }
    @Override
    public void setDate(String key, int value) {
        if (_longMap==null) {
            _longMap = new TObjectLongHashMap<>();
        }
        _longMap.put(key, value);
    }

    @Override
    public char getChar(String key) {
        if (_charMap == null) {
            log.warn("Missing char field " + key);
            return '\0';
        }
        return _charMap.get(key);
    }
    @Override
    public void setChar(String key, char value) {
        if (_charMap==null) {
            _charMap = new TObjectCharHashMap<>();
        }
        _charMap.put(key, value);
    }

    @Override
    public String getString(String key) throws Exception {
        if (_stringMap == null) {
            log.warn("Missing string field " + key);
            return null;
        }
        return _stringMap.get(key);
    }
    @Override
    public void setString(String key, String value) {
        if (_stringMap==null) {
            _stringMap = new HashMap<>();
        }
        _stringMap.put(key, value);
    }

    @Override
    public Enum<?> getEnum(String key) {
        if (_enumMap == null) {
            log.warn("Missing enum field " + key);
            return null;
        }
        return _enumMap.get(key);
    }
    @Override
    public void setEnum(String key, Enum<?> value) {
        if (_enumMap==null) {
            _enumMap = new HashMap<>();
        }
        _enumMap.put(key, value);
    }


    @Override
    public int hashCode() {
        final int prime = 31;
        int result = super.hashCode();
        result = prime * result + ((_charMap == null) ? 0 : _charMap.hashCode());
        result = prime * result + ((_doubleMap == null) ? 0 : _doubleMap.hashCode());
        result = prime * result + ((_enumMap == null) ? 0 : _enumMap.hashCode());
        result = prime * result + ((_longMap == null) ? 0 : _longMap.hashCode());
        result = prime * result + ((_stringMap == null) ? 0 : _stringMap.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (!super.equals(obj))
            return false;
        if (getClass() != obj.getClass())
            return false;
        MapObj other = (MapObj) obj;
        if (_charMap == null) {
            if (other._charMap != null)
                return false;
        } else if (!_charMap.equals(other._charMap))
            return false;
        if (_doubleMap == null) {
            if (other._doubleMap != null)
                return false;
        } else if (!_doubleMap.equals(other._doubleMap))
            return false;
        if (_enumMap == null) {
            if (other._enumMap != null)
                return false;
        } else if (!_enumMap.equals(other._enumMap))
            return false;
        if (_longMap == null) {
            if (other._longMap != null)
                return false;
        } else if (!_longMap.equals(other._longMap))
            return false;
        if (_stringMap == null) {
            if (other._stringMap != null)
                return false;
        } else if (!_stringMap.equals(other._stringMap))
            return false;
        return true;
    }

    @Override
    public String toString() {
        String str = "";
        if (_longMap!=null && !_longMap.isEmpty()) {
            str += " "+_longMap;
        }
        if (_doubleMap!=null && !_doubleMap.isEmpty()) {
            str += " "+_doubleMap;
        }
        if (_charMap!=null && !_charMap.isEmpty()) {
            str += " "+_charMap;
        }
        if (_stringMap!=null && !_stringMap.isEmpty()) {
            str += " "+_stringMap;
        }
        if (_enumMap!=null && !_enumMap.isEmpty()) {
            str += " "+_enumMap;
        }
        return super.toString()+str;
    }
}
