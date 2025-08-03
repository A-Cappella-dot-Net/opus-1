package net.a_cappella.cembalo.generator;

import gnu.trove.map.TDoubleObjectMap;
import gnu.trove.map.hash.TDoubleObjectHashMap;

public class FloatFieldDef extends FieldDef {
    // _type == 'F'
    public TDoubleObjectMap<String> _values;

    public FloatFieldDef(String[] comps) {
        super(comps);
        if (comps.length>2) {
            _values = new TDoubleObjectHashMap<>();
            String[] valNames = comps[2].split(",");
            for (String valName : valNames) {
                String[] valNam = valName.split("=");
                double val = Double.parseDouble(valNam[0]);
                String name = valNam[1];
                _values.put(val, name);
            }
        }
    }

    public String valuesToString() {
        return (_values==null)?"":("|"+_values);
    }
}
