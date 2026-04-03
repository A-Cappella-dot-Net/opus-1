/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.continuo.managed;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class ObjectManagerTestUtils {
    protected static Logger log = LoggerFactory.getLogger(ObjectManagerTestUtils.class);

    public static void checkPools() {
        ObjectManager.getInstance().forEachPool(pool -> {
            checkNumUsersAndLength(pool.getInstantiator(), pool.getAvailableObjects(), true, 20);
            checkNumUsersAndLength(pool.getInstantiator(), pool.getUsedCells(), false, 0);
        });
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
