package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class FtMonitorObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_FT_MONITOR; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_FT_MONITOR; }

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
            Arrays.asList(new FieldMetaInfo("groupName")),
            Arrays.asList(
                    new FieldMetaInfo("actives"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            )
    );
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _groupName;
    private int _actives;
    private long _ts;

    public FtMonitorObj() {}

    public FtMonitorObj(FtMonitorObj obj) {
        super(obj);
        _groupName = obj._groupName;
        _actives = obj._actives;
    }

    public FtMonitorObj set(String groupName, int actives, long ts) {
        _groupName = groupName;
        _actives = actives;
        _ts = ts;
        return this;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _groupName = null;
        _actives = 0;
        _ts = 0;
    }

    public String getGroupName() {
        return _groupName;
    }
    public void setGroupName(String groupName) {
        _groupName = groupName;
    }
    public int getActives() {
        return _actives;
    }
    public void setActives(int actives) {
        _actives = actives;
    }
    public long getTs() {
        return _ts;
    }
    public void setTs(long ts) {
        _ts = ts;
    }

    public String toString() {
        return "{"+_groupName+" "+_actives+" "+ Utils.formatMillis(_ts)+"}";
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("groupName".equalsIgnoreCase(fieldName)) return _groupName;
        return super.getString(fieldName); // throws exception
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("groupName".equalsIgnoreCase(fieldName)) _groupName = value;
        else super.setString(fieldName, value); // throws exception
    }

    @Override
    public int getInt(String fieldName) throws Exception {
        if ("actives".equalsIgnoreCase(fieldName)) return _actives;
        return super.getInt(fieldName); // throws exception
    }
    @Override
    public void setInt(String fieldName, int value) throws Exception {
        if ("actives".equalsIgnoreCase(fieldName)) _actives = value;
        else super.setInt(fieldName, value); // throws exception
    }

    @Override
    public long getTimestamp(String fieldName) throws Exception {
        if ("ts".equalsIgnoreCase(fieldName)) return _ts;
        return super.getTimestamp(fieldName); // throws exception
    }
    @Override
    public void setTimestamp(String fieldName, long value) throws Exception {
        if ("ts".equalsIgnoreCase(fieldName)) _ts = value;
        else super.setTimestamp(fieldName, value); // throws exception
    }
}
