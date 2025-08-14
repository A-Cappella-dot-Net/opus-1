package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;

public class SnapTimeoutObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(SnapTimeoutObj.class);

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_SNP_TIMEOUT; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_SNP_TIMEOUT; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) {
        _codCtor = codCtor;
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

    private long _ts;

    public SnapTimeoutObj() {
        _pubType = PubType.SNP_TIMEOUT;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
        _ts = 0;
    }

    public void set(String subject, long requestId, long ts) {
        _pubType = PubType.SNP_TIMEOUT;
        _subject = subject;
        _requestId = requestId;
        _ts = ts;
    }

    public long getTs() {
        return _ts;
    }
    public void setTs(long ts) {
        _ts = ts;
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

    public String toString() {
        return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+ Utils.formatMillis(_ts)+"}";
    }
}
