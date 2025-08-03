package net.a_cappella.continuo.msg;

import java.nio.ByteBuffer;

import static net.a_cappella.continuo.PrestoConstants.REGISTRATION_RESPONSE;

public class RegistrationResponse extends Msg {

    public char _outcome;

    public RegistrationResponse() {
        this(' ');
    }

    public RegistrationResponse(char outcome) {
        _outcome = outcome;
    }

    @Override
    public int getMsgType() {
        return REGISTRATION_RESPONSE;
    }

    @Override
    public void encode(ByteBuffer buffer) {
        buffer.putChar(_outcome);
    }

    @Override
    public Msg decode(ByteBuffer buffer, int len) {
        _outcome = buffer.getChar();
        return this;
    }

    @Override
    public void reset() {
        _outcome = ' ';
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof RegistrationResponse)) {
            return false;
        }
        RegistrationResponse other = (RegistrationResponse) obj;
        return _outcome == other._outcome;
    }

    @Override
    public int hashCode() {
        return _outcome;
    }

    @Override
    public String toString() {
        return String.valueOf(_outcome);
    }
}
