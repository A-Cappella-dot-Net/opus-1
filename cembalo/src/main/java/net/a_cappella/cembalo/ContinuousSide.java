package net.a_cappella.cembalo;

import java.nio.channels.SelectionKey;
import java.util.ArrayList;
import java.util.List;

public class ContinuousSide {
    public List<ContinuousLevel> _levels = new ArrayList<>(); // sorted by price

    public boolean isEmpty() {
        return _levels.isEmpty();
    }

    public double priceAtDepth(int i) {
        return _levels.get(i).getPrice();
    }

    public double sizeAtDepth(int i) {
        return _levels.get(i).getShownQty();
    }

    public int levelsCount() {
        return _levels.size();
    }

    public ContinuousLevel level(int i) {
        return _levels.get(i);
    }

    public void remove(ContinuousLevel level) {
        _levels.remove(level);
    }

    public boolean removeOrders(SelectionKey selectionKey) {
        boolean stackChanged = false;

        for (int i=0; i<_levels.size(); i++) {
            ContinuousLevel continuousLevel = _levels.get(i);
            stackChanged |= continuousLevel.remove(selectionKey);
            if (continuousLevel.hasNoOrders()) {
                _levels.remove(i--);
            }
        }

        return stackChanged;
    }

    public ContinuousLevel findLevel(Order ord, boolean descending) {
        double price = ord._price;
        for (int i=0; i<_levels.size(); i++) {
            ContinuousLevel continuousLevel = _levels.get(i);
            if (continuousLevel.getPrice()==price) return continuousLevel;
            if (descending) {
                if (continuousLevel.getPrice()<price) return null;
            } else {
                if (continuousLevel.getPrice()>price) return null;
            }
        }
        return null;
    }

    public void add(Order ord, boolean descending) {
        // add order to the appropriate level, at the end of the list
        if (_levels.isEmpty()) {
            ContinuousLevel continuousLevel = new ContinuousLevel(ord._price); // TODO no garbage
            continuousLevel.add(ord);
            _levels.add(continuousLevel);
        } else {
            if (descending) {
                // side is ordered DESCENDING
                for (int i=0; i<_levels.size(); i++) {
                    ContinuousLevel continuousLevel = _levels.get(i);
                    if (ord._price==continuousLevel.getPrice()) {
                        continuousLevel.add(ord);
                        return;
                    }
                    if (ord._price>continuousLevel.getPrice()) {
                        continuousLevel = new ContinuousLevel(ord._price); // TODO no garbage
                        continuousLevel.add(ord);
                        _levels.add(i, continuousLevel);
                        return;
                    }
                }
                ContinuousLevel continuousLevel = new ContinuousLevel(ord._price); // TODO no garbage
                continuousLevel.add(ord);
                _levels.add(continuousLevel);
                return;
            } else {
                // side is ordered ASCENDING
                for (int i=0; i<_levels.size(); i++) {
                    ContinuousLevel continuousLevel = _levels.get(i);
                    if (ord._price==continuousLevel.getPrice()) {
                        continuousLevel.add(ord);
                        return;
                    }
                    if (ord._price<continuousLevel.getPrice()) {
                        continuousLevel = new ContinuousLevel(ord._price); // TODO no garbage
                        continuousLevel.add(ord);
                        _levels.add(i, continuousLevel);
                        return;
                    }
                }
                ContinuousLevel continuousLevel = new ContinuousLevel(ord._price); // TODO no garbage
                continuousLevel.add(ord);
                _levels.add(continuousLevel);
                return;
            }
        }
    }
}
