package net.a_cappella.continuo.managed;

import java.util.List;

public class ObjectInitializer {

    public ObjectInitializer() {}

    public void setMsgInstantiators(List<MsgInstantiator> instantiatorsList) {
        ObjectManager.getInstance().setMsgInstantiators(instantiatorsList);
    }

    public void setMsgPools(List<Pool<?>> poolsList) {
        ObjectManager.getInstance().setMsgPools(poolsList);
    }
}
