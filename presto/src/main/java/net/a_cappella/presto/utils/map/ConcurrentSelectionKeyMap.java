package net.a_cappella.presto.utils.map;

import java.nio.channels.SelectionKey;
import java.util.concurrent.ConcurrentMap;

public interface ConcurrentSelectionKeyMap<T> extends ConcurrentMap<SelectionKey, T> {

}
