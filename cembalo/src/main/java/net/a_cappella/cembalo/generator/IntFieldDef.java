package net.a_cappella.cembalo.generator;

import gnu.trove.map.TLongObjectMap;
import gnu.trove.map.hash.TLongObjectHashMap;

public class IntFieldDef extends FieldDef {
    // _type == 'I'
    public TLongObjectMap<String> _values = null;

    public IntFieldDef(String[] comps) {
        super(comps);
        if (comps.length>2) {
            _values = new TLongObjectHashMap<>();
            String[] valNames = comps[2].split(",");
            for (String valName : valNames) {
                String[] valNam = valName.split("=");
                long val = Long.parseLong(valNam[0]);
                String name = valNam[1];
                _values.put(val, name);
            }
        }
    }

    public String valuesToString() {
        return (_values==null)?"":("|"+_values);
    }
}
