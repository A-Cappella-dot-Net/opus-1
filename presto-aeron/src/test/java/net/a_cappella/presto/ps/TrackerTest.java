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

package net.a_cappella.presto.ps;

import org.agrona.concurrent.UnsafeBuffer;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.nio.ByteBuffer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

public class TrackerTest {
    ArgumentCaptor<UnsafeBuffer> _bufferCaptor = ArgumentCaptor.forClass(UnsafeBuffer.class);

    private final AeronSerializer.RequestFragmentHandler _handler = mock(AeronSerializer.RequestFragmentHandler.class);
    private final UnsafeBuffer _buffer = new UnsafeBuffer(ByteBuffer.allocateDirect(20));

    private Tracker _tracker;

    @Test
    public void circularListNormalOrder() {
        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 2L, null);

        assertEquals(2, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 3L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 4L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());
    }

    @Test
    public void circularListReversedOrder() {
        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, null);
        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(2, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 3L, null);
        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 4L, null);
        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());
    }

    @Test
    public void circularListMixedOrder() {
        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(2, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 3L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 4L, null);
        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());
    }


    @Test
    public void startupWithOneLostRequest() {
        // response being lost results in list becoming 'full' but the 'not matched' message
        // gets overwritten at some point and normal processing occurs thereafter

        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

//    	_tracker.onMsg(_buffer, 0, 20, 1L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(0, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 3L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 4L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

    }

    @Test
    public void startupWithOneLostResponse() {
        // response being lost results in list becoming 'full' but the 'not matched' message
        // gets overwritten at some point and normal processing occurs thereafter

        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);
//    	_tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(0, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 3L, null);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 4L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

    }


    @Test
    public void onActivationNothingToSerialize() {
        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(2, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _tracker.onActivate();

        verify(_handler, never()).serialize(any(UnsafeBuffer.class), anyInt(), anyInt());
    }

    @Test
    public void onActivationTwoRecordsToSerialize() {
        _tracker = new Tracker(3, 20);

        assertEquals(0, _tracker.getOldest());
        assertEquals(2, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 1L, _handler);
        _tracker.onMsg(_buffer, 0, 20, 1L, null);

        assertEquals(1, _tracker.getOldest());
        assertEquals(0, _tracker.getNewest());

        _tracker.onMsg(_buffer, 0, 20, 2L, null);
        _tracker.onMsg(_buffer, 0, 20, 2L, _handler);

        assertEquals(2, _tracker.getOldest());
        assertEquals(1, _tracker.getNewest());

        _buffer.putStringUtf8(0, "abc");
        _tracker.onMsg(_buffer, 0, 20, 3L, _handler);

        _buffer.putStringUtf8(0, "xyz");
        _tracker.onMsg(_buffer, 0, 20, 4L, _handler);

        _tracker.onActivate();

        verify(_handler, times(2)).serialize(any(UnsafeBuffer.class), anyInt(), anyInt());
        verify(_handler).serialize(argThat((UnsafeBuffer b) -> "abc".equals(b.getStringUtf8(0))), eq(0), eq(20));
        verify(_handler).serialize(argThat((UnsafeBuffer b) -> "xyz".equals(b.getStringUtf8(0))), eq(0), eq(20));

    }

}
