Feature: Order Manager - Simulated Pegged orders Scenarios
  This feature includes scenarios that involve pegged orders (ordType PEGGED) sent to an exchange that
  does not support them natively.

  The pegged order is ACKed right away and it is worked through one LIMIT child order, the working order,
  which is re-priced (RWT) when the market data of the exchange shows that the price pegged to has moved:
    pegPriceType PRIMARY: the best price on the side of the order (bid for Buy, offer for Sell)
    pegPriceType MARKET:  the best price on the opposite side (offer for Buy, bid for Sell)
  pegOffsetValue is a signed number of ticks (0.01 for the instrument used here) added to the price pegged to.
  The price of a pegged order is optional: it is the limit the order never goes beyond.

  The client is not told when the working order is re-priced, and it is not told about the two edge cases
  either (they are only logged):
    (1) there is no price to peg to: the order is parked, i.e., the working order, if any, is pulled out
        of the market until there is a price to peg to again.
    (2) the pegged price is more aggressive than the limit: the order stops tracking and the working
        order is left in place. Tracking resumes when the pegged price is back within the limit.

  A PRIMARY peg is pegged to the side of the book its own working order sits on: the working order is
  left out when looking for the price to peg to.

Background:
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
	| true               | true             | false                           | true                    | true      |


@PegTracking
Scenario: PRIMARY peg follows the best bid up and down until it is filled.
  The working order joins the best bid. It follows the bid when a better bid shows up and it goes back
  when it is left alone at the top of the book. The client only hears about the ADD and the FILL.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  # the working order shows up in the market data: nothing to do
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 15.0     | 100.0 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # a better bid shows up
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 7.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.0 | 17.0     | 100.02 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # the better bid is gone: the working order is alone at the top of the book
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.0 | 10.0     | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 15.0     | 100.0 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-2 |      4 | x0-00001 | 10.0    | 100.0  | 0.0       | 10.0   | 100.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      4 | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 10.0    | 100.0  | 0.0       | 10.0   | 100.0 |      | true   | true  |
  And no child order is sent to exchange


@PegTracking
Scenario: MARKET peg follows the best offer until it is canceled.
  A Buy order pegged one tick below the best offer. The DEL request of the client cancels the working order.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0 | ask0  | askSize0 |
	| 5.0      | 99.9 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | MARKET       | -1             | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px     | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.09 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | MARKET       | -1             |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the working order is the best bid now; the offer has not moved
  When a market data snapshot is received from exchange
	| bidSize1 | bid1 | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 99.9 | 10.0     | 100.09 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # the offer comes down
  When a market data snapshot is received from exchange
	| bidSize1 | bid1 | bidSize0 | bid0   | ask0   | askSize0 |
	| 5.0      | 99.9 | 10.0     | 100.09 | 100.05 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.04 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the offer goes up
  When a market data snapshot is received from exchange
	| bidSize1 | bid1 | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 99.9 | 10.0     | 100.04 | 100.2 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.19 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-3 | 00001~0-2   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-3 |      4 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   | PEGGED  | MARKET       | -1             |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

  # the order is over: market data does not matter anymore
  When a market data snapshot is received from exchange
	| bidSize0 | bid0 | ask0  | askSize0 |
	| 5.0      | 99.9 | 100.3 | 5.0      |
  Then no child order is sent to exchange


@PegPrice
Scenario Outline: Pegged price: <side> <pegPriceType> peg with offset <offset> is sent at <px>.
  The best bid is 100.00 and the best offer is 100.10. The offset is added to the price pegged to,
  whatever the side of the order: a positive offset makes a Buy more aggressive and a Sell less aggressive.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType   | pegOffsetValue | timeInForce | side   | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | <pegPriceType> | <offset>       | DAY         | <side> |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side   | qty  | shownQty | px   | tif |
	| ADD     | 00001~0-0 | LIMIT   | <side> | 10.0 | 10.0     | <px> | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType   | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side   | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | <pegPriceType> | <offset>       |        |          |      1 | DAY         | <side> | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  Examples: PRIMARY peg, pegged to the side of the order
	| side | pegPriceType | offset | px     |
	| Buy  | PRIMARY      | 0      | 100.0  |
	| Buy  | PRIMARY      | 2      | 100.02 |
	| Buy  | PRIMARY      | -2     | 99.98  |
	| Sell | PRIMARY      | 0      | 100.1  |
	| Sell | PRIMARY      | 2      | 100.12 |
	| Sell | PRIMARY      | -2     | 100.08 |

  Examples: MARKET peg, pegged to the opposite side
	| side | pegPriceType | offset | px     |
	| Buy  | MARKET       | 0      | 100.1  |
	| Buy  | MARKET       | -3     | 100.07 |
	| Sell | MARKET       | 0      | 100.0  |
	| Sell | MARKET       | 3      | 100.03 |


