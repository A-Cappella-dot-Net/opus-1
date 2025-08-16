package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.SnapTimeoutObjDecoder;
import sbe.generated.SnapTimeoutObjEncoder;

public class SnapTimeoutCoder extends AeronCoderImpl<SnapTimeoutObj> {
    private final SnapTimeoutObjEncoder ENCODER = new SnapTimeoutObjEncoder();
    private static final SnapTimeoutObjDecoder DECODER = new SnapTimeoutObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public SnapTimeoutCoder() {
    }

    @Override
    public void encodeKeys() {
    }
    @Override
    public void encodeBody() {
        ENCODER.ts(_obj.getTs());
    }

    @Override
    public void decodeKeys() {
    }
    @Override
    public void decodeBody() {
        _obj.setTs(DECODER.ts());
    }
}
