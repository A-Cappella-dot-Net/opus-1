Feature: Order Manager - miscellaneous scenarios


Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
	| true               | true             | false                           | true                    | true      |

@EdgeCases
Scenario: DEL request received for non existing order (may have expired from cache).

  When a parent order is received from client
	| reqType | ordId | ver | ecnOrdId | timeInForce | side | price | qty  | shownQty |
	| DEL     | 00001 | 1   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                       | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Non existent order '00001' | true   | true  |

@EdgeCases
Scenario: RWT request received for non existing order (may have expired from cache).

  When a parent order is received from client
	| reqType | ordId | ver | ecnOrdId | timeInForce | side | price | qty  | shownQty |
	| RWT     | 00001 | 1   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                       | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Non existent order '00001' | true   | true  |

@EdgeCases
Scenario: Bad static for instrId.5: Child ADD NAK results in fail fast parent NAK.

  When a parent order is received from client
	| instrId   | reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| instrId.5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.5  | 7.5      | false     |
  Then one or more children orders are sent to exchange
	| symbol       | reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ecnInstrId.5 | ADD     | 00001~0-0 | Buy  | 7.5  | 7.5      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| ecnInstrId   | reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text             | done  |
	| ecnInstrId.5 | ADD     | NAK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.5       | 0.0    | 0.0   | Invalid Quantity | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId   | ecnInstrId   | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | ftDone | done  |
	| instrId.5 | ecnInstrId.5 | ADD     | NAK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.5  | 7.5      | 0.0     | NaN    | 7.5       | 0.0    | 0.0   | Invalid Quantity  | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Bad static for instrId5: Child ADD NAK results in fail fast parent NAK.

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| instrId5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ecnInstrId5 | ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| ecnInstrId  | reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text             | done  |
	| ecnInstrId5 | ADD     | NAK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Quantity | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | NAK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Quantity  | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario Outline: Order with initial size less than min quantity

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | timeInForce | side | price | qty   | shownQty | useNative |
	| instrId5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | <qty> | 2.0      | false     |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty   | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                            | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | NAK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | <qty> | 2.0      | 0.0     | NaN    | <qty>     | 0.0    | 0.0   | residual less than min quantity | true   | true  |
  And no child order is sent to exchange

Examples:
  | qty |
  | 2.0 |
  | 3.0 |
  | 5.0 |
  | 6.0 |

