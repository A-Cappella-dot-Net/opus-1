Feature: Order Manager - Simulated Iceberg Scenarios

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
#	| true               | true             | false                           | true                    | true      |

@Iceberg
Scenario: Full fill of the first child results in a second child for the remaining size.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      3 | x0-00002 | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00002 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@Iceberg
Scenario: Partial fill of the first child results in a new child order with size equal to the partial fill.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      6 | x0-00002 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00002 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 3.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      7 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      7 | x0-00003 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@Iceberg
Scenario: Partial fills of the first child order result in multiple active child orders.
  Naively, one would think that an order for size 10 and shown 5 would result in two children of size 5.
  However, if we want to always show 5, we need to send new child orders as soon as a partial fill is received.
  This can result, like in this example, in one clip of 5 fully executed and 3 outstanding child orders
  for sizes 2, 1, and 2 in the market (00001~1-0, 00001~2-0, and 00001~3-0). This test case serves as a
  basis for a number of additional tests.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      9 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, DEL request. All child DELs are ACKed. Parent DEL is ACKed and final.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     10 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

@Iceberg
Scenario: Three active children, DEL request. One child is filled instead of DELeted. Parent DEL is still ACKed and final.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |     10 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     11 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |      | true   | true  |

@Iceberg
Scenario: Three active children, DEL request. Two children are filled instead of DELeted. Parent DEL is still ACKed and final.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |       1 |DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     12 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 2.0       | 8.0    | 102.0 |      | true   | true  |

@Iceberg
Scenario: Three active children, DEL request. All three children are filled instead of DELeted. Parent ADD is ACKed and parent DEL is NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~3-1 |     13 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@Iceberg
Scenario: Three active children, RWT request (price change). UseDelAddForPriceChange. All three children are DELeted. A new child ADD is placed.
  The RWT ACK is sent when the new child is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     10 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 5.0  | 5.0      | 102.2 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |     11 | x0-00005 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     12 | x0-00005 | 5.0     | 102.2  | 0.0       | 5.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     12 | x0-00005 |      6 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 5.0     | 102.2  | 0.0       | 10.0   | 102.1 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseDelAddForPriceChange. One child is filled rather than DELeted. A new child ADD is placed.
  The RWT ACK is sent when the new child is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |     10 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     11 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 3.0  | 3.0      | 102.2 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |     12 | x0-00005 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      6 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     13 | x0-00005 | 3.0     | 102.2  | 0.0       | 3.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     13 | x0-00005 |      7 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 3.0     | 102.2  | 0.0       | 10.0   | 102.06 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseDelAddForPriceChange. Two children are filled rather than DELeted. A new child ADD is placed.
  The RWT ACK is sent when the new child is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     12 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 2.0  | 2.0      | 102.2 | DAY |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |     13 | x0-00005 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      7 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 2.0       | 8.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     14 | x0-00005 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     14 | x0-00005 |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 2.0     | 102.2  | 0.0       | 10.0   | 102.03999999999999 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseDelAddForPriceChange. All children are filled rather than DELeted. Parent RWT is ACKed as order is fully filled.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~3-1 |     13 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@Iceberg
