package net.a_cappella.presto.ps;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.PingCoder;
import net.a_cappella.presto.obj.PingObj;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;

public class MsgAccumulatorTest {
    private static final Logger log = LoggerFactory.getLogger(MsgAccumulatorTest.class);

    private final MsgAccumulator _msgAcc = new MsgAccumulator();

    private final SnSHandler _handler1 = mock(SnSHandler.class);
    private final SnSHandler _handler2 = mock(SnSHandler.class);
    private final SnSHandler _handler3 = mock(SnSHandler.class);

    private Pool<Obj> _pool;
    {
        ObjectManager objectManager = ObjectManager.getInstance();
        try {
            _pool = new Pool<>(new MsgInstantiator(PingObj.class.getName(), PingCoder.class.getName(), null), 10, 10);
            objectManager.setMsgPools(Arrays.asList(_pool));
        } catch (Exception e) {
            log.error("", e);
        }
    }

    private PingObj newPing(int id, long payload) {
        PingObj ping = ObjectManager.getInstance().acquire(PingObj.class);
        ping.setId(id);
        ping.setPayload(payload);
        return ping;
    }

    private boolean samePing(PingObj p1, PingObj p2) {
        return p1.getId() == p2.getId() && p1.getPayload() == p2.getPayload();
    }

    @Test
    public void accumulatorTest() {
        assertEquals(10, _pool.getAvailableObjectsCount());

        PingObj ping11 = newPing(1, 1);
        PingObj ping12 = newPing(1, 2);
        PingObj ping13 = newPing(1, 3);
        PingObj ping21 = newPing(2, 1);
        PingObj ping22 = newPing(2, 2);
        PingObj ping23 = newPing(2, 3);
        PingObj ping31 = newPing(3, 1);
        PingObj ping32 = newPing(3, 2);
        PingObj ping33 = newPing(3, 3);

        // messages acquired from pool
        assertEquals(1, ping11.getNumUsers());
        assertEquals(1, ping12.getNumUsers());
        assertEquals(1, ping13.getNumUsers());
        assertEquals(1, ping21.getNumUsers());
        assertEquals(1, ping22.getNumUsers());
        assertEquals(1, ping23.getNumUsers());
        assertEquals(1, ping31.getNumUsers());
        assertEquals(1, ping32.getNumUsers());
        assertEquals(1, ping33.getNumUsers());

        assertTrue(_msgAcc.isEmpty());

        _msgAcc.accumulate(_handler1, ping11); // final
        _msgAcc.accumulate(_handler2, ping11); // superseded
        _msgAcc.accumulate(_handler3, ping11); // superseded

        _msgAcc.accumulate(_handler2, ping12); // superseded
        _msgAcc.accumulate(_handler3, ping12); // superseded

        _msgAcc.accumulate(_handler2, ping13); // final
        _msgAcc.accumulate(_handler3, ping13); // final

        _msgAcc.accumulate(_handler1, ping21); // superseded
        _msgAcc.accumulate(_handler2, ping21); // superseded
        _msgAcc.accumulate(_handler3, ping21); // superseded

        _msgAcc.accumulate(_handler1, ping22); // final
        _msgAcc.accumulate(_handler2, ping22); // final
        _msgAcc.accumulate(_handler3, ping22); // superseded

        _msgAcc.accumulate(_handler3, ping23); // final

        _msgAcc.accumulate(_handler1, ping31); // superseded
        _msgAcc.accumulate(_handler2, ping31); // final
        _msgAcc.accumulate(_handler3, ping31); // superseded

        _msgAcc.accumulate(_handler1, ping32); // superseded
        _msgAcc.accumulate(_handler3, ping32); // superseded

        _msgAcc.accumulate(_handler1, ping33); // final
        _msgAcc.accumulate(_handler3, ping33); // final

        assertEquals(2, ping11.getNumUsers());
        assertEquals(1, ping12.getNumUsers());
        assertEquals(3, ping13.getNumUsers());
        assertEquals(1, ping21.getNumUsers());
        assertEquals(3, ping22.getNumUsers());
        assertEquals(2, ping23.getNumUsers());
        assertEquals(2, ping31.getNumUsers());
        assertEquals(1, ping32.getNumUsers());
        assertEquals(3, ping33.getNumUsers());

        InOrder inOrder = inOrder(_handler1, _handler2, _handler3);
        _msgAcc.notifyAndReset();

        assertTrue(_msgAcc.isEmpty());

        // all objects have been released
        assertEquals(1, ping11.getNumUsers());
        assertEquals(1, ping12.getNumUsers());
        assertEquals(1, ping13.getNumUsers());
        assertEquals(1, ping21.getNumUsers());
        assertEquals(1, ping22.getNumUsers());
        assertEquals(1, ping23.getNumUsers());
        assertEquals(1, ping31.getNumUsers());
        assertEquals(1, ping32.getNumUsers());
        assertEquals(1, ping33.getNumUsers());

        inOrder.verify(_handler1).onMsg(argThat((PingObj p) -> samePing(p, ping11)));
        inOrder.verify(_handler2).onMsg(argThat((PingObj p) -> samePing(p, ping13)));
        inOrder.verify(_handler3).onMsg(argThat((PingObj p) -> samePing(p, ping13)));

        inOrder.verify(_handler1).onMsg(argThat((PingObj p) -> samePing(p, ping22)));
        inOrder.verify(_handler2).onMsg(argThat((PingObj p) -> samePing(p, ping22)));
        inOrder.verify(_handler3).onMsg(argThat((PingObj p) -> samePing(p, ping23)));

        inOrder.verify(_handler2).onMsg(argThat((PingObj p) -> samePing(p, ping31)));
        inOrder.verify(_handler1).onMsg(argThat((PingObj p) -> samePing(p, ping33)));
        inOrder.verify(_handler3).onMsg(argThat((PingObj p) -> samePing(p, ping33)));

        inOrder.verifyNoMoreInteractions();

        ping11.stopUsing();
        ping12.stopUsing();
        ping13.stopUsing();

        ping21.stopUsing();
        ping22.stopUsing();
        ping23.stopUsing();

        ping31.stopUsing();
        ping32.stopUsing();
        ping33.stopUsing();

        assertEquals(0, _pool.getUsedCellsCount());
        assertEquals(10, _pool.getAvailableObjectsCount());
    }

}
