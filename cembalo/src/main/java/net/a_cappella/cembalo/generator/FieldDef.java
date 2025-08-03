package net.a_cappella.cembalo.generator;

import java.util.List;

public class FieldDef {
    public int _tag;
    public String _name;
    public char _type;
    public List<FieldDef> _group;

    public FieldDef(String[] comps) {
        String[] tagName = comps[0].split("=");
        _tag = Integer.parseInt(tagName[0]);
        _name = tagName[1];
        _type = comps[1].charAt(0);
    }

    public String valuesToString() {
        return "";
    }

    public String toString() {
        String group = (_group==null)?"":(" => "+_group);
        return _tag+"="+_name+"|"+_type+valuesToString()+group;
    }
}