Scenario: Three active children, RWT request (price change). UseRwtForPriceChange. All child RWT are ACKed and eventually filled.
	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.2 | DAY |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~3-1 |     10 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-0 |     11 | x0-00002 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     11 | x0-00002 |      6 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 2.0     | 102.2  | 3.0       | 7.0    | 102.05714285714285 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |     12 | x0-00003 | 1.0     | 102.2  | 0.0       | 1.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     12 | x0-00003 |      7 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 1.0     | 102.2  | 2.0       | 8.0    | 102.075 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~3-0 |     13 | x0-00004 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     13 | x0-00004 |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 2.0     | 102.2  | 0.0       | 10.0   | 102.1 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseRwtForPriceChange. One child is filled at the original price. Other RWTs are ACKed and eventually filled.
	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.2 | DAY |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |     10 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~3-1 |     11 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      6 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |     12 | x0-00003 | 1.0     | 102.2  | 0.0       | 1.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     12 | x0-00003 |      7 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 1.0     | 102.2  | 2.0       | 8.0    | 102.025 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~3-0 |     13 | x0-00004 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     13 | x0-00004 |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 2.0     | 102.2  | 0.0       | 10.0   | 102.06 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseRwtForPriceChange. Two children are filled at the original price. One RWTs is ACKed and eventually filled.
	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange |
	| false                   |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.2 | DAY |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~3-1 |     12 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      7 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 2.0       | 8.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~3-1 |     13 | x0-00004 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     13 | x0-00004 |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 2.0     | 102.2  | 0.0       | 10.0   | 102.03999999999999 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseRwtForPriceChange. All children are filled at the original price. StricRWT. Parent RWT is NAKed.
	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange | strictRwt |
	| false                   | true      |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.2 | DAY |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~3-1 |     13 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004' | false |
	Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (price change). UseRwtForPriceChange. All children are filled at the original price. LaxRWT. Parent RWT is ACKed.
	Given the OrderManagerService is further configured with
	| useDelAddForPriceChange | strictRwt |
	| false                   | false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.2 | DAY |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 | 2.0      | 102.2 | DAY |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~3-1 |     13 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004' | false |
	Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@Iceberg
Scenario: Three active children, RWT request (size increase). Parent RWT is ACKed right away. New child is sent when 'shown' allows.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 13.0 | 5.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 0.0     | NaN    | 8.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 2.0     | 102.0  | 6.0       | 7.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |      9 | x0-00005 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 1.0     | 102.0  | 5.0       | 8.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~5-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~5-0 |     11 | x0-00006 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     12 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 2.0     | 102.0  | 3.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     13 | x0-00005 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     13 | x0-00005 |      9 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 2.0     | 102.0  | 1.0       | 12.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~5-0 |     14 | x0-00006 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     14 | x0-00006 |     10 | DAY         | Buy  | 102.0 | 13.0 | 5.0      | 1.0     | 102.0  | 0.0       | 13.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to above fillable). Parent RWT is ACKed right away. New child is sent when 'shown' allows.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 11.0 | 5.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 0.0     | NaN    | 6.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 2.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |      9 | x0-00005 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     11 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     11 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 2.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     12 | x0-00005 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     12 | x0-00005 |      9 | DAY         | Buy  | 102.0 | 11.0 | 5.0      | 1.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to fillable). Parent RWT is ACKed right away. All children are filled and no new child is sent.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 10.0 | 5.0      |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      9 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 1.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). The latest child is successfully RWTen. Parent RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 1.0  | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 0.0     | NaN    | 4.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      9 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      9 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 2.0     | 102.0  | 2.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 1.0     | 102.0  | 1.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~3-1 |     11 | x0-00004 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     11 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 1.0     | 102.0  | 0.0       | 9.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). StrictRWT. The latest child is filled rather than RWTen. Parent RWT is NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 1.0  | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      9 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | done  |
	| RWT     | NAK    | 00001~3-1 |     11 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004'| true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 0.0     | NaN    | -1.0      | 10.0   | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |     12 | x0-00005 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     13 | x0-00005 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     13 | x0-00005 |      9 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). LaxRWT. The latest child is filled rather than RWTen. Parent RWT is AACKed.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 9.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 1.0  | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      9 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | done  |
	| RWT     | NAK    | 00001~3-1 |     11 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004'| true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 9.0  | 5.0      | 0.0     | NaN    | -1.0      | 10.0   | 102.0 | Too late to replace | true   | true  |

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). The latest child is DELeted. Parent RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 8.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 8.0  | 5.0      | 0.0     | NaN    | 3.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      9 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      9 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 8.0  | 5.0      | 2.0     | 102.0  | 1.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 8.0  | 5.0      | 1.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). StrictRWT. The latest child is filled rather than DELeted. Parent RWT is NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 8.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      9 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | done  |
	| DEL     | NAK    | 00001~3-1 |     11 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004'| true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 8.0  | 5.0      | 0.0     | NaN    | -2.0      | 10.0   | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |     12 | x0-00005 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     13 | x0-00005 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     13 | x0-00005 |      9 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). LaxRWT. The latest child is filled rather than DELeted. Parent RWT is ACKed.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 8.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      9 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      9 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | done  |
	| DEL     | NAK    | 00001~3-1 |     11 | x0-00004 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004'| true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 8.0  | 5.0      | 0.0     | NaN    | -2.0      | 10.0   | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). The latest two children are DELeted. Parent RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 7.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 7.0  | 5.0      | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |     10 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     10 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 7.0  | 5.0      | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below fillable but above filled). Two children are DELeted and one is RWTen. Parent RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 6.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |          |       |     |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0  | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |     10 | x0-00002 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 6.0  | 5.0      | 0.0     | NaN    | 1.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-1 |     11 | x0-00002 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |     11 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 6.0  | 5.0      | 1.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to filled). All children are DELeted. Parent RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |     10 | x0-00002 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 0.0       | 5.0    | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below filled). StrictRWT. Parent RWT is NAKed right away. The order is eventually fully filled.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -1.0      | 5.0    | 102.0 | Too late to replace | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~4-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~4-0 |      9 | x0-00005 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     11 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     11 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

    When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~4-0 |     12 | x0-00005 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00005 |      9 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 0.0       | 12.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: RWT (requested < filled) results in all children being successfully DELeted. RWT is ACKed since strictRwt is false.
	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |     10 | x0-00002 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -1.0      | 5.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@Iceberg
