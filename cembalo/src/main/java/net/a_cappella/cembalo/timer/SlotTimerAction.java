package net.a_cappella.cembalo.timer;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;

public class SlotTimerAction extends TimerAction {
    public int _slot;

    public SlotTimerAction(Book book, Operation operation, int slot) {
        super(book, operation);
        _slot = slot;
    }

    public String toString() {
        return "{"+super.toString()+" slot="+_slot+"}";
    }
}
