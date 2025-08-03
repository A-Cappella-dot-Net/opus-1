package net.a_cappella.cembalo.beans;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.InstrPhase;
import net.a_cappella.cembalo.constants.InstrStatus;
import net.a_cappella.continuo.utils.Utils;

public class InstrumentStatus {
    public String _securityID;
    public Book _book;
    public InstrStatus _status;
    public InstrPhase _phase;
    public long _tsx;

    public InstrumentStatus() {}

    public InstrumentStatus(String securityID, Book book) {
        _securityID = securityID;
        _book = book;
        _status = InstrStatus.CLOSED;
        _phase = InstrPhase.CLOSED;
    }

    public void reset(String securityID, long tsx) {
        _securityID = securityID;
        _book = null;
        _status = null;
        _phase = null;
        _tsx = tsx;
    }

    public boolean isSet() {
        return _book != null;
    }

    public String toString() {
        return "{"+_securityID+" "+_book+" "+_status+" "+_phase+" "+ Utils.formatMillis(_tsx)+"}";
    }
}
