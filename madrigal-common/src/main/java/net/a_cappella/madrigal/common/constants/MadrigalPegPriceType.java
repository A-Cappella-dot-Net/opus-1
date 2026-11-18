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

package net.a_cappella.madrigal.common.constants;

/**
 * What a pegged order (MadrigalOrdType.PEGGED) is pegged to.
 * MARKET: the best price on the opposite side of the book (the offer for a buy order, the bid for a sell order).
 * PRIMARY: the best price on the order's own side of the book (the bid for a buy order, the offer for a sell order).
 */
public enum MadrigalPegPriceType {
	MARKET, PRIMARY, NULL_VAL
}
