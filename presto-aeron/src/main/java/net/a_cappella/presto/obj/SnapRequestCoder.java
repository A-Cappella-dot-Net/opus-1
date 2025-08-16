package net.a_cappella.presto.obj;

import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.SnapRequestObjDecoder;
import sbe.generated.SnapRequestObjEncoder;

public class SnapRequestCoder extends AeronCoderImpl<SnapRequestObj> {
    private final SnapRequestObjEncoder ENCODER = new SnapRequestObjEncoder();
    private static final SnapRequestObjDecoder DECODER = new SnapRequestObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public SnapRequestCoder() {
    }

    @Override
    public void encodeKeys() {
    }
    @Override
    public void encodeBody() {
        String sql = _obj.getSql();
        ENCODER
                .sql(sql==null ? "" : sql)
        ;
    }

    @Override
    public void decodeKeys() {
    }
    @Override
    public void decodeBody() {
        String sql = DECODER.sql();
        _obj.setSql(sql.isEmpty() ? null : sql);
    }
}
