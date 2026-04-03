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

package net.a_cappella.cembalo.cukes.adaptors;

import io.cucumber.java.DataTableType;

import java.util.Map;
import java.util.Objects;

public class CukeRejection {
    private final String uid;
    private final String clOrdId;
    private final long ordId;
    private final String ordStatus;
    private final String text;

    @DataTableType
    public static CukeRejection cukeRejection(Map<String, String> entry) {
        return new CukeRejection(
                entry.get("uid"),
                Long.parseLong(entry.get("ordId")),
                entry.get("clOrdId"),
                entry.get("ordStatus"),
                entry.get("text")
        );
    }

    public CukeRejection(String uid, long ordId, String clOrdId, String ordStatus, String text) {
        this.uid = uid;
        this.ordId = ordId;
        this.clOrdId = clOrdId;
        this.ordStatus = ordStatus;
        this.text = emptyStringIfNull(text);
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        long temp;
        temp = ordId;
        result = prime * result + (int) (temp ^ (temp >>> 32));
        result = prime * result + ((uid == null) ? 0 : uid.hashCode());
        result = prime * result + ((clOrdId == null) ? 0 : clOrdId.hashCode());
        result = prime * result + ((ordStatus == null) ? 0 : ordStatus.hashCode());
        result = prime * result + ((text == null) ? 0 : text.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        CukeRejection other = (CukeRejection) obj;

        if (!Objects.equals(uid, other.uid)) return false;
        if (!Objects.equals(clOrdId, other.clOrdId)) return false;
        if (!Objects.equals(ordId, other.ordId)) return false;
        if (!Objects.equals(ordStatus, other.ordStatus)) return false;
        if (!Objects.equals(text, other.text)) return false;

        return true;
    }

    @Override
    public String toString() {
        return "{REJECTION "+uid+" "+clOrdId+" "+ordId+" "+ordStatus+" "+text+"}";
    }

    private static String emptyStringIfNull(String str) {
        return (str==null) ? "" : str;
    }
}
