package net.a_cappella.presto.obj;

import net.a_cappella.presto.ft.constants.FtMsgOp;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.FtMemberObjDecoder;
import sbe.generated.FtMemberObjEncoder;
import sbe.generated.FtMsgOpEnum;

public class FtMemberCoder extends AeronCoderImpl<FtMemberObj> {
    private final FtMemberObjEncoder ENCODER = new FtMemberObjEncoder();
    private static final FtMemberObjDecoder DECODER = new FtMemberObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public FtMemberCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .groupName(_obj.getGroupName())
                .instance(_obj.getInstance());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .action(convert(_obj.getAction()))
                .sliceNo(_obj.getSliceNo())
                .ofSlices(_obj.getOfSlices())
                .ts(_obj.getTs())
        ;
    }

    @Override
    public void decodeKeys() {
        _obj.setGroupName(DECODER.groupName());
        _obj.setInstance(DECODER.instance());
    }
    @Override
    public void decodeBody() {
        _obj.setAction(convert(DECODER.action()));
        _obj.setSliceNo(DECODER.sliceNo());
        _obj.setOfSlices(DECODER.ofSlices());
        _obj.setTs(DECODER.ts());
    }




    private FtMsgOpEnum convert(FtMsgOp op) {
        switch (op) {
            case ACTIVATE: return FtMsgOpEnum.ACTIVATE;
            case DEACTIVATE: return FtMsgOpEnum.DEACTIVATE;
            case DISCONNECT: return FtMsgOpEnum.DISCONNECT;
            case DUPLICATE: return FtMsgOpEnum.DUPLICATE;
            default: return FtMsgOpEnum.NULL_VAL;
        }
    }
    private FtMsgOp convert(FtMsgOpEnum op) {
        switch (op) {
            case ACTIVATE: return FtMsgOp.ACTIVATE;
            case DEACTIVATE: return FtMsgOp.DEACTIVATE;
            case DISCONNECT: return FtMsgOp.DISCONNECT;
            case DUPLICATE: return FtMsgOp.DUPLICATE;
            default: return FtMsgOp.NONE;
        }
    }
}
