package net.a_cappella.presto.ps;

import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.hash.TIntObjectHashMap;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Coder;

import java.lang.reflect.Constructor;

public class SharedCoders {
    public TIntObjectMap<Coder> _codersByObjType = new TIntObjectHashMap<>();

    public Coder getCoder(int objType) {
        Coder cod = _codersByObjType.get(objType);
        if (cod == null) {
            Constructor<? extends Coder> codCtor = ObjectManager.getInstance().getCoderConstructor(objType);
            try {
                cod = codCtor.newInstance();
                _codersByObjType.put(objType, cod);
            } catch (Exception x) {
                throw new RuntimeException("Could not create Coder object "+objType, x);
            }
        }
        return cod;
    }
}
