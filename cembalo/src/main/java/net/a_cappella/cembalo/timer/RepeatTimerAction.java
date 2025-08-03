package net.a_cappella.cembalo.timer;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;

public class RepeatTimerAction extends TimerAction {
    public int _count;

    public RepeatTimerAction(Book book, Operation operation, int count) {
        super(book, operation);
        _count = count;
    }

    public String toString() {
        return "{"+super.toString()+" count="+_count+"}";
    }
}