@PegTracking @OwnOrder
Scenario: PRIMARY peg with an aggressive offset does not follow itself.
  A Buy order pegged one tick above the best bid becomes the best bid. It is left out when looking
  for the price to peg to, otherwise it would move up by one tick with every market data snapshot.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 1              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px     | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.01 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 1              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the working order is the best bid: the price to peg to is still 100.00
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.0 | 10.0     | 100.01 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # the bid the order is pegged to goes down
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 99.98 | 10.0     | 100.01 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 99.99 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # somebody joins the working order at its price: this is the best bid now
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.98 | 13.0     | 99.99 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And no execution report is sent to client


@PegTracking @OwnOrder
Scenario: Market data that does not show the working order yet is not acted upon.
  Market data and execution reports are independent. A snapshot that should show the working order
  of a PRIMARY peg and does not is older than what we know about the working order.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the bid at 100.00 is gone and the working order is not there yet
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.99 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.99 | 10.0     | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 99.99 | DAY |
  And no execution report is sent to client


@PegTracking
Scenario: Market data received while the working order is busy is acted upon with the next market data.
  One request at a time is sent to the working order. Market data that arrives before the working
  order answers is not acted upon; neither is the answer of the working order.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |
  And no execution report is sent to client


@PegTracking @Fills
Scenario: Partially filled pegged order keeps tracking.
  The working order is re-priced for its entire quantity, as any order that is amended at the exchange.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 100.0  | 6.0       | 4.0    | 100.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      2 | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 4.0     | 100.0  | 6.0       | 4.0    | 100.0 |      | false  | false |

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 6.0      | 100.0 | 5.0      | 100.03 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.03 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 4.0    | 100.0 |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | done  |
	| ADD     | FILL   | 00001~0-1 |      4 | x0-00001 | 6.0     | 100.03 | 0.0       | 10.0   | 100.018 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      4 | x0-00001 |      3 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 6.0     | 100.03 | 0.0       | 10.0   | 100.018 |      | true   | true  |


@PegTracking @Fills
Scenario: Working order is filled while it is being re-priced.
  The re-pricing is rejected by the exchange because the working order is gone. The FILL told
  the client everything there is to know.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 100.0  | 0.0       | 10.0   | 100.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      2 | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 10.0    | 100.0  | 0.0       | 10.0   | 100.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange


@PegEdgeCases @Parked
Scenario: Edge case 1 - No market data when the order is received: the order is parked.
  The order is ACKed and nothing is sent to the exchange until there is a price to peg to.

  When a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And no execution report is sent to client


@PegEdgeCases @Parked
Scenario Outline: Edge case 1 - <side> <pegPriceType> peg is parked when there is no <pegSide> to peg to.
  The side of the book the order is pegged to depends on the side of the order and on pegPriceType.
  The other side of the book being populated does not help.

  When a market data snapshot is received from exchange
	| bidSize0   | bid0   | ask0   | askSize0   |
	| <bidSize0> | <bid0> | <ask0> | <askSize0> |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType   | pegOffsetValue | timeInForce | side   | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | <pegPriceType> | 0              | DAY         | <side> |       | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType   | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side   | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | <pegPriceType> | 0              |        |          |      1 | DAY         | <side> | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  # still nothing to peg to
  When a market data snapshot is received from exchange
	| bidSize0   | bid0   | ask0   | askSize0   |
	| <bidSize0> | <bid0> | <ask0> | <askSize0> |
  Then no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side   | qty  | shownQty | px   | tif |
	| ADD     | 00001~0-0 | LIMIT   | <side> | 10.0 | 10.0     | <px> | DAY |
  And no execution report is sent to client

  Examples:
	| side | pegPriceType | pegSide | bidSize0 | bid0  | ask0  | askSize0 | px    |
	| Buy  | PRIMARY      | bid     | 0.0      | NaN   | 100.1 | 5.0      | 100.0 |
	| Buy  | MARKET       | offer   | 5.0      | 100.0 | NaN   | 0.0      | 100.1 |
	| Sell | PRIMARY      | offer   | 5.0      | 100.0 | NaN   | 0.0      | 100.1 |
	| Sell | MARKET       | bid     | 0.0      | NaN   | 100.1 | 5.0      | 100.0 |


