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

import io.aeron.Aeron;
import io.aeron.FragmentAssembler;
import io.aeron.Publication;
import io.aeron.Subscription;
import io.aeron.logbuffer.FragmentHandler;
import io.aeron.logbuffer.Header;
import net.a_cappella.continuo.ShutdownHook;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.continuo.utils.tightloop.TightLoopSnippet;
import net.a_cappella.continuo.utils.tightloop.TightLoopThread;
import net.a_cappella.presto.serializer.PrestoSerializer;
import org.agrona.DirectBuffer;
import org.agrona.concurrent.UnsafeBuffer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import sbe.generated.CombinedSbePrestoHeaderDecoder;
import sbe.generated.CombinedSbePrestoHeaderEncoder;

public class AeronSerializer implements PrestoSerializer {
    private static final Logger log = LoggerFactory.getLogger(AeronSerializer.class);

    private static final int DEFAULT_TRACKER_LIST_SIZE = 100;
    private static final int DEFAULT_TRACKER_CELL_BUFFER_SIZE = 1_024;

    /**
     * When setting _useIpcLoopback to true make sure loopback via hardware is disabled.
     * For example, if using a SolarFlare card set EF_MCAST_RECV_HW_LOOP=0.
     */
    private boolean _useIpcLoopback = false;
    public void setUseIpcLoopback(String useIpcLoopbackStr) {
        _useIpcLoopback = Boolean.parseBoolean(useIpcLoopbackStr);
    }

    private final String _ipcChannel = "aeron:ipc";
    private String _multicastChannel = "aeron:udp?endpoint=224.0.1.1:40123";
    public void setMulticastChannel(String multicastChannel) {
        _multicastChannel = Utils.parseAsString("multicastChannel", multicastChannel, _multicastChannel);
    }
    private String _unicastChannel = "aeron:udp?endpoint=localhost:40123";
    public void setUnicastChannel(String unicastChannel) {
        _unicastChannel = Utils.parseAsString("unicastChannel", unicastChannel, _unicastChannel);
    }

    private String _channel = _multicastChannel;
    public void setChannelType(String channel) {
        switch (channel) {
            case "unicast":
                _channel = _unicastChannel;
                break;
            case "multicast":
                _channel = _multicastChannel;
                break;
            case "ipc":
                _channel = _ipcChannel;
                break;
            default:
                log.error("Un recognized channel {}. Defaulting to {}", channel, _channel);
                break;
        }
    }

    private int _pubStream = 10;
    public void setPubStream(String pubStream) {
        _pubStream = Utils.parseAsInt("pubStream", pubStream, _pubStream);
    }
    private int _subStream = 10;
    public void setSubStream(String subStream) {
        _subStream = Utils.parseAsInt("subStream", subStream, _subStream);
    }

    private int _maxRead_0 = Integer.MAX_VALUE;
    public void setMaxRead0(int maxRead) {
        _maxRead_0 = maxRead;
    }
    private int _maxRead_1 = Integer.MAX_VALUE;
    public void setMaxRead1(int maxRead) {
        _maxRead_1 = maxRead;
    }
    private int _maxRead_2 = 1;
    public void setMaxRead2(int maxRead) {
        _maxRead_2 = maxRead;
    }

    private Publication _pubIpc_0;
    private Publication _pubIpc_1;
    private Publication _pubIpc_2;
    private Publication _pubMct_0;
    private Publication _pubMct_1;
    private Publication _pubMct_2;
    private Subscription _subIpc_4;
    private Subscription _subIpc_5;
    private Subscription _subIpc_6;
    private Subscription _subMct_4;
    private Subscription _subMct_5;
    private Subscription _subMct_6;

    private FragmentAssembler _assemblerIpc_4;
    private FragmentAssembler _assemblerIpc_5;
    private FragmentAssembler _assemblerIpc_6;
    private FragmentAssembler _assemblerMct_4;
    private FragmentAssembler _assemblerMct_5;
    private FragmentAssembler _assemblerMct_6;

    private Subscription _subIpc_0;
    private Subscription _subIpc_1;
    private Subscription _subIpc_2;
    private Subscription _subMct_0;
    private Subscription _subMct_1;
    private Subscription _subMct_2;

    private FragmentAssembler _assemblerIpc_0;
    private FragmentAssembler _assemblerIpc_1;
    private FragmentAssembler _assemblerIpc_2;
    private FragmentAssembler _assemblerMct_0;
    private FragmentAssembler _assemblerMct_1;
    private FragmentAssembler _assemblerMct_2;


    protected final CombinedSbePrestoHeaderDecoder HEADER_DECODER = new CombinedSbePrestoHeaderDecoder();
    protected final CombinedSbePrestoHeaderEncoder HEADER_ENCODER = new CombinedSbePrestoHeaderEncoder();

