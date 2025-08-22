package net.a_cappella.madrigal.om.strategy;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class RandomizedIcebergStrategyTest {
    public static final double EPSILON = 0.000001;

	private InstrumentStatic _is;

	@Test
    public void mySystematicTest() {
		_is = new InstrumentStatic(1, 1);
		new Order().withOrderQty(100).withShown(5)
			.onFill(0).leavesIs(100).activeIs(0).whenRandom(0).placeNewSize(5).activeIs(5)
			.onFill(0).leavesIs(100).activeIs(5).whenRandom(0).placeNewSize(0).activeIs(5) // wait
			.onFill(5).leavesIs(95).activeIs(0).whenRandom(0).placeNewSize(5).activeIs(5)
			.onFill(4).leavesIs(91).activeIs(1).whenRandom(0).placeNewSize(4).activeIs(5)
			.onFill(3).leavesIs(88).activeIs(2).whenRandom(0).placeNewSize(3).activeIs(5)
			.onFill(2).leavesIs(86).activeIs(3).whenRandom(0).placeNewSize(2).activeIs(5)
			.onFill(1).leavesIs(85).activeIs(4).whenRandom(0).placeNewSize(1).activeIs(5)
			.onFill(0).leavesIs(85).activeIs(5).whenRandom(0).placeNewSize(0).activeIs(5)
			.onFill(0).leavesIs(85).activeIs(5).whenRandom(1).placeNewSize(1).activeIs(6)
			.onFill(6).leavesIs(79).activeIs(0).whenRandom(1).placeNewSize(6).activeIs(6)
			.onFill(5).leavesIs(74).activeIs(1).whenRandom(1).placeNewSize(5).activeIs(6)
			.onFill(4).leavesIs(70).activeIs(2).whenRandom(1).placeNewSize(4).activeIs(6)
			.onFill(3).leavesIs(67).activeIs(3).whenRandom(1).placeNewSize(3).activeIs(6)
			.onFill(2).leavesIs(65).activeIs(4).whenRandom(1).placeNewSize(2).activeIs(6)
			.onFill(1).leavesIs(64).activeIs(5).whenRandom(1).placeNewSize(1).activeIs(6)
			.onFill(0).leavesIs(64).activeIs(6).whenRandom(1).placeNewSize(0).activeIs(6) // wait
			.onFill(0).leavesIs(64).activeIs(6).whenRandom(2).placeNewSize(1).activeIs(7)
			.onFill(7).leavesIs(57).activeIs(0).whenRandom(2).placeNewSize(7).activeIs(7)
			.onFill(6).leavesIs(51).activeIs(1).whenRandom(2).placeNewSize(6).activeIs(7)
			.onFill(5).leavesIs(46).activeIs(2).whenRandom(2).placeNewSize(5).activeIs(7)
			.onFill(4).leavesIs(42).activeIs(3).whenRandom(2).placeNewSize(4).activeIs(7)
			.onFill(3).leavesIs(39).activeIs(4).whenRandom(2).placeNewSize(3).activeIs(7)
			.onFill(2).leavesIs(37).activeIs(5).whenRandom(2).placeNewSize(2).activeIs(7)
			.onFill(1).leavesIs(36).activeIs(6).whenRandom(2).placeNewSize(1).activeIs(7)
			.onFill(0).leavesIs(36).activeIs(7).whenRandom(2).placeNewSize(0).activeIs(7) // wait
			.onFill(0).leavesIs(36).activeIs(7).whenRandom(3).placeNewSize(1).activeIs(8)

			.onFill(8).leavesIs(28).activeIs(0).whenRandom(3).placeNewSize(8).activeIs(8)
			.onFill(7).leavesIs(21).activeIs(1).whenRandom(3).placeNewSize(7).activeIs(8)
			.onFill(6).leavesIs(15).activeIs(2).whenRandom(3).placeNewSize(6).activeIs(8)
			.onFill(5).leavesIs(10).activeIs(3).whenRandom(3).placeNewSize(5).activeIs(8)
			.onFill(4).leavesIs( 6).activeIs(4).whenRandom(3).placeNewSize(2).activeIs(6)
			.onFill(3).leavesIs( 3).activeIs(3).whenRandom(3).placeNewSize(0).activeIs(3)
			.onFill(2).leavesIs( 1).activeIs(1).whenRandom(3).placeNewSize(0).activeIs(1)
			.onFill(1).leavesIs( 0).activeIs(0).whenRandom(3).placeNewSize(0).activeIs(0) // done
			.onFill(0).leavesIs( 0).activeIs(0).whenRandom(3).placeNewSize(0).activeIs(0)
			;
	}

	@Test public void myTest() {
		_is = new InstrumentStatic(1, 1);
		new Order().withOrderQty(100).withShown(5)
			.whenRandom(0).placeNewSize(5).activeIs(5).leavesIs(100)
			.whenRandom(0).placeNewSize(0).activeIs(5).leavesIs(100) // nothing filled, so wait
			.onFill(1).whenRandom(0).placeNewSize(1).activeIs(5).leavesIs(99)
			.onFill(1).whenRandom(1).placeNewSize(2).activeIs(6).leavesIs(98)
			.onFill(1).whenRandom(2).placeNewSize(2).activeIs(7).leavesIs(97)
			.onFill(1).whenRandom(0).placeNewSize(0).activeIs(6).leavesIs(96)
			.onFill(2).whenRandom(0).placeNewSize(1).activeIs(5).leavesIs(94)
			.onFill(5).whenRandom(0).placeNewSize(5).activeIs(5).leavesIs(89)
			;
	}

	

	private class Order {
		private double _orderQty;
		private double _shown;
		private double _newSize;
		private double _activeQty;
		private double _leavesQty;

		public Order withShown(double shown) {
			_shown = shown;
			return this;
		}
		public Order withOrderQty(double orderQty) {
			_orderQty = orderQty;
			_activeQty = 0.0;
			_leavesQty = orderQty;
			return this;
		}

		public Order onFill(double qty) {
			_activeQty -= qty;
			_leavesQty -= qty;
			return this;
		}
		public Order whenRandom(int randomIncr) {
			_newSize = nextNewSize(_orderQty, _shown, randomIncr, _activeQty, _leavesQty, _is._minQty, _is._minQtyIncr);
//			_newSize = SimulatedIbgRwtStrategy.nextChildQty(_orderQty, _shown, randomIncr, _activeQty, _orderQty, _is._minQty, _is._minQtyIncr);
			return this;
		}
		public Order placeNewSize(double expectedNewSize) {
			assertEquals(expectedNewSize, _newSize, EPSILON);
			if (_newSize > EPSILON) {
				_activeQty += _newSize;
			}
			return this;
		}
		public Order activeIs(double active) {
			assertEquals(active, _activeQty, EPSILON);
			return this;
		}
		public Order leavesIs(double leaves) {
			assertEquals(leaves, _leavesQty, EPSILON);
			return this;
		}
	}
	private static class InstrumentStatic {
		private final double _minQty;
		private final double _minQtyIncr;
		public InstrumentStatic(double minQty, double minQtyIncr) {
			_minQty = minQty;
			_minQtyIncr = minQtyIncr;
		}
	}



//	double nextChildQty(double orderQty, double shownQty, int randInt, double activeQty, double fillableQty, double minQty, double minIncr);
	double nextNewSize(double orderQty, double shownQty, int randInt, double activeQty, double leavesQty, double minQty, double minIncr) {
		// returns -1 if remaining parent should be canceled (remaining qty not valid)
		// returns 0 if no new child should be sent
		// returns > 0 if a new child should be sent with orderQty==shownQty==return value
//		activeQty = sum[child in activeChildren](child.leavesQty) // current shown size in the market
		if (leavesQty < EPSILON) return 0.0;
		double passiveQty = leavesQty - activeQty; // parent size that has not yet been sent
		if (passiveQty < minQty) {
			// if there is active size in the market then wait for more size to fill up
			// if there is no active size in the market and the passive size is zero then done
			// else give up
			return (activeQty > EPSILON || passiveQty < EPSILON) ? 0.0 : -1.0;
		}
		double icebergPeak = shownQty + randInt*minIncr - activeQty;
		if (icebergPeak <= 0.0) {
			// activeQty must be > 0
			return 0.0; // wait until more size fills
		}
		icebergPeak = Math.min(passiveQty, icebergPeak);
		if (icebergPeak > minQty - EPSILON) {
			if (isValid(icebergPeak, minQty, minIncr)) {
				return icebergPeak;
			}
			if (activeQty > 0.0) {
				return 0.0;
			}
			// nothing active; somehow I got a fill for less than minQtyIncr
			return roundDown(icebergPeak, minQty, minIncr);
		}
		return (activeQty > EPSILON || passiveQty < EPSILON) ? 0.0 : -1.0;
	}

	private boolean isValid(double icebergPeak, double minQty, double minQtyIncr) {
		assert(icebergPeak > minQty - EPSILON);
		double increments = (icebergPeak - minQty) / minQtyIncr;
		return Math.abs(Math.rint(increments) - increments) < EPSILON;
	}
	private double roundDown(double icebergPeak, double minQty, double minQtyIncr) {
		assert(icebergPeak > minQty - EPSILON);
		double increments = (icebergPeak - minQty) / minQtyIncr;
		return minQty + Math.floor(increments) * minQtyIncr;
	}
}
