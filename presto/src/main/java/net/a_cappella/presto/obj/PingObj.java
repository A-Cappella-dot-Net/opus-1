package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class PingObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_PING; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_PING; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) throws Exception {
        _codCtor = codCtor;
        _priority = priority;
        _staticMetaInfo.updateMetaInfoFromInstance(this);
    }

    private static Constructor<? extends Coder> _codCtor;
    @Override
    public Constructor<? extends Coder> getCoderConstructor() {
        return _codCtor;
    }

    private static ObjPriority _priority;
    @Override
    public ObjPriority getPriority() {
        return _priority;
    }

    private static final ObjMetaInfo _staticMetaInfo = new ObjMetaInfo(
            Arrays.asList(new FieldMetaInfo("id")),
            Arrays.asList(new FieldMetaInfo("payload")));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    // migna ~ meghana
    private int _id;
    private long _payload;

    @Override // IPoolable
    public void reset() {
        super.reset();
        _id = 0;
        _payload = 0;
    }

    public int getId() {
        return _id;
    }
    public void setId(int id) {
        _id = id;
    }

    public long getPayload() {
        return _payload;
    }
    public void setPayload(long payload) {
        _payload = payload;
    }

    public String toString() {
//		return super.toString()+" id="+_id+" payload="+_payload;
        return "{id="+_id+" payload="+_payload+"}";
    }

    @Override
    public int getInt(String fieldName) throws Exception {
        if ("id".equalsIgnoreCase(fieldName)) return _id;
        return super.getInt(fieldName); // throws exception
    }

    @Override
    public void setInt(String fieldName, int value) throws Exception {
        if ("id".equalsIgnoreCase(fieldName)) _id = value;
        else super.setInt(fieldName, value); // throws exception
    }

    @Override
    public long getLong(String fieldName) throws Exception {
        if ("payload".equalsIgnoreCase(fieldName)) return _payload;
        return super.getLong(fieldName); // throws exception
    }

    @Override
    public void setLong(String fieldName, long value) throws Exception {
        if ("payload".equalsIgnoreCase(fieldName)) _payload = value;
        else super.setLong(fieldName, value); // throws exception
    }
}
