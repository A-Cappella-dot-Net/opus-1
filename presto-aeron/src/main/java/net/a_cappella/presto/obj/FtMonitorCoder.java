package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.FtMonitorObjDecoder;
import sbe.generated.FtMonitorObjEncoder;

public class FtMonitorCoder extends AeronCoderImpl<FtMonitorObj> {
    private final FtMonitorObjEncoder ENCODER = new FtMonitorObjEncoder();
    private static final FtMonitorObjDecoder DECODER = new FtMonitorObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public FtMonitorCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER.groupName(_obj.getGroupName());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .actives(_obj.getActives())
                .ts(_obj.getTs());
    }

    @Override
    public void decodeKeys() {
        _obj.setGroupName(DECODER.groupName());
    }
    @Override
    public void decodeBody() {
        _obj.setActives(DECODER.actives());
        _obj.setTs(DECODER.ts());
    }

}