    private final Aeron _aeron;

    private TightLoopThread _tightLoopThread;
    private final PublicationHelper _pubHelper;

    private boolean _active;
    private long _seqNo;

    private final Tracker _tracker;

    private volatile boolean _stop = false;

    public AeronSerializer(TightLoopThread tightLoopThread, PublicationHelper pubHelper, String trackerListSizeStr, String trackerCellBufferSizeStr) {
        _tightLoopThread = tightLoopThread;
        _pubHelper = pubHelper;
        _aeron = Aeron.connect(new Aeron.Context());
        _tracker = new Tracker(
                Utils.parseAsInt("trackerListSize", trackerListSizeStr, DEFAULT_TRACKER_LIST_SIZE),
                Utils.parseAsInt("trackerCellBufferSize", trackerCellBufferSizeStr, DEFAULT_TRACKER_CELL_BUFFER_SIZE)
        );
    }

    public void start() {
        ShutdownHook.registerShutdownAction(() -> stop());

        if (_useIpcLoopback) {
            log.info("Channel {} & stream {}/{}", _ipcChannel, _pubStream, _subStream);
            _pubIpc_0 = _aeron.addPublication(_ipcChannel, _pubStream);
            _pubIpc_1 = _aeron.addPublication(_ipcChannel, _pubStream+1);
            _pubIpc_2 = _aeron.addPublication(_ipcChannel, _pubStream+2);

            _subIpc_4 = _aeron.addSubscription(_ipcChannel, _subStream+4);
            _subIpc_5 = _aeron.addSubscription(_ipcChannel, _subStream+5);
            _subIpc_6 = _aeron.addSubscription(_ipcChannel, _subStream+6);

            _assemblerIpc_4 = new FragmentAssembler(new RequestFragmentHandler(true, _pubIpc_0));
            _assemblerIpc_5 = new FragmentAssembler(new RequestFragmentHandler(true, _pubIpc_1));
            _assemblerIpc_6 = new FragmentAssembler(new RequestFragmentHandler(true, _pubIpc_2));

            _subIpc_0 = _aeron.addSubscription(_ipcChannel, _subStream);
            _subIpc_1 = _aeron.addSubscription(_ipcChannel, _subStream+1);
            _subIpc_2 = _aeron.addSubscription(_ipcChannel, _subStream+2);

            _assemblerIpc_0 = new FragmentAssembler(new ResponseFragmentHandler());
            _assemblerIpc_1 = new FragmentAssembler(new ResponseFragmentHandler());
            _assemblerIpc_2 = new FragmentAssembler(new ResponseFragmentHandler());
        }

        log.info("Channel {} & stream {}/{}", _channel, _pubStream, _subStream);
        _pubMct_0 = _aeron.addPublication(_channel, _pubStream+10);
        _pubMct_1 = _aeron.addPublication(_channel, _pubStream+11);
        _pubMct_2 = _aeron.addPublication(_channel, _pubStream+12);

        _subMct_4 = _aeron.addSubscription(_channel, _subStream+14);
        _subMct_5 = _aeron.addSubscription(_channel, _subStream+15);
        _subMct_6 = _aeron.addSubscription(_channel, _subStream+16);

        _assemblerMct_4 = new FragmentAssembler(new RequestFragmentHandler(false, _pubMct_0));
        _assemblerMct_5 = new FragmentAssembler(new RequestFragmentHandler(false, _pubMct_1));
        _assemblerMct_6 = new FragmentAssembler(new RequestFragmentHandler(false, _pubMct_2));

        _subMct_0 = _aeron.addSubscription(_channel, _subStream+10);
        _subMct_1 = _aeron.addSubscription(_channel, _subStream+11);
        _subMct_2 = _aeron.addSubscription(_channel, _subStream+12);

        _assemblerMct_0 = new FragmentAssembler(new ResponseFragmentHandler());
        _assemblerMct_1 = new FragmentAssembler(new ResponseFragmentHandler());
        _assemblerMct_2 = new FragmentAssembler(new ResponseFragmentHandler());

        TightLoopSnippet op = new SubscriptionDispatcher();
        _tightLoopThread.add(op);
    }

    public void stop() {
        log.info("Stopping Serializer");
        _stop = true;
        _aeron.close();
    }

