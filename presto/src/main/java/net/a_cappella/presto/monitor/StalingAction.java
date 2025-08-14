package net.a_cappella.presto.monitor;

import net.a_cappella.continuo.obj.Obj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

public class StalingAction {
    private static final Logger log = LoggerFactory.getLogger(StalingAction.class);

    private final IStalingPredicate _stalingPredicate;
    private final List<String> _stalingSqls;
    private MonitorService _service;
    public void setService(MonitorService service) {
        _service = service;
    }

    public StalingAction(IStalingPredicate stalingPredicate, List<String> stalingSqls) {
        _stalingPredicate = stalingPredicate;
        _stalingSqls = stalingSqls;
    }

    public void eval(Obj obj) {
        log.info("eval {}", obj);
        if (_stalingPredicate.shouldStale(obj)) {
            for (String stalingSql : _stalingSqls) {
                staleRecordSet(stalingSql);
            }
        }
    }

    private void staleRecordSet(String stalingSql) {
        log.info("snapping {}", stalingSql);
        try {
            _service.getClient().snap(stalingSql, (obj, subsId) -> {
                onSubscriptionMessage(obj);
            });
        } catch (Exception x) {
            log.error("", x);
        }
    }

    private void onSubscriptionMessage(Obj obj) {
        log.debug("onSubscriptionMessage {}", obj);
        if (obj instanceof IStaleable) {
            try {
                // I can re-use the object because I am the only user of it (snap result)
                ((IStaleable) obj).stale();
                _service.getClient().publish(obj);
            } catch (Exception e) {
                log.error("", e);
            }
        } else {
            log.error(obj+" is NOT staleable. Ignoring...");
        }
    }
}