@PegEdgeCases @Parked
Scenario: Edge case 1 - Nothing left to peg to: the working order is pulled out of the market until there is.
  The working order of a PRIMARY peg is the only bid left. The order is parked: the working order is
  canceled and a new one is sent when a bid shows up. The client is not told.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the other bid is gone
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 10.0     | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize0 | bid0 | ask0  | askSize0 |
	| 0.0      | NaN  | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # a bid shows up
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.95 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | LIMIT   | Buy  | 10.0 | 10.0     | 99.95 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 15.0     | 99.95 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      4 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |


@PegEdgeCases @Parked @Fills
Scenario: Edge case 1 - Partially filled order is parked and then unparked for the quantity that is left.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 100.0  | 6.0       | 4.0    | 100.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      2 | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 4.0     | 100.0  | 6.0       | 4.0    | 100.0 |      | false  | false |

  # what is left of the working order is the only bid
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 6.0      | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 4.0    | 100.0 |      | true  |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize0 | bid0 | ask0  | askSize0 |
	| 5.0      | 99.9 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty | shownQty | px   | tif |
	| ADD     | 00001~1-0 | LIMIT   | Buy  | 6.0 | 6.0      | 99.9 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      4 | x0-00002 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 6.0     | 99.9   | 0.0       | 6.0    | 99.9  |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      5 | x0-00002 |      3 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 6.0     | 99.9   | 0.0       | 10.0   | 99.94 |      | true   | true  |


@PegEdgeCases @Parked
Scenario: Edge case 1 - RWT and DEL received while the order is parked are ACKed right away.
  There is nothing in the market: the requests are accepted without involving the exchange. The new
  quantity is used when the order is unparked.

  When a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
	| ADD     | 00002 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
	| ADD     | ACK    | 00002 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   |       | 15.0 | 15.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      3 | DAY         | Buy  | NaN   | 15.0 | 15.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00002 | 1   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00002 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      4 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

  # only the order that was not canceled is unparked
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 15.0 | 15.0     | 100.0 | DAY |
  And no execution report is sent to client


@PegEdgeCases @Parked @Rwt
Scenario: Edge case 1 - RWT received while the working order is being pulled out is ACKed when the order is parked.
  One request at a time is sent to the working order: the RWT waits for the cancel to be answered.
  There is nothing in the market by then, so the RWT is accepted without involving the exchange.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the working order is the only bid left
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 10.0     | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   |       | 15.0 | 15.0     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 15.0 | 15.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  # the order is unparked for its new quantity
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.95 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | LIMIT   | Buy  | 15.0 | 15.0     | 99.95 | DAY |
  And no execution report is sent to client


@PegEdgeCases @Parked @Rwt @Del
Scenario: Edge case 1 - RWT and then DEL received while the working order is being pulled out.
  The DEL supersedes the RWT that is waiting for the working order. The DEL is ACKed when the
  cancel of the working order is: there is nothing else to cancel.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 10.0     | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   |       | 15.0 | 15.0     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 15.0 | 15.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   | PEGGED  | PRIMARY      | 0              |        |          |      3 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |
  And no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.95 | 100.1 | 5.0      |
  Then no child order is sent to exchange


@PegEdgeCases @Limit
Scenario: Edge case 2 - Buy order stops tracking when the bid goes beyond its limit and resumes when the bid is back.
  The order follows the bid up to its limit (100.05). When the bid goes beyond the limit the working
  order is left where it is, and nothing is sent to the client. Tracking resumes when the bid is back
  within the limit.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.2 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price  | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  | 100.05 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | 100.05 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # within the limit: the order follows
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.0 | 5.0      | 100.04 | 100.2 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.04 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # beyond the limit: the working order stays at 100.04
  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.04 | 5.0      | 100.07 | 100.2 | 5.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize2 | bid2   | bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.04 | 5.0      | 100.07 | 5.0      | 100.09 | 100.2 | 5.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  # back within the limit: the order follows again
  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.04 | 5.0      | 100.05 | 100.2 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.05 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # beyond the limit again: the working order stays at 100.05, where it is eventually hit
  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.05 | 5.0      | 100.06 | 100.2 | 5.0      |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| ADD     | FILL   | 00001~0-2 |      4 | x0-00001 | 10.0    | 100.05 | 0.0       | 10.0   | 100.05 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      4 | x0-00001 |      2 | DAY         | Buy  | 100.05 | 10.0 | 10.0     | 10.0    | 100.05 | 0.0       | 10.0   | 100.05 |      | true   | true  |


