package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.CredentialsObjDecoder;
import sbe.generated.CredentialsObjEncoder;

public class CredentialsCoder extends AeronCoderImpl<CredentialsObj> {

    private final CredentialsObjEncoder ENCODER = new CredentialsObjEncoder();
    private static final CredentialsObjDecoder DECODER = new CredentialsObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public CredentialsCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setUid(DECODER.uid());
    }
    @Override
    public void decodeBody() {
        _obj.setPwd(DECODER.pwd());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .uid(_obj.getUid())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .pwd(_obj.getPwd())
                .ts(_obj.getTs())
        ;
    }
}
