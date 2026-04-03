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

package net.a_cappella.cembalo.beans;

import java.util.Objects;

public class MarketDataSnapshotEntry {
    private final static double EPSILON = 0.000000000001;
    private final static double MINUS_EPSILON = - EPSILON;

    public double _size;
    public double _price;

    public MarketDataSnapshotEntry(double size, double price) {
        _size = size;
        _price = price;
    }

    public void reset() {
        _size = 0;
        _price = Double.NaN;
    }

    public boolean equals(Object other) {
        if (other==null) {
            return false;
        }
        if (!(other instanceof MarketDataSnapshotEntry)) {
            return false;
        }
        MarketDataSnapshotEntry mds = (MarketDataSnapshotEntry) other;
        double diff = _size - mds._size;
        if (MINUS_EPSILON < diff && diff < EPSILON) {
            diff = _price - mds._price;
            return MINUS_EPSILON < diff && diff < EPSILON;
        }
        return false;
    }
    public int hashCode() {
        return Objects.hash(_size, _price);
    }

    public String toString() {
        return _size+"@"+_price;
    }
}