@PegEdgeCases @Limit
Scenario: Edge case 2 - Sell order stops tracking when the bid goes below its limit.
  A Sell order pegged one tick above the best bid, not to be sold below 100.00. For a Sell order
  the pegged price is more aggressive than the limit when it is lower.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.03 | 100.2 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | MARKET       | 1              | DAY         | Sell | 100.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px     | tif |
	| ADD     | 00001~0-0 | LIMIT   | Sell | 10.0 | 10.0     | 100.04 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | MARKET       | 1              |        |          |      1 | DAY         | Sell | 100.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # the pegged price would be 99.96: the working order stays at 100.04
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0   | askSize0 | ask1  | askSize1 |
	| 5.0      | 99.95 | 100.04 | 10.0     | 100.2 | 5.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  # the pegged price is 100.00: at the limit is within the limit
  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0   | askSize0 | ask1  | askSize1 |
	| 5.0      | 99.99 | 100.04 | 10.0     | 100.2 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Sell | 10.0 | 10.0     | 100.0 | DAY |
  And no execution report is sent to client


@PegEdgeCases @Limit
Scenario: Edge case 2 - Order received when the pegged price is already beyond its limit is sent at its limit.
  There is no working order to leave in place: the order goes in at its limit and it does not track
  until the pegged price is within the limit.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.1 | 100.2 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price  | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  | 100.05 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px     | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.05 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | 100.05 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0  | ask0  | askSize0 |
	| 10.0     | 100.05 | 5.0      | 100.1 | 100.2 | 5.0      |
  Then no child order is sent to exchange

  # the bid comes down below the working order, which is not hit: the order tracks the bid from now on
  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.03 | 10.0     | 100.05 | 100.2 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.03 | DAY |
  And no execution report is sent to client


@PegEdgeCases @Limit @Rwt
Scenario: Edge case 2 - RWT that moves the limit away is ACKed right away and the order resumes tracking.
  Only the limit changes: there is nothing to amend at the exchange on behalf of the request. With
  the new limit the pegged price is within the limit again.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.2 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price  | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  | 100.05 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | 100.05 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  # beyond the limit: the working order stays at 100.00
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.0 | 5.0      | 100.07 | 100.2 | 5.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 100.1 | 10.0 | 10.0     |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | 100.1 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.07 | DAY |


@PegEdgeCases @Limit @Rwt
Scenario: Edge case 2 - RWT that moves the limit short of the working order brings the working order back to the limit.
  The order never goes beyond its limit: the working order cannot be left in place this time. The
  request is ACKed when the working order is amended.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.07 | 100.2 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  | 100.1 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px     | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.07 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | 100.1 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 100.02 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | 100.02 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  # the bid is beyond the new limit: the working order stays at its limit
  When a market data snapshot is received from exchange
	| bidSize1 | bid1   | bidSize0 | bid0   | ask0  | askSize0 |
	| 10.0     | 100.02 | 5.0      | 100.07 | 100.2 | 5.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client


@Rwt
Scenario: RWT that changes the quantity amends the working order at the price it is at.
  The RWT is ACKed when the working order is amended.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   |       | 15.0 | 15.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 15.0 | 15.0     | 100.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 15.0 | 15.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false  | false |

  # the amended working order keeps tracking
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 20.0     | 100.0 | 5.0      | 100.01 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 15.0 | 15.0     | 100.01 | DAY |
  And no execution report is sent to client


@Rwt
Scenario: RWT received while the working order is being re-priced waits for the working order.
  One request at a time is sent to the working order: the RWT is applied, at the new price, when the
  re-pricing is ACKed by the exchange.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   |       | 15.0 | 15.0     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-2 | 00001~0-1   | x0-00001 | LIMIT   | Buy  | 15.0 | 15.0     | 100.02 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 15.0 | 15.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false  | false |


@Del
Scenario: DEL received before the working order is ACKed.
  The cancel of the working order is sent as soon as the exchange ACKs the working order.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |


@Del
Scenario: DEL received while the working order is being re-priced.
  The cancel is sent right away. The answer to the re-pricing does not matter anymore.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |


