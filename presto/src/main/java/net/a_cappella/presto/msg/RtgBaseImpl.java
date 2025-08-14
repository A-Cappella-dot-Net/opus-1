package net.a_cappella.presto.msg;

import net.a_cappella.continuo.msg.Rtg;

public abstract class RtgBaseImpl implements Rtg {
    protected String _originClient;

    @Override
    public void setOriginClient(String originClient) {
        _originClient = originClient;
    }
    @Override
    public String getOriginClient() {
        return _originClient;
    }
}
