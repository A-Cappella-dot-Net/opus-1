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

package net.a_cappella.test.madrigal.ox;

import net.a_cappella.test.madrigal.ox.OrderExerciser.MDSnapshot;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdType.LIMIT;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Sell;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.DAY;

public class SthExerciser extends AbstractFeatureExerciser {
    public SthExerciser(boolean useNative, String versionsSequence) {
    	super(useNative, versionsSequence);
    }

    public double shownQty() {
    	return 0.0;
    }

    @Override // IFeatureExerciser
    public boolean selectOrderDetails(MDSnapshot mds) {
        String instrId = mds._instrId;
        double bid = mds._bid;
        double ask = mds._ask;
        double bidSize = mds._bidSize;
        double askSize = mds._askSize;

        // aggressive order: buy at the offer, sell at the bid
        if (!Double.isNaN(bid) && !Double.isNaN(ask)) {
            if (bidSize>=askSize) {
            	set(instrId, Sell, bid);
            	return true;
            } else { // bidSize<askSize
            	set(instrId, Buy, ask);
            	return true;
            }
        } else if (!Double.isNaN(ask)) {
        	set(instrId, Buy, ask);
        	return true;
        } else if (!Double.isNaN(bid)) {
        	set(instrId, Sell, bid);
        	return true;
        }

        return false;
    }

    @Override // IFeatureExerciser
    public String sendOrder() {
    	return sendOrder(LIMIT, DAY);
    }
}
