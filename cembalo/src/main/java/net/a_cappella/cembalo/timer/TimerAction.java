package net.a_cappella.cembalo.timer;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;

public class TimerAction {
    protected Book _book;
    protected Operation _operation;

    public TimerAction(Book book, Operation operation) {
        _book = book;
        _operation = operation;
    }

    public String toString() {
        return "{"+_book+" "+_operation+"}";
    }
}
