package net.a_cappella.cembalo.generator;

import java.util.List;

public class MsgDef {
    private String _msgType;
    private String _name;
    private List<FieldDef> _fields;

    public MsgDef(String msgType, String name, List<FieldDef> fields) {
        _msgType = msgType;
        _name = name;
        _fields = fields;
    }

    public String getMsgType() {
        return _msgType;
    }
    public void setMsgType(String msgType) {
        _msgType = msgType;
    }

    public String getName() {
        return _name;
    }
    public void setName(String name) {
        _name = name;
    }

    public List<FieldDef> getFields() {
        return _fields;
    }
    public void setFields(List<FieldDef> fields) {
        _fields = fields;
    }

    public String toString() {
        return "{"+_msgType+"="+_name+"|"+_fields+"}";
    }
}
