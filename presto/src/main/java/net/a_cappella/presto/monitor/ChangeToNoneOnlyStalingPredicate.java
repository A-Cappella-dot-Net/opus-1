package net.a_cappella.presto.monitor;

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.ft.collective.CollectiveClient;
import net.a_cappella.presto.obj.FtMonitorObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ChangeToNoneOnlyStalingPredicate implements IStalingPredicate {
    private static final Logger log = LoggerFactory.getLogger(ChangeToNoneOnlyStalingPredicate.class);


    private int _actives = CollectiveClient.NONE;

    @Override
    public boolean shouldStale(Obj obj) {
        boolean result;

        FtMonitorObj ftMon = (FtMonitorObj) obj;
        int actives = ftMon.getActives();
        if (actives == _actives) return false;
        _actives = actives;
        result = actives == CollectiveClient.NONE;

        log.info("shouldStale({}) => {}", obj, result);
        return result;
    }

}
