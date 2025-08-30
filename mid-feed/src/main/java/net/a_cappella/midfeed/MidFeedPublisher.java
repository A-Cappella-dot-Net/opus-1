package net.a_cappella.midfeed;

import net.a_cappella.madrigal.common.obj.MidFeedObj;
import net.a_cappella.madrigal.common.utils.StringDelayer;
import net.a_cappella.presto.ps.PrestoClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MidFeedPublisher {
    private static final Logger log = LoggerFactory.getLogger(MidFeedPublisher.class);

    private final PrestoClient _client;
	private final MidFeedObj _midFeed = new MidFeedObj();
	private final Map<String, InstrumentConfig> _map = new HashMap<>();
	private StringDelayer _delayedPublisher;

	public MidFeedPublisher(PrestoClient client, String subject, List<String> list) {
		_client = client;
		for (String element : list) {
			InstrumentConfig instrStatic = new InstrumentConfig(element);
			_map.put(instrStatic._instrId, instrStatic);
		}
	}

	public void start() {
  		_client.waitUntilInitialized();

    	_delayedPublisher = new DelayedPublisher();
		for (InstrumentConfig instrStatic : _map.values()) {
			_delayedPublisher.add(instrStatic.randomDelay(), instrStatic._instrId);
		}
        _delayedPublisher.start();
	}


    private class DelayedPublisher extends StringDelayer {
    	public DelayedPublisher() {}
		@Override
		public void execute(String instrId) {
            InstrumentConfig instrStatic = _map.get(instrId);
            // generate mid and publish the record
            _midFeed.set(instrStatic._instrId, instrStatic.randomMid(), System.currentTimeMillis());
            try {
				_client.publish(_midFeed);
			} catch (Exception e) {
                log.error("Error publishing midFeed {}", _midFeed, e);
			}
            // add the new _obj to the queue with the new delay
            long delay = instrStatic.randomDelay();
            if (delay>0) {
                add(instrStatic.randomDelay(), instrId);
            }
		}
    }
}
