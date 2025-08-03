package net.a_cappella.cembalo.generator;

import java.util.HashMap;
import java.util.Map;

public class StringFieldDef extends FieldDef {
    // _type == 'S'
    public Map<String, String> _values = null;

    public StringFieldDef(String[] comps) {
        super(comps);
        if (comps.length>2) {
            _values = new HashMap<>();
            String[] valNames = comps[2].split(",");
            for (String valName : valNames) {
                String[] valNam = valName.split("=");
                String val = valNam[0];
                String name = valNam[1];
                _values.put(val, name);
            }
        }
    }

    public String valuesToString() {
        return (_values==null)?"":("|"+_values);
    }
}