@EdgeCases
Scenario: Order for size equal to min quantity is amended (price and size up). The fill and amend request cross. The amend ends up being rejected.

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| instrId5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 5.0  | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ecnInstrId5 | ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | price  | qty  | shownQty |
	| instrId5 | RWT     | 00001 | 1   | 102.01 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| ecnInstrId5 | RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  | 7.0      | 102.01 | DAY |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| instrId5 | ecnInstrId5 | RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.01 | 7.0  | 7.0      | 0.0     | NaN    | 2.0       | 5.0    | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Order for size equal to min quantity is amended (price and size up). A partial fill is received and then the amend ACK is received. The order is fully filled.

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| instrId5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 5.0  | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ecnInstrId5 | ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | price  | qty  | shownQty |
	| instrId5 | RWT     | 00001 | 1   | 102.01 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| ecnInstrId5 | RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  | 7.0      | 102.01 | DAY |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 1.0     | 102.0  | 4.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 1.0     | 102.0  | 4.0       | 1.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 6.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.01 | 7.0  | 7.0      | 0.0     | NaN    | 6.0       | 1.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx      | text | done  |
	| RWT     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.01 | 0.0       | 7.0    | 102.008571 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.01 | 7.0  | 7.0      | 6.0     | 102.01 | 0.0       | 7.0    | 102.008571428 |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario Outline: Order for size equal to min quantity is ACKed. A (price and) size amend request is received.
  The size increment is less than the minQty and only in the invisible part (order type changes from non iceberg to iceberg).
  Due to this restriction the exchange order is amended up and shows the full size (non iceberg). The iceberg restriction is thus not honored.
  A partial fill is received for the original order and then the remaining size is filled at the amend price. The order is fully filled.

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| instrId5 | ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 5.0  | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ecnInstrId5 | ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| instrId  | reqType | ordId | ver | price   | qty  | shownQty |
	| instrId5 | RWT     | 00001 | 1   | <rwtPx> | 7.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| symbol      | reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px      | tif |
	| ecnInstrId5 | RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  | 7.0      | <rwtPx> | DAY |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 1.0     | 102.0  | 4.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 1.0     | 102.0  | 4.0       | 1.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 6.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price   | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | <rwtPx> | 7.0  | 5.0      | 0.0     | NaN    | 6.0       | 1.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx  | leavesQty | cumQty | avgPx    | text | done  |
	| RWT     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | <rwtPx> | 0.0       | 7.0    | <xAvgPx> |      | true  |
  Then one or more execution reports are sent to client for parent order
	| instrId  | ecnInstrId  | reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price   | qty  | shownQty | lastQty | lastPx  | leavesQty | cumQty | avgPx    | text | ftDone | done  |
	| instrId5 | ecnInstrId5 | RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | <rwtPx> | 7.0  | 5.0      | 6.0     | <rwtPx> | 0.0       | 7.0    | <cAvgPx> |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rwtPx  | xAvgPx     | cAvgPx        |
  | 102.0  | 102.0      | 102.0         |
  | 102.01 | 102.008571 | 102.008571428 |

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in DEL for all children. First child DEL is NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      2 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      7 |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 | Fail Fast | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in DEL for all children. First two children DELs are NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      2 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  # In case of multiple failures, only the first one is reflected in the order flow
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      7 |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      8 |          |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 | Fail Fast | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in RWT for all children. All child RWTs are NAKed. Wind down DELs are all ACKed.

	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      1 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 | 2.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Price | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Invalid Price | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-2 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-2 | 00001~2-0   | x0-00003 | Buy  | 2.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      7 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-2 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-2 |      9 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | DONE   | 00001 | 2   |        |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Fail Fast | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in RWT for all children. All child RWTs are NAKed. One wind down DEL is NAKed.

	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      2 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 | 2.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Price | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Invalid Price | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-2 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-2 | 00001~2-0   | x0-00003 | Buy  | 2.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      7 |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-2 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-2 |      9 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-2 |     10 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | DONE   | 00001 | 2   |        |          |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 4.0       | 7.0    | 102.0 | Fail Fast | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in RWT for all children. All child RWTs are NAKed. Two wind down DELs are NAKed.

	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      2 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 | 2.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Price | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Invalid Price | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-2 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-2 | 00001~2-0   | x0-00003 | Buy  | 2.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      7 |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-2 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      9 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 |          |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-2 |     10 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-2 |     11 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | DONE   | 00001 | 2   |        |          |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 2.0       | 9.0    | 102.0 | Fail Fast | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: Fail Fast. Three active children. RWT results in RWT for all children. All child RWTs are NAKed. All wind down DELs are NAKed.

	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      2 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      3 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      3 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 11.0 | 11.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 | 2.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   | Invalid Price | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | Invalid Price | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	| DEL     | 00001~1-2 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-2 | 00001~2-0   | x0-00003 | Buy  | 2.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text          | done  |
	| RWT     | NAK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Invalid Price | false |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      7 |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-2 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      9 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 |          |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 | Fail Fast | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-2 |     10 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     11 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |     11 |          |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 | Fail Fast | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-2 |     12 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text      | ftDone | done  |
	| RWT     | DONE   | 00001 | 2   |        |          |      8 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 0.0     | NaN    | 0.0       | 11.0   | 102.0 | Fail Fast | false  | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: DelNakRetryManager is disabled. Native DEL request is NAKed. The NAK is passed back to the client. The order is eventually filled.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: DelNakRetryManager is enabled. The exchange NAKs the original DEL request and the DEL is retried.
  A fill crosses the DEL retry which is NAKed by the exchange and a NAK for the original DEL is passed back
  to the client.

	Given the OrderManagerService is further configured with
	| delRetryType | delRetryConstant |
	| COUNT        | 2                |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001-2 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

