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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.madrigal.common.constants.MadrigalOrdType;
import net.a_cappella.madrigal.common.constants.MadrigalPegPriceType;
import net.a_cappella.madrigal.common.constants.MadrigalSide;
import net.a_cappella.madrigal.common.constants.MadrigalTimeInForce;
import org.agrona.concurrent.UnsafeBuffer;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import sbe.generated.OrderObjEncoder;

import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class OrderCoderTest {

	@BeforeAll
	public static void beforeAll() throws Exception {
		ObjectManager.getInstance().setMsgInstantiators(
			Arrays.asList(
				new MsgInstantiator(OrderObj.class.getName(), OrderCoder.class.getName(), null)
			)
		);
	}

	private OrderObj encodeAndDecode(OrderObj order) {
		UnsafeBuffer buffer = new UnsafeBuffer(new byte[1024]);

		OrderCoder encoder = new OrderCoder();
		encoder.getEncoder().wrap(buffer, 0);
		encoder.setObj(order);
		encoder.encodeKeys();
		encoder.encodeBody();

		OrderObj decoded = new OrderObj();
		OrderCoder decoder = new OrderCoder();
		decoder.getDecoder().wrap(buffer, 0, OrderObjEncoder.BLOCK_LENGTH, OrderObjEncoder.SCHEMA_VERSION);
		decoder.setObj(decoded);
		decoder.decodeKeys();
		decoder.decodeBody();
		return decoded;
	}

	@Test
	public void peggedOrderGoesOverTheWireWithItsPegInstructions() {
		OrderObj order = new OrderObj();
		order.setAddRequest("ecn", "uid", "00001", 0, "00001-0", "instrId", MadrigalOrdType.PEGGED, MadrigalTimeInForce.DAY, MadrigalSide.Sell, Double.NaN, 10.0, 10.0, 0);
		order.setPeg(MadrigalPegPriceType.MARKET, (byte) -3);

		OrderObj decoded = encodeAndDecode(order);

		assertEquals(MadrigalOrdType.PEGGED, decoded.getOrdType());
		assertEquals(MadrigalPegPriceType.MARKET, decoded.getPegPriceType());
		assertEquals((byte) -3, decoded.getPegOffsetValue());
		assertTrue(Double.isNaN(decoded.getPrice()), "a pegged order with no limit has no price");
		assertEquals(10.0, decoded.getOrderQty());
		assertEquals(MadrigalSide.Sell, decoded.getSide());
	}

	@Test
	public void limitOrderGoesOverTheWireWithNoPegInstructions() {
		OrderObj order = new OrderObj();
		order.setAddRequest("ecn", "uid", "00001", 0, "00001-0", "instrId", MadrigalOrdType.LIMIT, MadrigalTimeInForce.DAY, MadrigalSide.Buy, 102.0, 10.0, 10.0, 0);

		OrderObj decoded = encodeAndDecode(order);

		assertEquals(MadrigalOrdType.LIMIT, decoded.getOrdType());
		assertEquals(MadrigalPegPriceType.NULL_VAL, decoded.getPegPriceType());
		assertEquals((byte) 0, decoded.getPegOffsetValue());
		assertEquals(102.0, decoded.getPrice());
	}
}