Scenario: Three active children, RWT request (size decrease to below filled). LaxRWT. All active children are DELeted. Parent RWT is ACKed. Over fill.
	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     10 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      5 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -1.0      | 5.0    | 102.0 | Too late to replace | true   | true  |

@Iceberg
Scenario: Three active children, RWT request (size decrease to below filled). LaxRWT. One active child is filled instead of being DELeted. Parent RWT is ACKed. Over fill.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |     10 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     11 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      6 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -3.0      | 7.0    | 102.0 | Too late to replace | true   | true  |

@Iceberg
Scenario: Three active children, RWT request (size decrease to below filled). LaxRWT. Two active children are filled instead of being DELeted. Parent RWT is ACKed. Over fill.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~3-1 |     12 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      7 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -4.0      | 8.0    | 102.0 | Too late to replace | true   | true  |

@Iceberg
Scenario: Three active children, RWT request (size decrease to below filled). LaxRWT. All active children are filled instead of being DELeted. Parent RWT is ACKed. Over fill.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 12.0 | 5.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 5.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 3.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 10.0      | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~1-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~1-0 |      3 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 1.0     | 102.0  | 2.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 9.0       | 3.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~2-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~2-0 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 2.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      6 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 7.0       | 5.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 4.0  | 4.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0  |
	| DEL     | 00001~3-1 | 00001~3-0   | x0-00004 | Buy  | 2.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      8 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 5.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |     10 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     10 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 1.0     | 102.0  | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |     11 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     12 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |     12 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 12.0 | 5.0      | 2.0     | 102.0  | 2.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~3-1 |     13 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00004' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      8 | DAY         | Buy  | 102.0 | 4.0  | 4.0      | 0.0     | NaN    | -6.0      | 10.0   | 102.0 | Too late to replace | true   | true  |

@Iceberg
@BurstMode
@EdgeCase
Scenario: An iceberg ADD request followed by three RWTs and a DEL in burst mode with conflateRequests flag set.
  After the child ADD is ACKed the conflated DEL is sent but it crosses with the child ADD full FILL.
  After the child DEL ACK is received the parent DEL is ACKed and the parent is partially FILLed.

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

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 4   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      3 | DAY         | Buy  | 102.1 | 12.0 | 3.0      | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      4 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 3.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 4   |        |          |      6 | DAY         | Buy  | 102.0 | 7.0  | 3.0      | 0.0     | NaN    | 4.0       | 3.0    | 102.0 |      | true   | true  |