Scenario: DelNakRetryManager is enabled and configured for two attempts. The original native DEL request and the first DEL retry 
  are NAKed and the DEL is retried. No NAK is passed back to the client at this time. The second retried DEL request is also 
  NAKed but this time the NAK is passed back to the client. A fill is eventually received for the original order and passed 
  back to the client as well.

	Given the OrderManagerService is further configured with
	| delRetryType | delRetryConstant |
	| COUNT        | 2                |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-3 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      5 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      5 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: DelNakRetryManager is enabled and configured for two attempts. The original native DEL request and the first DEL retry 
  are NAKed and the DEL is retried. No NAK is passed back to the client at this time. The second retried DEL request is ACKed 
  and the ACK is passed back to the client.

	Given the OrderManagerService is further configured with
	| delRetryType | delRetryConstant |
	| COUNT        | 2                |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-3 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
Scenario: DelNakRetryManager is enabled and configured for two attempts. The original native DEL request and the first DEL retry 
  are NAKed and the DEL is retried. No NAK is passed back to the client at this time. The second retried DEL request is also 
  NAKed but this time the NAK is passed back to the client. A subsequenct client DEL request is ACKed which concludes the order.

	Given the OrderManagerService is further configured with
	| delRetryType | delRetryConstant |
	| COUNT        | 2                |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-3 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-4 | 00001-0     | x0-00001 | Buy  | 10.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-4 |      5 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

@EdgeCases
Scenario: DelNakRetryManager is enabled and configured for two attempts. The original native DEL request and the first DEL retry 
  are NAKed and the DEL is retried. No NAK is passed back to the client at this time. The second retried DEL request is also 
  NAKed but this time the NAK is passed back to the client. A subsequenct client RWT request to size 1 is ACKed and the amended 
  order is filled (smaller size than if RWT were not requested).

	Given the OrderManagerService is further configured with
	| delRetryType | delRetryConstant |
	| COUNT        | 2                |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | done  |
	| DEL     | NAK    | 00001-3 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Too Soon to Cancel | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 1.0  | 1.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-4 | 00001-0     | x0-00001 | Buy  | 1.0  | 1.0      | 102.0 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-4 |      5 | x0-00001 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 1.0 | 1.0      | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001-4 |      6 | x0-00001 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 1.0 | 1.0      | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
@EdgeCases
@ConflateRequests
Scenario: An iceberg ADD request followed by three RWTs in burst mode with conflateRequests flag set.
  After the child ADD is ACKed both the the original parent ADD and the last parent RWT are ACKed 
  as there is no price change and the displayed size does not change. At this time no child request 
  is sent to exchange. Eventually the order is filled in four clips.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 3.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 2.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 5.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | DAY         | Buy  | 102.0 | 9.0  | 2.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.0 | 12.0 | 3.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      2 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      3 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 12.0 | 3.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      2 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 12.0 | 3.0      | 3.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      4 | x0-00001 |      6 | DAY         | Buy  | 102.0 | 12.0 | 3.0      | 3.0     | 102.0  | 6.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00001 |      7 | DAY         | Buy  | 102.0 | 12.0 | 3.0      | 3.0     | 102.0  | 3.0       | 9.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      8 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00001 |      8 | DAY         | Buy  | 102.0 | 12.0 | 3.0      | 3.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
