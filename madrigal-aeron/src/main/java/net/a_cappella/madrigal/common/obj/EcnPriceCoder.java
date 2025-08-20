package net.a_cappella.madrigal.common.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.EcnPriceObjDecoder;
import sbe.generated.EcnPriceObjEncoder;

public class EcnPriceCoder extends AeronCoderImpl<EcnPriceObj> {

    private final EcnPriceObjEncoder ENCODER = new EcnPriceObjEncoder();
    private static final EcnPriceObjDecoder DECODER = new EcnPriceObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public EcnPriceCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setEcn(DECODER.ecn());
        _obj.setInstrId(DECODER.instrId());
    }
    @Override
    public void decodeBody() {
        _obj.setBid0(DECODER.bid0());
        _obj.setBid1(DECODER.bid1());
        _obj.setBid2(DECODER.bid2());
        _obj.setBid3(DECODER.bid3());
        _obj.setBid4(DECODER.bid4());
        _obj.setBidSize0(DECODER.bidSize0());
        _obj.setBidSize1(DECODER.bidSize1());
        _obj.setBidSize2(DECODER.bidSize2());
        _obj.setBidSize3(DECODER.bidSize3());
        _obj.setBidSize4(DECODER.bidSize4());
        _obj.setOffer0(DECODER.offer0());
        _obj.setOffer1(DECODER.offer1());
        _obj.setOffer2(DECODER.offer2());
        _obj.setOffer3(DECODER.offer3());
        _obj.setOffer4(DECODER.offer4());
        _obj.setOfferSize0(DECODER.offerSize0());
        _obj.setOfferSize1(DECODER.offerSize1());
        _obj.setOfferSize2(DECODER.offerSize2());
        _obj.setOfferSize3(DECODER.offerSize3());
        _obj.setOfferSize4(DECODER.offerSize4());
        _obj.setTs(DECODER.ts());
        _obj.setTsx(DECODER.tsx());
        _obj.setStale(EnumConverters.convert(DECODER.stale()));
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .ecn(_obj.getEcn())
                .instrId(_obj.getInstrId())
        ;
    }
    @Override
    public void encodeBody() {
        ENCODER
                .bid0(_obj.getBid0())
                .bid1(_obj.getBid1())
                .bid2(_obj.getBid2())
                .bid3(_obj.getBid3())
                .bid4(_obj.getBid4())
                .bidSize0(_obj.getBidSize0())
                .bidSize1(_obj.getBidSize1())
                .bidSize2(_obj.getBidSize2())
                .bidSize3(_obj.getBidSize3())
                .bidSize4(_obj.getBidSize4())
                .offer0(_obj.getOffer0())
                .offer1(_obj.getOffer1())
                .offer2(_obj.getOffer2())
                .offer3(_obj.getOffer3())
                .offer4(_obj.getOffer4())
                .offerSize0(_obj.getOfferSize0())
                .offerSize1(_obj.getOfferSize1())
                .offerSize2(_obj.getOfferSize2())
                .offerSize3(_obj.getOfferSize3())
                .offerSize4(_obj.getOfferSize4())
                .ts(_obj.getTs())
                .tsx(_obj.getTsx())
                .stale(EnumConverters.convert(_obj.isStale()))
        ;
    }
}