    public void waitUntilInitialized() {
        log.info("Waiting for Serializer to connect");

        if (_useIpcLoopback) {
            while (!_pubIpc_0.isConnected()) if (_stop) return;
            while (!_pubIpc_1.isConnected()) if (_stop) return;
            while (!_pubIpc_2.isConnected()) if (_stop) return;
        } else {
            while (!_pubMct_0.isConnected()) if (_stop) return;
            while (!_pubMct_1.isConnected()) if (_stop) return;
            while (!_pubMct_2.isConnected()) if (_stop) return;
        }

        log.info("all publications connected...");

        if (_useIpcLoopback) {
            while (!_subIpc_4.isConnected()) if (_stop) return;
            while (!_subIpc_5.isConnected()) if (_stop) return;
            while (!_subIpc_6.isConnected()) if (_stop) return;

            while (!_subIpc_0.isConnected()) if (_stop) return;
            while (!_subIpc_1.isConnected()) if (_stop) return;
            while (!_subIpc_2.isConnected()) if (_stop) return;
        } else {
            while (!_subMct_4.isConnected()) if (_stop) return;
            while (!_subMct_5.isConnected()) if (_stop) return;
            while (!_subMct_6.isConnected()) if (_stop) return;

            while (!_subMct_0.isConnected()) if (_stop) return;
            while (!_subMct_1.isConnected()) if (_stop) return;
            while (!_subMct_2.isConnected()) if (_stop) return;
        }

        log.info("all subscriptions connected...");
    }

    @Override
    public void onActivate(long seqNo) {
        _active = true;
        _seqNo = seqNo;

        log.info("onActivate seqNo={}", seqNo);

        _tracker.onActivate();
    }

    @Override
    public void onDeactivate() {
        _active = false;
    }

    private class SubscriptionDispatcher implements TightLoopSnippet {

        @Override // TightLoopSnippet
        public int executeSnippet() {

            int fragmentsRead = 0;

            // reading from 'normal' streams
            if (_useIpcLoopback) {
                int read10 = _subIpc_0.poll(_assemblerIpc_0, _maxRead_0);
                fragmentsRead += read10;
            }

            int read20 = _subMct_0.poll(_assemblerMct_0, _maxRead_0);
            fragmentsRead += read20;

            if (_useIpcLoopback) {
                int read11 = _subIpc_1.poll(_assemblerIpc_1, _maxRead_1);
                fragmentsRead += read11;
            }

            int read21 = _subMct_1.poll(_assemblerMct_1, _maxRead_1);
            fragmentsRead += read21;

            if (_useIpcLoopback) {
                int read12 = _subIpc_2.poll(_assemblerIpc_2, _maxRead_2);
                fragmentsRead += read12;
            }

            int read22 = _subMct_2.poll(_assemblerMct_2, _maxRead_2);
            fragmentsRead += read22;

            // reading from 'serial' streams
            if (_useIpcLoopback) {
                int read14 = _subIpc_4.poll(_assemblerIpc_4, _maxRead_0);
                fragmentsRead += read14;
            }

            int read24 = _subMct_4.poll(_assemblerMct_4, _maxRead_0);
            fragmentsRead += read24;

            if (_useIpcLoopback) {
                int read15 = _subIpc_5.poll(_assemblerIpc_5, _maxRead_1);
                fragmentsRead += read15;
            }

            int read25 = _subMct_5.poll(_assemblerMct_5, _maxRead_1);
            fragmentsRead += read25;

            if (_useIpcLoopback) {
                int read16 = _subIpc_6.poll(_assemblerIpc_6, _maxRead_2);
                fragmentsRead += read16;
            }

            int read26 = _subMct_6.poll(_assemblerMct_6, _maxRead_2);
            fragmentsRead += read26;

            return fragmentsRead;
        }
    }

    public class RequestFragmentHandler implements FragmentHandler {
        private final boolean _loopback;
        private final Publication _publication;

        public RequestFragmentHandler(boolean loopback, Publication publication) {
            _loopback = loopback;
            _publication = publication;
        }

        @Override
        public void onFragment(DirectBuffer buffer, int offset, int length, Header header) {
            if (_active) {
                serialize((UnsafeBuffer) buffer, offset, length);
            } else {
                long serialId = HEADER_DECODER.wrap(buffer, offset).serialId();
                if (serialId > 0L) {
                    _tracker.onMsg(buffer, offset, length, serialId, this);
                }
            }
        }

        public void serialize(UnsafeBuffer buffer, int offset, int length) {
            HEADER_ENCODER.wrap(buffer, offset).seqNo(++_seqNo);
            _pubHelper.offer(_loopback, _publication, buffer, offset, length);
        }
    }

    private class ResponseFragmentHandler implements FragmentHandler {
        @Override
        public void onFragment(DirectBuffer buffer, int offset, int length, Header header) {
            if (!_active) {
                long serialId = HEADER_DECODER.wrap(buffer, offset).serialId();
                if (serialId > 0L) {
                    _tracker.onMsg(buffer, offset, length, serialId, null);
                }
            }
        }
    }

}
