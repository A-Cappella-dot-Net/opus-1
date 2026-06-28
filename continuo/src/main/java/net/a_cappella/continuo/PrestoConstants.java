/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.continuo;

public interface PrestoConstants {
    int FORCE_DISCONNECT      = 1;
    int SERIAL                = 2;
    int BYTES                 = 3;
    int VERSIONED_STRING_MSG  = 4;
    int REGISTRATION_REQUEST  = 5;
    int REGISTRATION_RESPONSE = 6;
    int VOTE_MSG              = 7;
    int FT_MEMBER             = 8;
    int FT_MONITOR            = 9;
    int SOURCES_PORTS         = 10;
    int PATHS_SUBJECTS        = 11;
    int TEST_MSG              = 12;

    // the below types must match the ones in presto-aeron/src/main/resources/schema.xml
    int TYPE_FT_MEMBER   = 101;
    int TYPE_FT_MONITOR  = 102;
    int TYPE_SNP         = 103;
    int TYPE_SNP_TIMEOUT = 104;
    int TYPE_MAP         = 105;
    int TYPE_PING        = 106;
    int TYPE_TEST        = 107;
    int TYPE_CACHE_CMD   = 108;
    int TYPE_SEQ_NO      = 109;

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
}
