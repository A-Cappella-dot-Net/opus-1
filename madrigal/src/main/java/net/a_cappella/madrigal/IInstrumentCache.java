package net.a_cappella.madrigal;

import net.a_cappella.madrigal.common.obj.EcnInstrumentObj;

public interface IInstrumentCache {
    String getEcnInstrId(String instrId);
    EcnInstrumentObj getEcnInstr(String instrId);
}
