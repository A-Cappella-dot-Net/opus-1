package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.MarketStatusObjDecoder;
import sbe.generated.MarketStatusObjEncoder;

public class MarketStatusCoder extends AeronCoderImpl<MarketStatusObj> {

    private final MarketStatusObjEncoder ENCODER = new MarketStatusObjEncoder();
    private static final MarketStatusObjDecoder DECODER = new MarketStatusObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public MarketStatusCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setEcn(DECODER.ecn());
        _obj.setGwt(EnumConverters.convert(DECODER.gwt()));
    }
    @Override
    public void decodeBody() {
        _obj.setStatus(EnumConverters.convert(DECODER.status()));
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .ecn(_obj.getEcn())
                .gwt(EnumConverters.convert(_obj.getGwt()))
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .status(EnumConverters.convert(_obj.getStatus()))
                .ts(_obj.getTs())
        ;
    }
}
