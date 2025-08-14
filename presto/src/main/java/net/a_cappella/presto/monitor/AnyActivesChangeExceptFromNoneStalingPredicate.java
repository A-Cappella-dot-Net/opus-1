package net.a_cappella.presto.monitor;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.obj.FtMonitorObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AnyActivesChangeExceptFromNoneStalingPredicate implements IStalingPredicate {
    private static final Logger log = LoggerFactory.getLogger(AnyActivesChangeExceptFromNoneStalingPredicate.class);

    private int _actives = CollectiveClient.NONE;

    @Override
    public boolean shouldStale(Obj obj) {
        boolean result;

        FtMonitorObj ftMon = (FtMonitorObj) obj;
        int actives = ftMon.getActives();

        if (actives == _actives) result = false;
        else if (_actives == CollectiveClient.NONE) {
            _actives = actives;
            result = false;
        } else {
            _actives = actives;
            result = true;
        }

        log.info("shouldStale({}) => {}", obj, result);
        return result;
    }

}
