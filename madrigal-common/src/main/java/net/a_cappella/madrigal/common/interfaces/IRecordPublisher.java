package net.a_cappella.madrigal.common.interfaces;

import java.util.Map;

public interface IRecordPublisher {
	IPublishable enrichAndPublish(Map<String, Object> objMap);
	void publish(IPublishable pub);
	void publish(String subject, IPublishable pub);
}
