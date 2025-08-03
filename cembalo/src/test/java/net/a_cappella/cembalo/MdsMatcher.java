package net.a_cappella.cembalo;

import java.util.Arrays;
import java.util.List;

import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;

import net.a_cappella.cembalo.beans.MarketDataSnapshotEntry;

public class MdsMatcher extends BaseMatcher<List<MarketDataSnapshotEntry>> {
    private final List<MarketDataSnapshotEntry> _list;

    public static MdsMatcher list(MarketDataSnapshotEntry... array) {
        return new MdsMatcher(array);
    }

    public MdsMatcher(MarketDataSnapshotEntry... array) {
        _list = Arrays.asList(array);
    }

    @Override
    public boolean matches(Object obj) {
        if (obj instanceof List) {
            List<?> list = (List<?>) obj;
            if (list.size() != _list.size()) {
                return false;
            }
            for (int i=0; i<_list.size(); i++) {
                if (!_list.get(i).equals(list.get(i))) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    @Override
    public void describeTo(Description description) {
        description.appendText("<" + _list + ">");
    }

}
