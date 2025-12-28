package net.a_cappella.devtools.obj;

import net.a_cappella.presto.obj.AeronCoderImpl;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;
import sbe.generated.WebSocketMsgObjDecoder;
import sbe.generated.WebSocketMsgObjEncoder;

public class WebSocketMsgCoder extends AeronCoderImpl<WebSocketMsgObj> {

    private final WebSocketMsgObjEncoder ENCODER = new WebSocketMsgObjEncoder();
    private static final WebSocketMsgObjDecoder DECODER = new WebSocketMsgObjDecoder();

    public MessageEncoderFlyweight getEncoder() { return ENCODER; }
    public MessageDecoderFlyweight getDecoder() { return DECODER; }


    public WebSocketMsgCoder() {
    }

    @Override
    public void encodeKeys() {
        ENCODER
                .remote(_obj.getRemote());
    }
    @Override
    public void encodeBody() {
        ENCODER
                .msg(_obj.getMsg());
    }

    @Override
    public void decodeKeys() {
        _obj.setRemote(DECODER.remote());
    }
    @Override
    public void decodeBody() {
        _obj.setMsg(DECODER.msg());
    }

}
