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

import static net.a_cappella.cembalo.generated.FixConstants.Val_PegOffsetType_BasisPoints;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegOffsetType_Price;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegOffsetType_Ticks;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegPriceType_Market;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegPriceType_MidPrice;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegPriceType_Primary;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegRoundDirection_MoreAggressive;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegRoundDirection_MorePassive;
import static net.a_cappella.cembalo.generated.FixConstants.Val_PegScope_Local;

/**
 * The peg instructions of a pegged order (OrdType = P). Values are the FIX ones.
 *
 * <ul>
 * <li>PegPriceType (1094): what the order is pegged to. Primary (5, default) = the best price on the
 * order's own side, Market (4) = the best price on the opposite side, MidPrice (2) = the midpoint
 * between the two.</li>
 * <li>PegOffsetValue (211): signed amount <b>added</b> to the reference price (default 0), expressed
 * in the units given by PegOffsetType (836): Price (0), BasisPoints (1) or Ticks (2, default).</li>
 * <li>PegRoundDirection (838): how a pegged price that does not fall on a valid price increment is
 * rounded: MorePassive (2, default) or MoreAggressive (1).</li>
 * <li>PegScope (840): where the reference price comes from. Only Local (1, default), i.e., this exchange, is supported.</li>
 * </ul>
 */
public final class PegInstruction {
    public static final int DEFAULT_PRICE_TYPE = Val_PegPriceType_Primary;
    public static final int DEFAULT_ROUND_DIRECTION = Val_PegRoundDirection_MorePassive;
    public static final double DEFAULT_OFFSET_VALUE = 0.0;
    public static final int DEFAULT_OFFSET_TYPE = Val_PegOffsetType_Ticks;
    public static final int DEFAULT_SCOPE = Val_PegScope_Local;

    public static final PegInstruction DEFAULT = new PegInstruction(DEFAULT_PRICE_TYPE, DEFAULT_ROUND_DIRECTION, DEFAULT_OFFSET_VALUE, DEFAULT_OFFSET_TYPE, DEFAULT_SCOPE);

    public final int _priceType;
    public final int _roundDirection;
    public final double _offsetValue;
    public final int _offsetType;
    public final int _scope;

    public PegInstruction(int priceType, int roundDirection, double offsetValue, int offsetType, int scope) {
        _priceType = priceType;
        _roundDirection = roundDirection;
        _offsetValue = offsetValue;
        _offsetType = offsetType;
        _scope = scope;
    }

    /** @return null when the instructions are supported, the reason for rejecting them otherwise */
    public String validate() {
        if (_scope != Val_PegScope_Local) {
            return "PegScope "+_scope+" is not supported";
        }
        switch (_priceType) {
            case Val_PegPriceType_MidPrice:
            case Val_PegPriceType_Market:
            case Val_PegPriceType_Primary:
                break;
            default:
                return "PegPriceType "+_priceType+" is not supported";
        }
        switch (_roundDirection) {
            case Val_PegRoundDirection_MoreAggressive:
            case Val_PegRoundDirection_MorePassive:
                break;
            default:
                return "PegRoundDirection "+_roundDirection+" is not supported";
        }
        switch (_offsetType) {
            case Val_PegOffsetType_Price:
            case Val_PegOffsetType_BasisPoints:
            case Val_PegOffsetType_Ticks:
                break;
            default:
                return "PegOffsetType "+_offsetType+" is not supported";
        }
        if (Double.isNaN(_offsetValue) || Double.isInfinite(_offsetValue)) {
            return "PegOffsetValue "+_offsetValue+" is not valid";
        }
        return null;
    }

    /** Mid Price pegged orders are hidden, i.e., they are not part of the Market Data. */
    public boolean isHidden() {
        return _priceType == Val_PegPriceType_MidPrice;
    }

    public boolean isRoundMoreAggressive() {
        return _roundDirection == Val_PegRoundDirection_MoreAggressive;
    }

    /** @return the offset, in price units, to be added to the given reference price */
    public double offset(double referencePrice, double minPriceIncrement) {
        switch (_offsetType) {
            case Val_PegOffsetType_Price: return _offsetValue;
            case Val_PegOffsetType_BasisPoints: return referencePrice * _offsetValue / 10000.0;
            default: return _offsetValue * minPriceIncrement; // Ticks
        }
    }

    @Override
    public String toString() {
        return "{peg "+_priceType+" "+_offsetValue+"/"+_offsetType+" "+_roundDirection+"}";
    }
}
