package net.a_cappella.cembalo.message;

import net.a_cappella.cembalo.constants.Book;
import net.a_cappella.cembalo.constants.Operation;

public class TimerMsg {
    public Book _book;
    public Operation _operation;

    public TimerMsg(Book book, Operation operation) {
        _book = book;
        _operation = operation;
    }

    public Book getBook() {
        return _book;
    }

    public Operation getOperation() {
        return _operation;
    }

    public String toString() {
        return "{"+_book+" "+_operation+"}";
    }
}
