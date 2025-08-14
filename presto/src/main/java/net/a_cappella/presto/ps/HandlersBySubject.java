package net.a_cappella.presto.ps;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class HandlersBySubject {
    private static final Logger log = LoggerFactory.getLogger(HandlersBySubject.class);

    private final List<String> _subjects = new ArrayList<>();
    private final List<List<SnSHandler>> _handlers = new ArrayList<>();

    public void put(String subject, SnSHandler handler) {
        int i = 0;
        while (i<_subjects.size()) {
            int cmp = subject.compareTo(_subjects.get(i));
            if (cmp==0) {
                List<SnSHandler> list = _handlers.get(i);
                list.add(handler);
                return;
            }
            if (cmp<0) {
                _subjects.add(i, subject);
                List<SnSHandler> list = new ArrayList<>();
                list.add(handler);
                _handlers.add(i, list);
                return;
            }
            i++;
        }
        _subjects.add(subject);
        List<SnSHandler> list = new ArrayList<>();
        list.add(handler);
        _handlers.add(list);
    }

    public void remove(String subject, SnSHandler handler) {
        int i = 0;
        while (i<_subjects.size()) {
            int cmp = subject.compareTo(_subjects.get(i));
            if (cmp==0) {
                List<SnSHandler> list = _handlers.get(i);
                list.remove(handler);
                return;
            }
            if (cmp<0) return; // did not find...
            i++;
        }
    }

    public List<SnSHandler> get(String subject) {
        int i = 0;
        while (i<_subjects.size()) {
            int cmp = subject.compareTo(_subjects.get(i));
            if (cmp==0) return _handlers.get(i);
            if (cmp<0) return null; // did not find...
            i++;
        }
        return null; // did not find...
    }

    public String toString() {
        String str = "";
        for (int i=0; i<_subjects.size(); i++) {
            str += _subjects.get(i)+"="+_handlers.get(i);
            if (i!=(_subjects.size()-1)) str += ",";
        }
        return "{"+str+"}";
    }
}
