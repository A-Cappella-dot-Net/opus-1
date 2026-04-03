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

package net.a_cappella.cembalo;

public class Bond extends Instrument {
    private final int _maturityDate;
    private final double _contractMultiplier;
    private final double _coupon;

    public Bond(String symbol, String secId, double minQty, double minQtyIncrement, double minPriceIncrement, int ordering, int maxLevels,
                int maturityDate, double contractMultiplier, double coupon) {
        super(symbol, secId, minQty, minQtyIncrement, minPriceIncrement, ordering, maxLevels);
        _maturityDate = maturityDate;
        _contractMultiplier = contractMultiplier;
        _coupon = coupon;
    }

    public int getMaturityDate() {
        return _maturityDate;
    }
    public double getContractMultiplier() {
        return _contractMultiplier;
    }
    public double getCoupon() {
        return _coupon;
    }
}