@EdgeCases
@ConflateRequests
Scenario: An iceberg ADD request followed by three RWTs in burst mode with conflateRequests flag set.
  After the child ADD is ACKed a child RWT is sent to the exchange as there is a price change.
  This request crosses with the child ADD full FILL which triggers the iceberg to re-load. The 
  subsequent RWT NAK is ignored and the new child ADD ACK is used to ACK the parent RWT.
  Eventually the order gets fuly filled in four clips.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 3.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 2.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.0 | 11.0 | 5.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | DAY         | Buy  | 102.0 | 9.0  | 2.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.1 | 12.0 | 3.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      2 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 0.0     | NaN    | 11.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      3 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 3.0 | 3.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 3.0  | 3.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.1 | 12.0 | 3.0      | 0.0     | NaN    | 9.0       | 3.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00001 | 3.0     | 102.1  | 0.0       | 3.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      4 | x0-00001 |      6 | DAY         | Buy  | 102.1 | 12.0 | 3.0      | 3.0     | 102.1  | 6.0       | 6.0    | 102.05 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 3.0  | 3.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00001 | 3.0     | 102.1  | 0.0       | 3.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00001 |      7 | DAY         | Buy  | 102.1 | 12.0 | 3.0      | 3.0     | 102.1  | 3.0       | 9.0    | 102.066666666 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 3.0  | 3.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      8 | x0-00001 | 3.0     | 102.1  | 0.0       | 3.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00001 |      8 | DAY         | Buy  | 102.1 | 12.0 | 3.0      | 3.0     | 102.1  | 0.0       | 12.0   | 102.075 |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: Initial ADD sniper order is not executable but is ACKed right away. The first RWT makes it executable
  and a child order is sent to the exchange. This request is ACKed immendiately as well. Subsequent burst RWT requests
  are superseded until the child order is zero filled (DONE), at which time the latest RWT request is ACKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 8.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Sell | 102.1 | 17.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Sell | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Sell | 3.0  | 3.0      | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 18.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      3 | DAY         | Sell | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 16.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Sell | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 19.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 3.0       | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 4   |        |          |      5 | DAY         | Sell | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      | false  | false |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: Initial ADD sniper order is not executable but is ACKed right away. The first RWT makes it executable
  and a child order is sent to the exchange. This request is ACKed immendiately as well. Subsequent burst RWT requests
  are superseded until the child order is FILLed, at which time the parent sniper order is partially FILLed and 
  the latest RWT request is ACKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 8.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Sell | 102.1 | 17.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Sell | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Sell | 3.0  | 3.0      | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 18.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      3 | DAY         | Sell | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 16.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Sell | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 19.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      2 | x0-00001 |      5 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 3.0     | 102.0  | 15.0      | 3.0    | 102.0 |      | false  | false |
	| RWT     | ACK    | 00001 | 4   |        |          |      6 | DAY         | Sell | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | 12.0      | 3.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: Initial ADD sniper order is not executable but is ACKed right away. The first RWT makes it executable
  and a child order is sent to the exchange. This request is ACKed immendiately as well. Subsequent burst RWT requests
  are superseded and a final DEL request is ACKed when the child order is zero filled (DONE).

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 8.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Sell | 102.1 | 17.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Sell | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Sell | 3.0  | 3.0      | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 18.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      3 | DAY         | Sell | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 16.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Sell | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 19.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 5   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 4   |        |          |      5 | DAY         | Sell | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | 15.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 3.0       | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 5   |        |          |      6 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 18.0      | 0.0    | NaN   |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: Initial ADD sniper order is not executable but is ACKed right away. The first RWT makes it executable
  and a child order is sent to the exchange. This request is ACKed immendiately as well. Subsequent burst RWT requests
  are superseded and a final DEL request is ACKed when the child order is fully filled (DONE). The parent sniper order 
  is partially FILLed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 8.0      |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Sell | 102.1 | 17.0 | 0.0      | true      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Sell | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Sell | 3.0  | 3.0      | 102.0 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 18.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      3 | DAY         | Sell | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 16.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      4 | DAY         | Sell | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 19.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 5   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 4   |        |          |      5 | DAY         | Sell | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | 15.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      2 | x0-00001 |      6 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 3.0     | 102.0  | 15.0      | 3.0    | 102.0 |      | false  | false |
	| DEL     | ACK    | 00001 | 5   |        |          |      7 | DAY         | Sell | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 15.0      | 3.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: The initial ADD sniper order is executable, sends an IOC order to exchange, and is ACKed right away.
  The next RWT request is queued until the child ADD is partially filled, at which point the order is no longer
  executable but the RWT request is ACKed nonetheless. Since there is no pending request the next RWT is ACKed 
  right away and since the order is now executable a new child IOC is sent to exchange. A third RWT request is
  received and since there is a pending child request the RWT is queued. After the latest IOC order is ACKed
  but before it is fully FILLed a fourth RWT request arrives which supersedes the third request. After the IOC
  order is fully FILLed the fourth RWT request is NAKed.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.1 | 17.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 12.0 | 12.0     | 102.1 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.1  | 2.0       | 10.0   | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.1 | 17.0 | 0.0      | 10.0    | 102.1  | 7.0       | 10.0   | 102.1 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 12.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 8.0       | 10.0   | 102.1 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 6.0  | 6.0      | 102.1 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      4 | DAY         | Buy  | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 6.0       | 10.0   | 102.1 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 9.0       | 10.0   | 102.1 | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00001 | 6.0     | 102.1  | 0.0       | 6.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      6 | DAY         | Buy  | 102.1 | 16.0 | 0.0      | 6.0     | 102.1  | 0.0       | 16.0   | 102.1 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 4   |        |          |      7 | DAY         | Buy  | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | -1.0      | 16.0   | 102.1 | Order already completed | false  | true  |
  And no child order is sent to exchange

