package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.CacheCmdObjDecoder;
import sbe.generated.CacheCmdObjEncoder;

public class CacheCmdCoder extends AeronCoderImpl<CacheCmdObj> {
    private final CacheCmdObjEncoder ENCODER = new CacheCmdObjEncoder();
    private static final CacheCmdObjDecoder DECODER = new CacheCmdObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public CacheCmdCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .command(_obj.getCommand())
                .cacheSubject(_obj.getCacheSubject());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .whereClause(_obj.getWhereClause());
    }

    @Override
    public void decodeKeys() {
        _obj.setCommand(DECODER.command());
        _obj.setCacheSubject(DECODER.cacheSubject());
    }
    @Override
    public void decodeBody() {
        _obj.setWhereClause(DECODER.whereClause());
    }
}
