package net.a_cappella.cembalo.cukes.adaptors;

import java.util.Objects;

public class CukeRejection {
    private final String uid;
    private final String clOrdId;
    private final long ordId;
    private final String ordStatus;
    private final String text;

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
