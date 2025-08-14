package net.a_cappella.presto.serializer;

import net.a_cappella.presto.obj.FtMemberObj;
import net.a_cappella.presto.obj.SeqNoObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.continuo.PrestoConstants.SUBJ_FT_MEMBER;
import static net.a_cappella.continuo.PrestoConstants.SUBJ_SEQ_NO;
import static net.a_cappella.presto.ft.constants.FtMsgOp.ACTIVATE;
import static net.a_cappella.presto.ft.constants.FtMsgOp.DEACTIVATE;

public class SerializerService {
    private static final Logger log = LoggerFactory.getLogger(SerializerService.class);

    private static final String _ftMemberSubSql = "select * from " + SUBJ_FT_MEMBER + " where groupName='%s' and instance=%d";
    private static final String _seqNoSubSql = "select * from " + SUBJ_SEQ_NO;

    private final String _ftGroup;
    private final int _ftInstance;

    private final PrestoClient _client;
    private final PrestoSerializer _serializer;

    public SerializerService(PrestoClient client, PrestoSerializer serializer) {
        _serializer = serializer;
        _client = client;

        _ftGroup = "FT.SER." + _client.getAppInfo().getShard();
        _ftInstance = client.getAppInfo().getInstance();
    }

    public void init() {
        _serializer.waitUntilInitialized();
        _client.waitUntilInitialized();

        try {
            _client.subscribe(String.format(_ftMemberSubSql, _ftGroup, _ftInstance), (obj, subsId) -> {
                onFtMemberMessage((FtMemberObj) obj);
            });
        } catch (Exception x) {
            log.error("", x);
        }

        _client.registerFtMember(_ftGroup, _client.getAppInfo().getInstance(), 1);
    }

    public void onFtMemberMessage(FtMemberObj ftMem) {
        if (ftMem.getAction() == ACTIVATE) {
            long seqNo = _client.getSeqNo();
            if (seqNo > 0) { // serializer was in hot/hot mode
                _serializer.onActivate(seqNo);
            } else { // serializer has received no serialized message since it was inactive
                // retrieve the latest value from the cache
                try {
                    _client.snap(_seqNoSubSql, (obj, subsId) -> {
                        SeqNoObj seqNoObj = (SeqNoObj) obj;
                        _serializer.onActivate(seqNoObj.getSeqNo());
                    });
                } catch (Exception x) {
                    log.error("", x);
                }
            }
        } else if (ftMem.getAction() == DEACTIVATE) {
            _serializer.onDeactivate();
        }
    }
}
