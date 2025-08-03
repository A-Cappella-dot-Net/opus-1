package net.a_cappella.continuo;

public interface PrestoConstants {
    int FORCE_DISCONNECT      = -2;
    int SERIAL                = -1;
    int BYTES                 = 0;
    int VERSIONED_STRING_MSG  = 1;
    int REGISTRATION_REQUEST  = 2;
    int REGISTRATION_RESPONSE = 3;
    int FT_MEMBER             = 4;
    int FT_MONITOR            = 5;
    int SOURCES_PORTS         = 6;
    int PATHS_SUBJECTS        = 7;
    int TEST_MSG              = 8;

    // the below types must match the ones in presto-aeron/src/main/resources/schema.xml
    int TYPE_FT_MEMBER   = 101;
    int TYPE_FT_MONITOR  = 102;
    int TYPE_SNP         = 103;
    int TYPE_SNP_TIMEOUT = 104;
    int TYPE_MAP         = 105;
    int TYPE_MONITOR     = 106;
    int TYPE_PING        = 107;
    int TYPE_TEST        = 108;
    int TYPE_CACHE_CMD   = 109;
    int TYPE_SEQ_NO      = 110;

    String SUBJ_FT_MEMBER   = "ft.member";
    String SUBJ_FT_MONITOR  = "ft.monitor";
    String SUBJ_SNP         = "snap";
    String SUBJ_SNP_TIMEOUT = "snap.timeout";
    String SUBJ_MAP         = "map";
    String SUBJ_PING        = "ping";
    String SUBJ_TEST        = "test";
    String SUBJ_CACHE_CMD   = "cache.cmd";
    String SUBJ_SEQ_NO      = "seq.no";

    char YES = 'Y';
    char NO = 'N';

    String NULL_SUBJECT = "null";
}
