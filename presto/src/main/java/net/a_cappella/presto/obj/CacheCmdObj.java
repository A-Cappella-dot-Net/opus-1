package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class CacheCmdObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_CACHE_CMD; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_CACHE_CMD; }

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
            Arrays.asList(
                    new FieldMetaInfo("command"),
                    new FieldMetaInfo("cacheSubject")
            ),
            Arrays.asList(new FieldMetaInfo("whereClause")));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _command;
    private String _cacheSubject;
    private String _whereClause;

    public CacheCmdObj() {}

    public CacheCmdObj(CacheCmdObj obj) {
        super(obj);
        _command = obj._command;
        _cacheSubject = obj._cacheSubject;
        _whereClause = obj._whereClause;
    }

    public CacheCmdObj set(String command, String cacheSubject, String whereClause) {
        _command = command;
        _cacheSubject = cacheSubject;
        _whereClause = whereClause;
        return this;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _command = null;
        _cacheSubject = null;
        _whereClause = null;
    }

    public String getCommand() {
        return _command;
    }
    public void setCommand(String command) {
        _command = command;
    }
    public String getCacheSubject() {
        return _cacheSubject;
    }
    public void setCacheSubject(String cacheSubject) {
        _cacheSubject = cacheSubject;
    }
    public String getWhereClause() {
        return _whereClause;
    }
    public void setWhereClause(String whereClause) {
        _whereClause = whereClause;
    }

    public String toString() {
        return super.toString()+" {"+_command+" "+_cacheSubject+" "+_whereClause+"} ";
    }

    @Override
    public String getString(String fieldName) throws Exception {
        if ("command".equalsIgnoreCase(fieldName)) return _command;
        if ("cacheSubject".equalsIgnoreCase(fieldName)) return _cacheSubject;
        if ("whereClause".equalsIgnoreCase(fieldName)) return _whereClause;
        return super.getString(fieldName); // throws exception
    }
    @Override
    public void setString(String fieldName, String value) throws Exception {
        if ("command".equalsIgnoreCase(fieldName)) _command = value;
        if ("cacheSubject".equalsIgnoreCase(fieldName)) _cacheSubject = value;
        if ("whereClause".equalsIgnoreCase(fieldName)) _whereClause = value;
        else super.setString(fieldName, value); // throws exception
    }

}
