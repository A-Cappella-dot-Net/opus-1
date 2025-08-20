package net.a_cappella.madrigal.common.obj;

import net.a_cappella.madrigal.common.constants.MadrigalOrdStatus;
import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.OrderObjDecoder;
import sbe.generated.OrderObjEncoder;
import sbe.generated.SbeBoolean;

import static net.a_cappella.madrigal.common.constants.MadrigalMode.REQUEST;

public class OrderCoder extends AeronCoderImpl<OrderObj> {

    private final OrderObjEncoder ENCODER = new OrderObjEncoder();
    private static final OrderObjDecoder DECODER = new OrderObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }

    public OrderCoder() {
    }

    @Override
    public void decodeKeys() {
        _obj.setMadrigalMode(EnumConverters.convert(DECODER.mode()));
        _obj.setEcn(DECODER.ecn());
        _obj.setUid(DECODER.uid());
        _obj.setOrdId(DECODER.ordId());
        _obj.setInstrId(DECODER.instrId());
    }
    @Override
    public void decodeBody() {
        _obj.setVer(DECODER.ver());
        _obj.setClOrdId(DECODER.clOrdId());
        _obj.setOrdType(EnumConverters.convert(DECODER.ordType()));
        _obj.setTimeInForce(EnumConverters.convert(DECODER.timeInForce()));
        _obj.setSide(EnumConverters.convert(DECODER.side()));
        _obj.setPrice(DECODER.price());
        _obj.setOrderQty(DECODER.orderQty());
        _obj.setShownQty(DECODER.shownQty());
        _obj.setRandomMax(DECODER.randomMax());
        _obj.setReqType(EnumConverters.convert(DECODER.reqType()));
        _obj.setUseNative(DECODER.useNative()==SbeBoolean.TRUE);
        _obj.setTs(DECODER.ts());
        _obj.setTsx(DECODER.tsx());
        if (REQUEST == _obj.getMadrigalMode()) {
        } else {
            _obj.setEcnOrdId(DECODER.ecnOrdId());
            _obj.setFillId(DECODER.fillId());
            _obj.setExecId(DECODER.execId());
            _obj.setStatus(EnumConverters.convert(DECODER.status()));
            _obj.setLastQty(DECODER.lastQty());
            _obj.setLastPx(DECODER.lastPx());
            _obj.setLeavesQty(DECODER.leavesQty());
            _obj.setCumQty(DECODER.cumQty());
            _obj.setAvgPx(DECODER.avgPx());
            _obj.setFtDone(DECODER.ftDone()==SbeBoolean.TRUE);
            _obj.setDone(DECODER.done()==SbeBoolean.TRUE);
        	String text = DECODER.text();
            _obj.setText(text.isEmpty() ? null : text);
        }
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .mode(EnumConverters.convert(_obj.getMadrigalMode()))
                .ecn(_obj.getEcn())
                .uid(_obj.getUid())
                .ordId(_obj.getOrdId())
                .instrId(_obj.getInstrId())
        ;
    }
    @Override
    public void encodeBody() {
    	ENCODER
                .ver(_obj.getVer())
                .clOrdId(_obj.getClOrdId())
                .ordType(EnumConverters.convert(_obj.getOrdType()))
                .timeInForce(EnumConverters.convert(_obj.getTimeInForce()))
                .side(EnumConverters.convert(_obj.getSide()))
                .price(_obj.getPrice())
                .orderQty(_obj.getOrderQty())
                .shownQty(_obj.getShownQty())
                .randomMax(_obj.getRandomMax())
                .reqType(EnumConverters.convert(_obj.getReqType()))
                .useNative(_obj.isUseNative()?SbeBoolean.TRUE:SbeBoolean.FALSE)
                .ts(_obj.getTs())
                .tsx(_obj.getTsx())
        ;
//        if (RESPONSE == _obj.getMadrigalMsgType()) {
        	String text = _obj.getText();
        	String fillId = _obj.getFillId();
        	String ecnOrdId = _obj.getEcnOrdId();
        	MadrigalOrdStatus status = _obj.getStatus();
            ENCODER
            		.ecnOrdId(ecnOrdId==null?"":ecnOrdId)
            		.fillId(fillId==null?"":fillId)
            		.execId(_obj.getExecId())
                    .status(EnumConverters.convert(status==null?MadrigalOrdStatus.ACK:status))
                    .lastQty(_obj.getLastQty())
                    .lastPx(_obj.getLastPx())
                    .leavesQty(_obj.getLeavesQty())
                    .cumQty(_obj.getCumQty())
                    .avgPx(_obj.getAvgPx())
                    .ftDone(_obj.isFtDone()?SbeBoolean.TRUE:SbeBoolean.FALSE)
                    .done(_obj.isDone()?SbeBoolean.TRUE:SbeBoolean.FALSE)
                    .text(text==null?"":text)
            ;
//        }
    }
}
