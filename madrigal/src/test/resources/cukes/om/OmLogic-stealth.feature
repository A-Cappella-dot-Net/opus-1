Feature: Order Manager - Stealth / Hidden orders Scenarios
  This feature includes scenarios that involve simulated IOC orders.
	In a strict RWT scenario when a RWT request arrives for a size smaller than what is already filled
	the RWT request is rejected (Too late to replace). If nothing else is done eventually the order
	could be fully filled resulting in a filled size that is much greater than the desired one.
	The lax RWT flag instructs Madrigal to ACK such requests and cancel the remaining size on a 
	best effort basis.

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
	| true               | true             | false                           | true                    | true      |

@SniperOrderTriggering
Scenario: ADD received when no market data in cache => no sniper order is sent.
  At the time the stealth order is received there is no cached market data for the order instrument.
  The order is ACKed but no child order is sent to the exchange.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

@SniperOrderTriggering
Scenario: ADD received when market data price not tradable => no sniper order is sent.
  At ther time the stealth order is received there is cached market data for the order instrument but the
  TOB price is worse than the order price. The order is ACKed but no order is sent to the exchange.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

@SniperOrderTriggering
Scenario: Dormant ADD and market data arrives at tradable price => sniper order is sent.
  Initially there is no cached market data for the order instrument. An IOC order is sent to the 
  exchange when the price on the opposite side TOB matches the order price and gets fully filled 
  in one clip.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@SniperOrderTriggering
Scenario: ADD received when market data at tradable price exists => new sniper order is sent.
  Initially there is cached market data for the order instrument at the correct price. An IOC 
  order is sent to the exchange right away and gets fully filled in one clip.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@OneSniperOrderForFullFill
Scenario: Sniper order for full order size is filled in two clips.
  An IOC order is sent to the exchange right away and gets fully filled in two clips.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 101.5 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 101.5  | 5.0       | 5.0    | 101.5 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 101.5  | 5.0       | 5.0    | 101.5 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 5.0     | 102.0  | 0.0       | 10.0   | 101.75 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 0.0       | 10.0   | 101.75 |      | true   | true  |

@MultipleSniperOrdersForFullFill
Scenario: Need to send two sniper orders to get fully filled.
  The first IOC child order only partially fills the parent. As a result, a second
  child order is needed, which accomplishes the parent goal.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 5.0  | 5.0      | 102.0 | IOC |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00002 | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00002 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@AmendCancelAfterSniperAck
Scenario: RWT and DEL received when order is still dormant => requests are ACKed right away.
  The requests are ACKed right away and nothing is sent to exchange.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  And a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 12.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true   | true  |

@AmendCancelAfterSniperAck
Scenario: DEL request received when order is dormant and partially filled => DEL is ACKed right away.
  The first IOC child order only partially fills the parent. When the DEL request is received
  it immadiatelly cancels the order. Nothing is sent to the exchange.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

@AmendCancelAfterSniperAck
Scenario: RWT (requested > filled) is received when order is dormant and partially filled => RWT is ACKed right away.
  A new sniper child order is sent to the exchange when the price is tradable. 
  This last order is fully filled later on in two clips.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 12.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 0.0     | NaN    | 7.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 7.0  | 7.0      | 102.0 | IOC |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00002 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00002 |      4 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 5.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00003 | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      5 | x0-00003 |      5 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 2.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@AmendCancelAfterSniperAck
Scenario: RWT (requested = filled) is received when order is dormant and partially filled => order is completed right away.
  The original order is completed right away and no other order is sent to the exchange.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 5.0 | 0.0      | 0.0     | NaN    | 0.0       | 5.0    | 102.0 |      | true   | true  |

@AmendCancelAfterSniperAck
Scenario: RWT (requested < filled) is received when order is dormant and partially filled => RWT is rejected and order is eventually filled. Strict RWT.
  Since strictRwt is true the RWT is rejected and the order is eventually filled to its initial size.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 3.0  | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 3.0 | 0.0      | 0.0     | NaN    | -2.0      | 5.0    | 102.0 | Too late to replace | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 5.0  | 5.0      | 102.0 | IOC |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00002 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00002 |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@LaxRwt
