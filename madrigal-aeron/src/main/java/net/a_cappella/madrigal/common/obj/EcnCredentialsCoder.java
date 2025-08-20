package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.EcnCredentialsObjDecoder;
import sbe.generated.EcnCredentialsObjEncoder;

public class EcnCredentialsCoder extends AeronCoderImpl<EcnCredentialsObj> {

    private final EcnCredentialsObjEncoder ENCODER = new EcnCredentialsObjEncoder();
    private static final EcnCredentialsObjDecoder DECODER = new EcnCredentialsObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnCredentialsCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setUid(DECODER.uid());
        _obj.setEcn(DECODER.ecn());
    }
    @Override
    public void decodeBody() {
        _obj.setEcnUid(DECODER.ecnUid());
        _obj.setEcnPwd(DECODER.ecnPwd());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .uid(_obj.getUid())
                .ecn(_obj.getEcn())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .ecnUid(_obj.getEcnUid())
                .ecnPwd(_obj.getEcnPwd())
                .ts(_obj.getTs())
        ;
    }
}
