package net.a_cappella.madrigal.common.interfaces;

import java.util.Map;

public interface IFieldTransformer {
	Map<String, Object> transform(Map<String, Object> map);
}