@Exchange
Scenario: Working order is rejected by the exchange: the pegged order is over.
  The pegged order was ACKed when it was received, so it cannot be NAKed anymore: the client is sent
  a DONE message with the reason given by the exchange.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | done  |
	| ADD     | NAK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Trading suspended | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Trading suspended | true   | true  |
  And no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.02 | 100.1 | 5.0      |
  Then no child order is sent to exchange


@Exchange
Scenario: Working order is canceled by the exchange: the pegged order is over.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | done  |
	| DEL     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Done for Day | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Done for Day | true   | true  |

  When a market data snapshot is received from exchange
	| bidSize0 | bid0   | ask0  | askSize0 |
	| 5.0      | 100.02 | 100.1 | 5.0      |
  Then no child order is sent to exchange


@Exchange @FailFast
Scenario: Re-pricing is rejected by the exchange while the working order is alive: fail fast.
  A working order that cannot be re-priced cannot be pegged: it is canceled and the client is told
  when the cancel is ACKed.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | done  |
	| RWT     | NAK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Price out of band | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  # no more re-pricing
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.03 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Fail Fast | true   | true  |


@Validation
Scenario Outline: Pegged order that is not supported is NAKed: <text>.
  Only MARKET and PRIMARY pegs are supported, the order has to be a DAY order and it has to be displayed.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType   | pegOffsetValue | timeInForce | side | price | qty  | shownQty   | useNative |
	| ADD     | 00001 | 0   | PEGGED  | <pegPriceType> | 0              | <tif>       | Buy  |       | 10.0 | <shownQty> | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType   | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty   | lastQty | lastPx | leavesQty | cumQty | avgPx | text   | ftDone | done  |
	| ADD     | NAK    | 00001 | 0   | PEGGED  | <pegPriceType> | 0              |        |          |      1 | <tif>       | Buy  | NaN   | 10.0 | <shownQty> | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | <text> | true   | true  |

  Examples:
	| pegPriceType | tif | shownQty | text                                   |
	|              | DAY | 10.0     | PegPriceType not supported             |
	| PRIMARY      | IOC | 10.0     | Pegged orders must be DAY orders       |
	| MARKET       | DAY | 0.0      | Hidden pegged orders are not supported |


@Iceberg
Scenario: Iceberg pegged order: only the shown quantity of the working order is displayed.
  The working order is an iceberg order like the pegged order. What is displayed of it is what is left
  out when looking for the price to peg to.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 30.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | LIMIT   | Buy  | 30.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 30.0 | 10.0     | 0.0     | NaN    | 30.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 30.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 15.0     | 100.0 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  # the 10.0 that are displayed at 100.00 are the working order: the price to peg to is 99.97
  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 99.97 | 10.0     | 100.0 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | LIMIT   | Buy  | 30.0 | 10.0     | 99.97 | DAY |
  And no execution report is sent to client


@Simulated
Scenario: Pegged order with useNative=false: the working order is a simulated order.
  The working order is handled by the simulated iceberg / rwt logic, which in turn sends its own child
  order to the exchange. Everything else is the same.

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 5.0      | 100.0 | 100.1 | 5.0      |
  And a parent order is received from client
	| reqType | ordId | ver | ordType | pegPriceType | pegOffsetValue | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | PEGGED  | PRIMARY      | 0              | DAY         | Buy  |       | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID     | ordType | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0~0-0 | LIMIT   | Buy  | 10.0 | 10.0     | 100.0 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   | PEGGED  | PRIMARY      | 0              |        |          |      1 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize0 | bid0  | ask0  | askSize0 |
	| 15.0     | 100.0 | 100.1 | 5.0      |
  Then no child order is sent to exchange

  When a market data snapshot is received from exchange
	| bidSize1 | bid1  | bidSize0 | bid0   | ask0  | askSize0 |
	| 15.0     | 100.0 | 5.0      | 100.02 | 100.1 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID     | origClOrdId | ecnOrdId | ordType | side | qty  | shownQty | px     | tif |
	| RWT     | 00001~0~0-1 | 00001~0~0-0 | x0-00001 | LIMIT   | Buy  | 10.0 | 10.0     | 100.02 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| ADD     | FILL   | 00001~0~0-1 |      3 | x0-00001 | 10.0    | 100.02 | 0.0       | 10.0   | 100.02 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | ordType | pegPriceType | pegOffsetValue | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   | PEGGED  | PRIMARY      | 0              |      3 | x0-00001 |      2 | DAY         | Buy  | NaN   | 10.0 | 10.0     | 10.0    | 100.02 | 0.0       | 10.0   | 100.02 |      | true   | true  |
