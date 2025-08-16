package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.PingObjDecoder;
import sbe.generated.PingObjEncoder;

public class PingCoder extends AeronCoderImpl<PingObj> {
    private final PingObjEncoder ENCODER = new PingObjEncoder();
    private static final PingObjDecoder DECODER = new PingObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public PingCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setId(DECODER.id());
    }
    @Override
    public void decodeBody() {
        _obj.setPayload(DECODER.payload());
    }

    @Override
    public void encodeKeys() {
        ENCODER.id(_obj.getId());
    }
    @Override
    public void encodeBody() {
        ENCODER.payload(_obj.getPayload());
    }
}
