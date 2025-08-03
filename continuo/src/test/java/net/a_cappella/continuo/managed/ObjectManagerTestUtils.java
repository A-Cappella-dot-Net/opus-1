package net.a_cappella.continuo.managed;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class ObjectManagerTestUtils {
    protected static Logger log = LoggerFactory.getLogger(ObjectManagerTestUtils.class);

    public static void checkPools() {
        for (Pool<?> pool : ObjectManager.getInstance().getPools()) {
            checkNumUsersAndLength(pool.getInstantiator(), pool.getAvailableObjects(), true, 20);
            checkNumUsersAndLength(pool.getInstantiator(), pool.getUsedCells(), false, 0);
        }
    }
    private static void checkNumUsersAndLength(MsgInstantiator instantiator, Pool.ListCell<?> cell, boolean hasObject, int expectedLen) {
        int len = 0;
        while (cell!=null) {
            len++;
            IPoolable obj = cell.getObj();
            assertEquals(hasObject, obj != null);
            if (obj!=null) {
                if (0!=obj.getNumUsers()) {
                    String err = instantiator+" =====> ["+obj.getNumUsers()+"] obj="+obj;
                    log.info(err);
                    System.out.println(err);
                }
                assertEquals(0, obj.getNumUsers());
            }
            cell = cell.getNext();
        }
        if (expectedLen!=len) {
            String err = instantiator+" =====> expected="+expectedLen+" actual="+len;
            log.info(err);
            System.out.println(err);
        }
        assertEquals(expectedLen, len);
    }
}
