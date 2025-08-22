Feature: Order Manager - Failover Scenarios
	This feature includes scenarios that test failover edge cases.
	Notice that we never get RWT NAK or DEL NAK as a starting state (just before failover) because of the way the cache processes 
	these messages (just removes the request from the queued list).

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt | actionOnFailover |
	| true               | true             | false                           | true                    | true      | ALWAYS_CANCEL    |
  And the OrderManagerService is activated with execId 1000

Scenario: A fully FILLed ADD order is only finalized.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And no execution report is sent to client

Scenario: A fully FILLed RWT order is only finalized.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 0   |      2 | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And no execution report is sent to client

Scenario: A DELeted order is only finalized.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true   | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And no execution report is sent to client

Scenario: Simulated iceberg corner case after failover.
  Quantity is adjusted up and Shown Quantity is adjusted down. The displayed quantity in the market is at the new Shown Quantity level so no action is taken.

	Given the OrderManagerService is further configured with
	| actionOnFailover |
	| ALWAYS_RESUME    |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| RWT     | FILL   | 00001 | 1   |      1 | x0-00001 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 2.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false  | false | false     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID     | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0~0-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0~0-0 |      2 | x0-00001 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 9.0  | 2.0      |
  Then no child order is sent to exchange
  # the desired shown quantity is already displayed in the market
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |   1001 | DAY         | Buy  | 102.0 | 9.0  | 2.0      | 0.0     | NaN    | 4.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0~0-0 |      3 | x0-00001 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      3 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 9.0  | 2.0      | 2.0     | 102.0  | 2.0       | 7.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID     | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0~1-0 |      4 | x0-00001 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 9.0  | 2.0      | 2.0     | 102.0  | 0.0       | 9.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Scenario: Simulated iceberg after failover. Native mode is preserved.

	Given the OrderManagerService is further configured with
	| actionOnFailover |
	| ALWAYS_RESUME    |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| RWT     | FILL   | 00001 | 1   |      1 | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 3.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false | false     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID     | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0~0-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0~0-0 |      2 | x0-00001 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0~0-0 |      3 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      3 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 3.0      | 3.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID     | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId     | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0~1-0 |      4 | x0-00001 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 3.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

