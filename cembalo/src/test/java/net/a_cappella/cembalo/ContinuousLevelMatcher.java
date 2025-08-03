package net.a_cappella.cembalo;

import java.util.Arrays;
import java.util.List;

import org.hamcrest.BaseMatcher;
import org.hamcrest.Description;

public class ContinuousLevelMatcher extends BaseMatcher<ContinuousLevel> {
    private final double _px;
    private final List<Order> _list;

    public static ContinuousLevelMatcher list(double px, Order... array) {
        return new ContinuousLevelMatcher(px, array);
    }

    public ContinuousLevelMatcher(double px, Order... array) {
        _px = px;
        _list = Arrays.asList(array);
    }

    @Override
    public boolean matches(Object obj) {
        if (obj instanceof ContinuousLevel) {
            ContinuousLevel continuousLevel = (ContinuousLevel) obj;
            if (_px != continuousLevel.getPrice()) {
                return false;
            }
            if (continuousLevel.ordersCount() != _list.size()) {
                return false;
            }
            for (int i=0; i<_list.size(); i++) {
                Order actual = continuousLevel.get(i);
                Order expected = _list.get(i);
                if (expected._orderID!=actual._orderID ||
                        expected._leavesQty != actual._leavesQty ||
                        expected._cumQty != actual._cumQty ||
                        expected._shownSize != actual._shownSize ||
                        expected._size != actual._size) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    @Override
    public void describeTo(Description description) {
        description.appendText("<{"+_px+" "+_list+"}>");
    }

}
