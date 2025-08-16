package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.SeqNoObjDecoder;
import sbe.generated.SeqNoObjEncoder;

public class SeqNoCoder extends AeronCoderImpl<SeqNoObj> {
    private final SeqNoObjEncoder ENCODER = new SeqNoObjEncoder();
    private static final SeqNoObjDecoder DECODER = new SeqNoObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public SeqNoCoder() {
    }

    @Override
    public void decodeKeys() {}

    @Override
    public void decodeBody() {
        _obj.setSeqNo(DECODER.seqNo());
    }

    @Override
    public void encodeKeys() {
    }
    @Override
    public void encodeBody() {
        ENCODER.seqNo(_obj.getSeqNo());
    }


}
