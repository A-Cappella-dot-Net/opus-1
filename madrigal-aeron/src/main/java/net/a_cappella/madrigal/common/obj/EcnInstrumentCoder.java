package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.EcnInstrumentObjDecoder;
import sbe.generated.EcnInstrumentObjEncoder;

public class EcnInstrumentCoder extends AeronCoderImpl<EcnInstrumentObj> {

    private final EcnInstrumentObjEncoder ENCODER = new EcnInstrumentObjEncoder();
    private static final EcnInstrumentObjDecoder DECODER = new EcnInstrumentObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnInstrumentCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setSecurityID(DECODER.securityID());
        _obj.setSymbol(DECODER.symbol());
        _obj.setEcn(DECODER.ecn());
    }
    @Override
    public void decodeBody() {
        _obj.setMaturityDate(DECODER.maturityDate());
        _obj.setCouponRate(DECODER.couponRate());
        _obj.setContractMultiplier(DECODER.contractMultiplier());
        _obj.setMinPriceIncrement(DECODER.minPriceIncrement());
        _obj.setMinQty(DECODER.minQty());
        _obj.setMinQtyIncrement(DECODER.minQtyIncrement());
        _obj.setTs(DECODER.ts());
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .securityID(_obj.getSecurityID())
                .symbol(_obj.getSymbol())
                .ecn(_obj.getEcn())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .maturityDate(_obj.getMaturityDate())
                .couponRate(_obj.getCouponRate())
                .contractMultiplier(_obj.getContractMultiplier())
                .minPriceIncrement(_obj.getMinPriceIncrement())
                .minQty(_obj.getMinQty())
                .minQtyIncrement(_obj.getMinQtyIncrement())
                .ts(_obj.getTs())
        ;
    }
}
