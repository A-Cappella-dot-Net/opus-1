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

import net.a_cappella.cembalo.constants.Side;

public class AuctionLevel extends AccumulatingLevel {
    public SummarizedOrders _contSumBids = null;
    public SummarizedOrders _contSumOffers = null;

    private double _bidPressure;
    private double _offerPressure;
    private double _matched;
    private double _surplus;
    private Side _surplusSide;

    public AuctionLevel(double price) {
        super(price);
        _surplusSide = Side.None;
    }

    public void clearContinuousSummarizedOrders() {
        _contSumBids = null;
        _contSumOffers = null;
    }
    public void setContinuousSummarizedOrders(Side side, SummarizedOrders summarizedOrders) {
        if (side==Side.Buy) {
            _contSumBids = summarizedOrders;
        } else {
            _contSumOffers = summarizedOrders;
        }
    }

    public double bidsSize() {
        return _sumBids.getLeavesQty() + ((_contSumBids==null)? 0 : _contSumBids.getLeavesQty());
    }

    public int bidsCount() {
        return _sumBids.count() + ((_contSumBids==null)? 0 : _contSumBids.count());
    }

    public Order getBid(int i) {
        return (i<_sumBids.count()) ? _sumBids.getOrder(i) : _contSumBids.getOrder(i-_sumBids.count());
    }

    public double offersSize() {
        return _sumOffers.getLeavesQty() + ((_contSumOffers==null)? 0 : _contSumOffers.getLeavesQty());
    }

    public int offersCount() {
        return _sumOffers.count() + ((_contSumOffers==null)? 0 : _contSumOffers.count());
    }

    public Order getOffer(int i) {
        return (i<_sumOffers.count()) ? _sumOffers.getOrder(i) : _contSumOffers.getOrder(i-_sumOffers.count());
    }


    public void setBidPressure() {
        _bidPressure = bidsSize();
    }
    public void setBidPressure(AuctionLevel prevLevel) {
        _bidPressure = bidsSize() + prevLevel._bidPressure;
    }

    public void setOfferPressure() {
        _offerPressure = offersSize();
    }
    public void setOfferPressure(AuctionLevel prevLevel) {
        _offerPressure = offersSize() + prevLevel._offerPressure;
    }

    public void setMatchedSurplusAndSide() {
        if (bidsCount() == 0 && offersCount() == 0) {
            // empty levels result from amends
            _matched = 0.0;
            _surplus = 0.0;
            _surplusSide = Side.None;
        } else if (_bidPressure > _offerPressure) {
            _matched = _offerPressure;
            _surplus = _bidPressure - _offerPressure;
            _surplusSide = Side.Buy;
        } else if (_bidPressure == _offerPressure) {
            _matched = _offerPressure;
            _surplus = _bidPressure - _offerPressure;
            _surplusSide = Side.None;
        } else {
            _matched = _bidPressure;
            _surplus = _offerPressure - _bidPressure;
            _surplusSide = Side.Sell;
        }
    }



    public double getBidPressure() {
        return _bidPressure;
    }

    public double getOfferPressure() {
        return _offerPressure;
    }

    public double getMatched() {
        return _matched;
    }

    public double getSurplus() {
        return _surplus;
    }

    public Side getSurplusSide() {
        return _surplusSide;
    }

    public String toString() {
        return "{"+_price+"|("+getBidLeavesQty()+","+getOfferLeavesQty()+")("+_bidPressure+","+_offerPressure+")<"+_matched+","+_surplus+","+_surplusSide+">}";
    }

}
