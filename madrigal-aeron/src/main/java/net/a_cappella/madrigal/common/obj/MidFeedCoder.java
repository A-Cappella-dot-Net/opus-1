package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.MidFeedObjDecoder;
import sbe.generated.MidFeedObjEncoder;

public class MidFeedCoder extends AeronCoderImpl<MidFeedObj> {

    private final MidFeedObjEncoder ENCODER = new MidFeedObjEncoder();
    private static final MidFeedObjDecoder DECODER = new MidFeedObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public MidFeedCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setInstrId(DECODER.instrId());
    }
    @Override
    public void decodeBody() {
        _obj.setMid(DECODER.mid());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .instrId(_obj.getInstrId())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .mid(_obj.getMid())
                .ts(_obj.getTs())
        ;
    }
}
