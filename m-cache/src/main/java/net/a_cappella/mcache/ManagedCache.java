package net.a_cappella.mcache;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.presto.ft.constants.FtMsgOp;
import net.a_cappella.presto.obj.CacheCmdCoder;
import net.a_cappella.presto.obj.CacheCmdObj;
import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.ps.PrestoClient;

import net.a_cappella.continuo.utils.interner.HashMap;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jmx.export.annotation.ManagedOperation;
import org.springframework.jmx.export.annotation.ManagedOperationParameter;
import org.springframework.jmx.export.annotation.ManagedOperationParameters;
import org.springframework.jmx.export.annotation.ManagedResource;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

@ManagedResource(objectName="m-cache:name=Managed Cache", description="Managed Cache Controls")
public class ManagedCache {
    private static final Logger log = LoggerFactory.getLogger(ManagedCache.class);

    private static final String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";

    public static final String CMD_CLEAN = "clean";
    public static final String CMD_LOG = "log";

    private static final ObjectManager _objectManager = ObjectManager.getInstance();
	static {
		try {
		    MsgInstantiator localInstantiator = new MsgInstantiator(CacheCmdObj.class.getName(), CacheCmdCoder.class.getName());
	        _objectManager.setMsgInstantiators(Arrays.asList(localInstantiator));
	        _objectManager.setMsgPools(Arrays.asList(new Pool<Msg>(localInstantiator, 10, 10)));
		} catch (Exception x) {
			x.printStackTrace();
		}
	}

	private static final ThreadLocal<CacheCmdObj> _cacheCmdObjThreadLocal = new ThreadLocal<>() {
		public CacheCmdObj initialValue() {
			return new CacheCmdObj();
		}
		public CacheCmdObj get() {
			CacheCmdObj obj = super.get();
			obj.reset();
			return obj;
		}
	};

    private final PrestoClient _client;
    private final String _ftGroup;
    private final int _ftInstance;
    public boolean _active = false;

    private final Map<String, ManagedSubject> _bySubjectMap = new HashMap<>();

    public ManagedCache(PrestoClient client, List<ManagedSubject> managedSubjectsList) {
        _client = client;
        _ftGroup = "FT.MC." + client.getAppInfo().getShard();
        _ftInstance = client.getAppInfo().getInstance();

        for (ManagedSubject managedSubject : managedSubjectsList) {
    		try {
	            String subj = managedSubject.getSubj();
	            if (_bySubjectMap.putIfAbsent(subj, managedSubject) != null) {
	            	throw new Exception("Subject already cached <"+subj+">. Only one caching sql is alowed for a subject.");
	            }
    		} catch (Exception x) {
                log.error("", x);
    		}
        }

	}

    public void init() {
    	_client.waitUntilInitialized();

		try {
	        _client.subscribe(String.format(_ftMemberSubSql, _ftGroup, _ftInstance), (obj, subsId) -> {
	        	onFtMemberMessage((FtMemberObj) obj);
	    	});

	    	for (ManagedSubject managedSubject : _bySubjectMap.values()) {
	    		managedSubject.init(_client, this);
	        }
		} catch (Exception x) {
            log.error("", x);
		}

		_client.registerFtMember(_ftGroup, _ftInstance, 1);
    }

	private void onFtMemberMessage(FtMemberObj ftMem) {
		FtMsgOp op = ftMem.getAction();
        log.info("onFtMemberMessage("+ftMem+")");
		
		if (op == ACTIVATE) {
			_active = true;
		} else if (op == DEACTIVATE) {
			_active = false;
		}
	}

	public boolean isActive() {
		return _active;
	}





    public void loopbackCacheCmdMessage(String command, String subj, String condition) {
    	CacheCmdObj obj = _cacheCmdObjThreadLocal.get();
    	obj.set(command, subj, condition);
    	try {
			_client.loopback(obj);
		} catch (Exception e) {
            log.error("", e);
		}
    }



    // JMX helpers
    @ManagedOperation(description = "Log one subject in the cache")
    @ManagedOperationParameters({
        @ManagedOperationParameter(description = "The subject to log.", name = "subject") })
    public String log(String subject) {
        log.info("JMX.log <"+subject+">");
        if ("String".equalsIgnoreCase(subject) || subject==null || "".equals(subject.trim())) {
            subject = "*";
            for (String subj : _bySubjectMap.keySet()) {
                loopbackCacheCmdMessage(CMD_LOG, subj, null);
            }
        } else {
            subject = subject.trim();
            ManagedSubject ms = _bySubjectMap.get(subject);
            if (ms==null) {
                return "Unknown 'subject' {"+subject+"}";
            }
            loopbackCacheCmdMessage(CMD_LOG, subject, null);
        }
        return subject+" logged...";
    }

    @ManagedOperation(description = "Clean one subject in the cache")
    @ManagedOperationParameters({
        @ManagedOperationParameter(description = "The subject to clean (e.g., b2b.price).", name = "subject"),
        @ManagedOperationParameter(description = "Optional where clause (e.g., completed=1).", name = "whereClause") })
    public String clean(String subject, String condition) {
        if ("String".equalsIgnoreCase(condition) || condition==null || "".equals(condition.trim())) condition = null;
        if ("String".equalsIgnoreCase(subject) || subject==null || "".equals(subject.trim())) {
            subject = "*";
            for (String subj : _bySubjectMap.keySet()) {
                loopbackCacheCmdMessage(CMD_CLEAN, subj, condition);
            }
        } else {
            subject = subject.trim();
            ManagedSubject ms = _bySubjectMap.get(subject);
            if (ms==null) {
                return "Unknown 'subject' {"+subject+"}";
            }
            loopbackCacheCmdMessage(CMD_CLEAN, subject, condition);
        }
        log.info("JMX.clean <"+subject+", "+condition+">");
        loopbackCacheCmdMessage(CMD_CLEAN, subject, condition);
        return subject+" cleaned...";
    }
}
