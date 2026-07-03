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

package net.a_cappella.continuo.msg;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InvalidClassException;
import java.io.ObjectInputFilter;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Date;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

/**
 * Verifies the allow-list {@link ObjectInputFilter} guarding the base
 * {@link Msg#decode(ByteBuffer, int)} Java-serialization path, including the "extend the baseline"
 * semantics of {@link Msg#SERIAL_FILTER_PROPERTY}.
 */
public class MsgDeserializationFilterTest {

    /** A legitimate project message (net.a_cappella.*) must still round-trip through the base path. */
    @Test
    public void allowsProjectMessageClass() {
        TestMsg original = new TestMsg();
        original.setTimeNanos(1_234_567L);

        ByteBuffer buffer = ByteBuffer.allocate(1024);
        original.encode(buffer);
        int len = buffer.position();
        buffer.flip();

        Msg decoded = new TestMsg().decode(buffer, len);

        assertInstanceOf(TestMsg.class, decoded);
        assertEquals(1_234_567L, ((TestMsg) decoded).getTimeNanos());
    }

    /**
     * A serializable class outside the allow-list (here {@link File}, standing in for a gadget
     * class) must be refused by the default (baseline) filter: {@code readObject} throws and
     * {@code decode} returns {@code null} instead of instantiating the class.
     */
    @Test
    public void rejectsNonAllowListedClass() throws Exception {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (ObjectOutputStream out = new ObjectOutputStream(bos)) {
            out.writeObject(new File("/etc/passwd"));
        }
        byte[] payload = bos.toByteArray();

        ByteBuffer buffer = ByteBuffer.allocate(payload.length + 16);
        buffer.put(payload);
        buffer.flip();

        Msg decoded = new TestMsg().decode(buffer, payload.length);

        assertNull(decoded, "non-allow-listed class must be rejected by the deserialization filter");
    }

    /**
     * Configured additions <em>extend</em> the baseline: a class named in the additions is allowed,
     * while a class in neither the baseline nor the additions is still rejected — proving the
     * reject-all is appended after the additions rather than replacing them.
     */
    @Test
    public void additionsExtendBaselineWithoutWeakeningIt() throws Exception {
        ObjectInputFilter filter = Msg.buildFilter("java.util.Date");

        // java.util.Date is not in the baseline, but is now permitted as an addition
        Object allowed = roundTrip(new Date(0L), filter);
        assertEquals(new Date(0L), allowed);

        // java.io.File is in neither the baseline nor the additions, so it stays rejected
        assertThrows(InvalidClassException.class, () -> roundTrip(new File("/etc/passwd"), filter));
    }

    /** A malformed additions value must fail safe to the baseline allow-list, not to no filter. */
    @Test
    public void invalidAdditionsFallBackToBaseline() throws Exception {
        ObjectInputFilter filter = Msg.buildFilter("maxdepth=not-a-number");

        // baseline still enforced: net.a_cappella message decodes, arbitrary class is rejected
        assertThrows(InvalidClassException.class, () -> roundTrip(new File("/etc/passwd"), filter));
    }

    /**
     * The baseline allow-list intentionally lists no JDK class. That is only safe because pool
     * bookkeeping — including the {@code AtomicInteger} user counter — lives in
     * {@link net.a_cappella.continuo.managed.Poolable}, which is not {@link java.io.Serializable} and
     * so is never written to the stream. This guards that assumption: if {@code Poolable} were ever
     * made serializable, {@code AtomicInteger} would start appearing on the wire (and the baseline
     * filter would begin rejecting legitimate messages), and this test would flag it first.
     */
    @Test
    public void poolBookkeepingIsNotSerialized() throws Exception {
        TestMsg m = new TestMsg();
        m.setTimeNanos(7L);

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (ObjectOutputStream out = new ObjectOutputStream(bos)) {
            out.writeObject(m);
        }
        String stream = new String(bos.toByteArray(), StandardCharsets.ISO_8859_1);

        assertFalse(stream.contains("AtomicInteger"), "pool user-counter must not be serialized");
        assertFalse(stream.contains("Poolable"), "non-serializable pool superclass must not appear in the stream");
    }

    private static Object roundTrip(Object obj, ObjectInputFilter filter) throws Exception {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (ObjectOutputStream out = new ObjectOutputStream(bos)) {
            out.writeObject(obj);
        }
        ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bos.toByteArray()));
        in.setObjectInputFilter(filter);
        return in.readObject();
    }
}