@AmendCancelAfterSniperAck
Scenario: RWT (requested < filled) is received when order is dormant and partially filled => RWT is ACKed and remaining size is canceled. Lax RWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.5 | 10.0     |
  Then no child order is sent to exchange
  # we already have an active child order

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange
  # the market data TOB price is not tradable at the order price

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 3.0  | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 3.0 | 0.0      | 0.0     | NaN    | -2.0      | 5.0    | 102.0 | Too late to replace | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL is received before sniper is ACKed. DEL is NAKed and sniper fully fills order in one clip.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| DEL     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL is received before sniper is ACKed. DEL is NAKed and sniper fully fills order in two clips.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00002 | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00002 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |                         | true   | true  |
	| DEL     | NAK    | 00001 | 1   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 0.0       | 10.0   | 101.5 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL is received before sniper is ACKed. Sniper partially fills order in one clip and DEL is ACKed completing order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL is received before sniper is ACKed. Sniper partially fills order in two clips and DEL is ACKed completing order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00002 | 4.0     | 101.0  | 2.0       | 8.0    | 101.5 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00002 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 4.0     | 101.0  | 2.0       | 8.0    | 101.5 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      4 | x0-00002 | 0.0     | 0.0    | 2.0       | 8.0    | 101.5 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 2.0       | 8.0    | 101.5 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL is received before sniper is ACKed. Sniper zero fills order and DEL is ACKed completing order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 |          | 0.0     | 0.0    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (price change) is received before sniper is ACKed. Sniper fully fills order in one clip and RWT is NAKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (size increase) is received before sniper is ACKed. Sniper fully fills order in one clip and RWT is NAKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 12.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (size decrease) is received before sniper is ACKed. Sniper fully fills order in one clip and RWT is NAKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 8.0  | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 8.0  | 0.0      | 0.0     | NaN    | -2.0      | 10.0   | 102.0 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (price change) is received before sniper is ACKed. Sniper fully fills order in two clips and RWT is NAKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00002 | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00002 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |      4 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 0.0       | 10.0   | 101.5 | Order already completed | false  | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (price change) is received before sniper is ACKed. Sniper partially fills order and RWT is ACKed. New sniper is needed fo fill the amended order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 5.0  | 5.0      | 102.2 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00002 | 5.0     | 102.2  | 0.0       | 5.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00002 |      4 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 5.0     | 102.2  | 0.0       | 10.0   | 102.1 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (requested > filled, size increase) is received before sniper is ACKed. Sniper partially fills order and RWT is ACKed. New sniper is needed fo fill the amended order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 12.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 0.0     | NaN    | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 7.0  | 7.0      | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00002 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00002 |      4 | DAY         | Buy  | 102.0 | 12.0 | 0.0      | 7.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (requested > filled, size decrease) is received before sniper is ACKed. Sniper partially fills order and RWT is ACKed. New sniper is needed fo fill the amended order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 8.0  | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 8.0  | 0.0      | 0.0     | NaN    | 3.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 3.0  | 3.0      | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00002 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00002 |      4 | DAY         | Buy  | 102.0 | 8.0  | 0.0      | 3.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: RWT (requested < filled) is received before sniper is ACKed. Sniper partially fills order and RWT is NAKed (strictRwt=true). New sniper is needed fo fill the original order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 4.0  | 0.0      | 0.0     | NaN    | -1.0      | 5.0    | 102.0 | Too late to replace | false  | false |
  And no child order is sent to exchange

@AmendCancelBeforeSniperAck
Scenario: RWT (requested < filled) is received before sniper is ACKed. Sniper partially fills order and RWT is ACKed (strictRwt=false), completing the order.
	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 4.0  | 0.0      | 0.0     | NaN    | -1.0      | 5.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@AmendCancelBeforeSniperAck
Scenario: RWT (price change) is received before sniper is ACKed. Sniper is eventually zero filled. Another sniper is needed to fill the order.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 |          | 0.0     | 0.0    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 10.0 | 10.0     | 102.2 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00002 | 10.0    | 102.2  | 0.0       | 10.0   | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00002 |      3 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 10.0    | 102.2  | 0.0       | 10.0   | 102.2 |      | true   | true  |
  And no child order is sent to exchange

@AmendCancelBeforeSniperAck
Scenario: RWT, DEL are received before sniper is ACKed. RWT is rejected right away while DEL cancels the remaining size after sniper is completed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: DEL, RWT are received in the wrong order before sniper is ACKed. RWT is NAKed right away while DEL cancels remaining size after sniper is completed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text             | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      2 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL already sent | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: Two DELs are received before sniper is ACKed. Second DEL is rejected right away while the first cancels the remaining size after sniper is completed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      2 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL already sent | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      3 | x0-00001 | 0.0     | 0.0    | 5.0       | 5.0    | 102.0 | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

@AmendCancelBeforeSniperAck
Scenario: Two RWTs and one DEL are received before sniper is ACKed. RWTs are rejected right away while DEL cancels the remaining size after sniper is completed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 5.0      | 101.0 | 102.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 |  DAY        | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 10.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.2 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 3   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.1 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 0.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

