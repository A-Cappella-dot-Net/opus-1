package net.a_cappella.cembalo.generator;

import gnu.trove.map.TCharObjectMap;
import gnu.trove.map.hash.TCharObjectHashMap;

public class CharFieldDef extends FieldDef {
    // _type == 'C'
    public TCharObjectMap<String> _values;

    public CharFieldDef(String[] comps) {
        super(comps);
        if (comps.length>2) {
            _values = new TCharObjectHashMap<>();
            String[] valNames = comps[2].split(",");
            for (String valName : valNames) {
                String[] valNam = valName.split("=");
                char val = valNam[0].charAt(0);
                String name = valNam[1];
                _values.put(val, name);
            }
        }
    }

    public String valuesToString() {
        return (_values==null)?"":("|"+_values);
    }
}