@EdgeCases
@ConflateRequests
@Sniper
Scenario: The initial ADD sniper order is executable, sends an IOC order to exchange, and is ACKed right away.
  The next RWT request is queued until the child ADD is partially filled, at which point the order is no longer
  executable but the RWT request is ACKed nonetheless. Since there is no pending request the next RWT is ACKed 
  right away and since the order is now executable a new child IOC is sent to exchange. A third RWT request is
  received and since there is a pending child request the RWT is queued. As the latest IOC order makes the
  original order fully filled the queued RWT request is NAKed. A further RWT request is NAKed as well.

  When a market data snapshot is received from exchange
  | bidSize0 | bid0  | ask0  | askSize0 |
  | 3.0      | 102.0 | 102.1 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.1 | 17.0 | 0.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 12.0 | 12.0     | 102.1 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.1 | 17.0 | 0.0      | 0.0     | NaN    | 17.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 18.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.1  | 2.0       | 10.0   | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.1 | 17.0 | 0.0      | 10.0    | 102.1  | 7.0       | 10.0   | 102.1 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001~0-0 |      2 | x0-00001 | 0.0     | 0.0    | 12.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 18.0 | 0.0      | 0.0     | NaN    | 8.0       | 10.0   | 102.1 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.1 | 16.0 | 0.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 6.0  | 6.0      | 102.1 | IOC |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        |          |      4 | DAY         | Buy  | 102.1 | 16.0 | 0.0      | 0.0     | NaN    | 6.0       | 10.0   | 102.1 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 3   | 102.2 | 19.0 | 0.0      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      4 | x0-00001 | 6.0     | 102.1  | 0.0       | 6.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      5 | DAY         | Buy  | 102.1 | 16.0 | 0.0      | 6.0     | 102.1  | 0.0       | 16.0   | 102.1 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.2 | 19.0 | 0.0      | 0.0     | NaN    | 3.0       | 16.0   | 102.1 | Order already completed | false  | true  |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 4   | 102.1 | 15.0 | 0.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 4   |        |          |      7 | DAY         | Buy  | 102.1 | 15.0 | 0.0      | 0.0     | NaN    | -1.0      | 16.0   | 102.1 | Order already completed | false  | true  |

