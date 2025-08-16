package net.a_cappella.presto.ps;

import net.a_cappella.continuo.obj.Coder;
import org.agrona.MutableDirectBuffer;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.agrona.sbe.MessageEncoderFlyweight;

public interface AeronCoder extends Coder {

    MessageEncoderFlyweight getEncoder();
    MessageDecoderFlyweight getDecoder();

    void decodeKeys();
    void decodeBody();
    void decodeAdHocs();

    void encodeKeys();
    void encodeBody();
    int encodeAdHocs();

    int encodeObj(final MutableDirectBuffer buffer, int offset);
}
