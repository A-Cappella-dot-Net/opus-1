package net.a_cappella.continuo.msg;

import net.a_cappella.continuo.collective.AppInfo;
import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.ObjectManagerTestUtils;
import net.a_cappella.continuo.managed.Pool;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

public class MsgCoderTest {
    private static final Logger log = LoggerFactory.getLogger(MsgCoderTest.class);

    private final MsgCoder _coder = new MsgCoder();

    public MsgCoderTest() {
        try {
            MsgInstantiator registrationRequestInstantiator =
                    new MsgInstantiator(RegistrationRequest.class.getName());
            MsgInstantiator registrationResponseInstantiator =
                    new MsgInstantiator(RegistrationResponse.class.getName());
            MsgInstantiator bytesInstantiator =
                    new MsgInstantiator(Bytes.class.getName(), List.of(Integer.class.getName()), List.of("1024"));
            List<MsgInstantiator> msgInstantiators = Arrays.asList(
                    registrationRequestInstantiator,
                    registrationResponseInstantiator,
                    bytesInstantiator);

            List<Pool<?>> pools = Arrays.asList(
                    new Pool<Msg>(registrationRequestInstantiator, 20, 10),
                    new Pool<Msg>(registrationResponseInstantiator, 20, 10),
                    new Pool<Msg>(bytesInstantiator, 20, 10));

            ObjectManager objectManager = ObjectManager.getInstance();
            objectManager.setMsgInstantiators(msgInstantiators);
            objectManager.setMsgPools(pools);

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    private final RegistrationRequest _msg0 = new RegistrationRequest(new AppInfo("b-1_0@a:0"), 100);
    private final RegistrationResponse _msg1 = new RegistrationResponse('z');
    private final Bytes _msg2 = new Bytes("ABC");

    private final Msg[] _first0 = new Msg[] {};
    private final Msg[] _last3 = new Msg[] {_msg0, _msg1, _msg2};
    private final Msg[] _first1 = new Msg[] {_msg0};
    private final Msg[] _last2 = new Msg[] {_msg1, _msg2};
    private final Msg[] _first2 = new Msg[] {_msg0, _msg1};
    private final Msg[] _last1 = new Msg[] {_msg2};
    private final Msg[] _first3 = new Msg[] {_msg0, _msg1, _msg2};
    private final Msg[] _last0 = new Msg[] {};


    private ByteBuffer _buffer;
    private final List<Msg> _firstMMsgs = new ArrayList<>();
    private final List<Msg> _lastMMsgs = new ArrayList<>();

    @BeforeEach
    public void setUp() {
        Msg[] msgs = new Msg[] {_msg0, _msg1, _msg2};
        _buffer = ByteBuffer.allocate(256);
        _buffer.clear();
        _coder.encode(msgs, _buffer);
        _buffer.flip();

        log.info(Arrays.toString(msgs)+" => ");
    }

    private void partialRead(int n, int lim, ByteBuffer buffer) {
        buffer.put(_buffer.array(), 0, n);
        buffer.flip();
        _coder.decode(buffer, _firstMMsgs);
        Msg[] firstMsgs = getMsgs(_firstMMsgs);
        buffer.compact();
        buffer.put(_buffer.array(), n, lim-n);
        buffer.flip();
        _coder.decode(buffer, _lastMMsgs);
        Msg[] lastMsgs = getMsgs(_lastMMsgs);
        buffer.compact();
        // msg0:hdr:2x4[int] + bdy:(2[short]+2[char]x1)("b")+(2[short])(!hasConn)+2[short]+8[long]+2[char] = 26
        // msg1:hdr:2x4[int] + bdy:+2[char] = 10
        // msg3:hdr:2x4[int] + bdy:3x1[byte] = 11
        if (n<26) {
            assertArrayEquals(_first0, firstMsgs);
            assertArrayEquals(_last3, lastMsgs);
        } else if (n<36) {
            assertArrayEquals(_first1, firstMsgs);
            assertArrayEquals(_last2, lastMsgs);
        } else if (n<47) { //
            assertArrayEquals(_first2, firstMsgs);
            assertArrayEquals(_last1, lastMsgs);
        } else {
            assertArrayEquals(_first3, firstMsgs);
            assertArrayEquals(_last0, lastMsgs);
        }
        log.info(" => n = "+n+" "+Arrays.toString(firstMsgs)+" "+Arrays.toString(lastMsgs));

        stopUsing(_firstMMsgs);
        _firstMMsgs.clear();
        stopUsing(_lastMMsgs);
        _lastMMsgs.clear();
    }
    private Msg[] getMsgs(List<Msg> list) {
        Msg[] msgs = new Msg[list.size()];
        for (int i=0; i<list.size(); i++) {
            Msg msg = list.get(i);
            msgs[i] = msg;
        }
        return msgs;
    }
    private void stopUsing(List<Msg> msgs) {
        for (int i=0; i<msgs.size(); i++) {
            Msg msg = msgs.get(i);
            if (msg!=null) {
                msg.stopUsing();
            }
        }
    }

    @Test
    public void allPartialReadCombinations() {
        ByteBuffer buffer = ByteBuffer.allocate(256);
        int lim = _buffer.limit();

        for (int n=1; n<=lim; n++) {
            partialRead(n, lim, buffer);
        }

        ObjectManagerTestUtils.checkPools();
    }

}
