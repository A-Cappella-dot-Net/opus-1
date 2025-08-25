Feature: Order Manager - Failover Scenarios
	This feature includes scenarios that test failover when the OMS is configured to ALWAYS_RESUME.

	Basic Use Cases:
	State From Cache: 1 to 4
	1) ADD no ACK -> failover
	2) ADD ACK -> failover
	3) partial FILL (ADD FILL or RWT ACK) -> failover
	Unprocessed FILLs: X to Z
	X) no unprocessed FILL
	Y) partial unprocessed FILL
	Z) full unprocessed FILL
	Queued Requests: A to D
	A) no queued Request
	B) RWT
	C) DEL
	D) RWT and DEL; may require shortcut mode / non shortcut mode sub cases
  Taking combinations of these basic use cases results in 36 tests.

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt | actionOnFailover |
	| true               | true             | false                           | true                    | true      | ALWAYS_RESUME    |
  And the OrderManagerService is activated with execId 1000


Scenario: 1XA: Simplest case.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |


Scenario: 1XB-1: Non shortcut mode. The RWT request crosses with a full FILL.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 12.0 | 12.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange


Scenario: 1XB-2: Non shortcut mode. Partial FILL for the original ADD. RWT request ultimately results in full FILL.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 12.0 | 12.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx    | text | done  |
	| RWT     | FILL   | 00001~0-1 |      4 | x0-00001 | 10.0    | 102.1  | 0.0       | 12.0   | 102.0833 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |   1004 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 10.0    | 102.1  | 0.0       | 12.0   | 102.083333333 |      | true   | true  |

Scenario: 1XB-3: Shortcut mode. The ADD is superseded while the RWT is ACKed and later fully FILLed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 12.0 | 12.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| ADD     | NAK    | 00001 | 0   |        |          |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | ADD superseded | false  | false |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |                | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 12.0    | 102.1  | 0.0       | 12.0   | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      2 | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 12.0    | 102.1  | 0.0       | 12.0   | 102.1 |      | true   | true  |

Scenario: 1YA-1: After failover order picks up from where it left off and fills in one clip.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 8.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |   1003 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |


Scenario: 1YA-2: After failover order picks up from where it left off and fills in two clips.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 2.0     | 102.0  | 6.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |   1003 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |   1004 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |


Scenario: 1YB-1: Shortcut mode. RWT is fully FILLed for the remainder of the size.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 6.0       | 6.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 6.0     | 102.1  | 0.0       | 6.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      3 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 6.0     | 102.1  | 0.0       | 12.0   | 102.05 |      | true   | true  |

Scenario: 1YB-2: Non Shortcut mode. RWT is fully FILLed for the remainder of the size.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 4.0  | 4.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0  | 6.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
  | RWT     | ACK    | 00001 | 1   |        | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 6.0       | 6.0    | 102.0  |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      4 | x0-00001 | 6.0     | 102.1  | 0.0       | 6.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
  | RWT     | FILL   | 00001 | 1   |      4 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 6.0     | 102.1  | 0.0       | 12.0   | 102.05 |      | true   | true  |

Scenario Outline: 1YB-3: Shortcut mode. RWT quantity is less than / equal to the quantity already filled.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty      | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0     | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | <rwtQty> | <rwtQty> |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status      | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty      | shownQty | lastQty | lastPx | leavesQty      | cumQty | avgPx | text      | ftDone | done  |
	| ADD     | ACK         | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0     | 10.0     | 0.0     | NaN    | 10.0           | 0.0    |   0.0 |           | false  | false |
	| ADD     | FILL        | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0     | 10.0     | 6.0     | 102.0  | 4.0            | 6.0    | 102.0 |           | false  | false |
	| RWT     | <rwtStatus> | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.1 | <rwtQty> | <rwtQty> | 0.0     | NaN    | <nakLeavesQty> | 6.0    | 102.0 | <rwtText> | <done> | <done> |

Examples:
  | rwtQty | nakLeavesQty | rwtStatus | rwtText             | done  |
  | 5.0    | -1.0         | NAK       | Too late to replace | false |
  | 6.0    | 0.0          | ACK       |                     | true  |

Scenario: 1YB-4: Non Shortcut mode. Strict RWT. RWT quantity is less than the quantity already filled.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 5.0  | 5.0      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 4.0  | 4.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.1 | 5.0 | 5.0      | 0.0     | NaN    | -1.0      | 6.0    | 102.0 | Too late to replace | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 4.0     | 102.0  | 0.0       | 4.0    | 102.0 |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 | 1004   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

Scenario: 1YB-5: Non Shortcut mode. Lax RWT. RWT quantity is less than the quantity already filled.
	Given the OrderManagerService is further configured with
	| conflateRequests | strictRwt |
	| false            | false     |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 5.0  | 5.0      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 4.0  | 4.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 4.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 5.0  | 5.0      | 0.0     | NaN    | -1.0      | 6.0    | 102.0 |      | true   | true  |

Scenario: 1YB-6: Non Shortcut mode. Lax RWT. RWT quantity is less than the quantity already filled. Crossing FILL and DEL request.
	Given the OrderManagerService is further configured with
	| conflateRequests | strictRwt |
	| false            | false     |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 5.0  | 5.0      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 4.0  | 4.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 4.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 4.0     | 102.0  | 0.0       | 4.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      4 |          | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1004   | DAY         | Buy  | 102.1 | 5.0  | 5.0      | 0.0     | NaN    | -5.0      | 10.0   | 102.0 | Order already completed | false  | true  |


Scenario: 1YC-1: Non Shortcut Mode. DEL is ACKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      2 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
  | DEL     | ACK    | 00001 | 1   |        | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |      | true   | true  |

Scenario: 1YC-2: Shortcut Mode. DEL is ACKed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  | DEL     | ACK    | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |      | true   | true  |


Scenario: 1ZA: Order continues from where it left off.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |      | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  Then no child order is sent to exchange

Scenario: 1ZC: DEL is NAKed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| DEL     | NAK    | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  Then no child order is sent to exchange

Scenario Outline: 1ZD: Shortcut mode. RWT and DEL are NAKed. DEL goal is the last ACKed goal.
	Given the OrderManagerService is further configured with
	| conflateRequests   |
	| <conflateRequests> |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | 2   |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      1 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    |   0.0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      1 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | <nakText>               | false  | true  |
	| DEL     | NAK    | 00001 | 2   |        |          | 1004   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  Then no child order is sent to exchange

Examples:
  | conflateRequests | nakText                 |
  | false            | Order already completed |
  | true             | RWT superseded          |

Scenario Outline: 2XA-1: An ACKed ADD/zero filled RWT is resumed and fully FILLed in one clip.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2XA-2: An ACKed ADD/zero filled RWT is resumed and fully FILLed in two clips.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      3 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2XA-3: An ACKed ADD/zero filled RWT is resumed and partially FILLed before a DEL request is received. The DEL request and the remaining FILL cross.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver   |
	| DEL     | 00001 | <vp1> |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      3 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      4 |          | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | <vp1> |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2XA-4: An ACKed ADD/zero filled RWT is resumed and partially FILLed before a DEL request is received and ACKed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver   |
	| DEL     | 00001 | <vp1> |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 4.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp1> |        | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 6.0       | 4.0    | 102.0 |      | true   | true  |

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario: 2XB: A queued RWT is accepted and filled in two clips.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 12.0 | 12.0     | 102.1 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 | 1001   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 102.1  | 8.0       | 4.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 4.0     | 102.1  | 8.0       | 4.0    | 102.1 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 8.0     | 102.1  | 0.0       | 12.0   | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      3 | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 8.0     | 102.1  | 0.0       | 12.0   | 102.1 |      | true   | true  |
  And no child order is sent to exchange

Scenario: 2XC-1: Shortcut Mode.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

Scenario: 2XC-2: Non Shortcut Mode.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

Scenario: 2XD-1: Shortcut Mode.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | 2   |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1001   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT superseded | false  | false |
	| DEL     | ACK    | 00001 | 2   |        |          | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                | true   | true  |

Scenario: 2XD-2: Non Shortcut Mode.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | 2   |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 12.0 | 12.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 | 1001   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 12.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      3 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true   | true  |

Scenario Outline: 2YA-1: Order is resumed and fully FILLed in one clip.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 8.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2YA-2: Order is resumed and fully FILLed in two clips.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 2.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      3 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2YB-1: Shortcut Mode. Order is resumed and fully FILLed in two clips.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.1  | 4.0       | 6.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      4 | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 6.0     | 102.1  | 4.0       | 8.0    | 102.075 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 4.0     | 102.1  | 0.0       | 10.0   | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      5 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 4.0     | 102.1  | 0.0       | 12.0   | 102.083333333 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YB-2: Non Shortcut Mode. Order is resumed and fully FILLed in two clips. RWT is NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 2.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      5 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | <vp1> |        | x0-00001 |   1004 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YB-3: Non Shortcut Mode. RWT crosses with a partial FILL but is ultimately FILLed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 | 1003   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 4.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| RWT     | FILL   | 00001~0-1 |      6 | x0-00001 | 4.0     | 102.1  | 0.0       | 10.0   | 102.04 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      6 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 4.0     | 102.1  | 0.0       | 12.0   | 102.033333333 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YC-1: Shortcut Mode. DEL is ACKed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side |
	| DEL     | 00001 | <vp1> |             |      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v>   |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
	| DEL     | ACK    | 00001 | <vp1> |        |          | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |      | true   | true  |

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YC-2: Non Shortcut Mode. Order is resumed and fully FILLed in two clips. DEL is NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side |
	| DEL     | 00001 | <vp1> |             |      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 2.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      5 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | <vp1> |        | x0-00001 |   1004 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YC-3: Non Shortcut Mode. DEL crosses with a partial FILL but is ultimately ACKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side |
	| DEL     | 00001 | <vp1> |             |      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 2.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp1> |        | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 2.0       | 8.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2YD-1: Shortcut Mode. RWT is superseded and DEL is ACKed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <vp2> |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v>   |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |                | false  | false |
	| RWT     | NAK    | 00001 | <vp1> |        |          | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 | RWT superseded | false  | false |
	| DEL     | ACK    | 00001 | <vp2> |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |                | true   | true  |

Examples:
  | rT  | v | vp1 | vp2 |
  | ADD | 0 | 1   | 2   |
  | RWT | 1 | 2   | 3   |

Scenario Outline: 2YD-2: Non Shortcut Mode. Order is resumed and fully FILLed in two clips. RWT is NAKed and DEL is ACKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <vp2> |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 2.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      5 | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | <vp1> |        | x0-00001 |   1004 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |
	| DEL     | ACK    | 00001 | <vp2> |        |          |   1005 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 |                         | false  | true  |
  And no child order is sent to exchange

Examples:
  | rT  | v | vp1 | vp2 |
  | ADD | 0 | 1   | 2   |
  | RWT | 1 | 2   | 3   |

Scenario Outline: 2YD-3: Non Shortcut Mode. Order is resumed and partially FILLed then RWT is ACKed and fully filled. DEL is NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <vp2> |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 4.0       | 8.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| RWT     | FILL   | 00001~0-1 |      6 | x0-00001 | 4.0     | 102.1  | 0.0       | 10.0   | 102.04 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      6 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 4.0     | 102.1  | 0.0       | 12.0   | 102.033333333 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-2 |      7 |          | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | <vp2> |        |          | 1005   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 0.0       | 12.0   | 102.033333333 | Order already completed | false  | true  |

Examples:
  | rT  | v | vp1 | vp2 |
  | ADD | 0 | 1   | 2   |
  | RWT | 1 | 2   | 3   |

Scenario Outline: 2YD-4: Non Shortcut Mode. Order is resumed and partially FILLed then RWT is ACKed and partially FILLed. DEL is finally ACKed for a partial FILL.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <vp2> |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 2.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 4.0       | 8.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | done  |
	| RWT     | FILL   | 00001~0-1 |      6 | x0-00001 | 2.0     | 102.1  | 2.0       | 8.0    | 102.025 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      6 | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 2.0     | 102.1  | 2.0       | 10.0   | 102.02 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | done  |
	| DEL     | ACK    | 00001~0-2 |      7 |          | 0.0     | NaN    | 2.0       | 8.0    | 102.025 |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp2> |        |          | 1005   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.02 |      | true   | true  |

Examples:
  | rT  | v | vp1 | vp2 |
  | ADD | 0 | 1   | 2   |
  | RWT | 1 | 2   | 3   |

Scenario Outline: 2ZB: A zero filled ACKed ADD/RWT with an un-processed full FILL is completed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v>   |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | <vp1> |        |          | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2ZC: A zero filled ACKed ADD/RWT with an un-processed full FILL is completed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | <vp1> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v>   |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| DEL     | NAK    | 00001 | <vp1> |        |          | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Examples:
  | rT  | v | vp1 |
  | ADD | 0 | 1   |
  | RWT | 1 | 2   |

Scenario Outline: 2ZD: A zero filled ACKed ADD/RWT with an un-processed full FILL is completed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <vp2> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v>   |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| RWT     | NAK    | 00001 | <vp1> |        |          | 1002   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | RWT superseded          | false  | true  |
	| DEL     | NAK    | 00001 | <vp2> |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Examples:
  | rT  | v | vp1 | vp2 |
  | ADD | 0 | 1   | 2   |
  | RWT | 1 | 2   | 3   |

Scenario Outline: 3XA-1: A partially FILLed ADD / RWT is resumed and fully FILLed in one clip.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 8.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |

Scenario Outline: 3XA-2: A partially FILLed ADD / RWT is resumed and fully FILLed in two clips.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 5.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      3 | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |

Scenario Outline: 3XB-1: Shortcut Mode. A partially FILLed ADD / RWT is resumed and partially FILLed. The queued RWT is ACKed and fully FILLed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.1  | 0.0       | 10.0   | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      2 | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 10.0    | 102.1  | 0.0       | 12.0   | 102.083333333 |      | true   | true  |

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XB-2: Non Shortcut Mode. A partially FILLed ADD / RWT is resumed and partially FILLed. The queued RWT crosses the full FILL and is eventually NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 8.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | <vp1> |        | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XB-3: Non Shortcut Mode. A partially FILLed ADD / RWT is resumed but nothing gets FILLed. The queued RWT is eventually fully FILLed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <vp1> |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange


  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      3 | x0-00001 | 10.0    | 102.1  | 0.0       | 10.0   | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      3 | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 10.0    | 102.1  | 0.0       | 12.0   | 102.083333333 |      | true   | true  |
  And no child order is sent to exchange

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XB-4: A partially FILLed ADD / RWT is resumed and partially FILLed. Then a RWT arrives which is ACKed and fully FILLed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 5.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | <vp1> | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 | 10.0     | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 7.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | <vp1> |        | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 7.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | done  |
	| RWT     | FILL   | 00001~0-1 |      4 | x0-00001 | 7.0     | 102.1  | 0.0       | 10.0   | 102.07 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | <vp1> |      4 | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 7.0     | 102.1  | 0.0       | 12.0   | 102.058333333 |      | true   | true  |

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XC-1: Shortcut Mode. A partially FILLed ADD / RWT is NOT resumed. The queued DEL is ACKed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | <vp1> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp1> |        |          |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XC-2: Non Shortcut Mode. A partially FILLed ADD / RWT is resumed but nothing gets FILLed as the queued DEL is ACKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | <vp1> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp1> |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3XC-3: Non Shortcut Mode. A partially FILLed ADD / RWT is resumed and gets partially FILLed before the queued DEL is ACKed.
	Given the OrderManagerService is further configured with
	| conflateRequests |
	| false            |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And requests are received from cache or clients
	| reqType | ordId | ver   | timeInForce | side | price | qty  | shownQty | useNative |
	| DEL     | 00001 | <vp1> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 8.0  | 8.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 5.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 5.0       | 3.0    | 102.0 |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | <vp1> |        | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 5.0       | 5.0    | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | vp1 | fI | lQ  | lP    |
  | ADD | FILL | 0 | 1   |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 | 2   |    | 0.0 | NaN   |

Scenario Outline: 3YA-1: A partially FILLed ADD / RWT with a partially un-processed FILL is resumed and fully FILLed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      4 | x0-00001 |   1002 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  1 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |


Scenario: A partially FILLed ADD is resumed after failover. A first RWT request to increase the size is accepted. 
  A second RWT to decrease the size to below the already filled quantity results in a 'Too late to replace'
  rejection (strictRwt = true). Eventually the increased size is fully FILLed.

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | FILL   | 00001 | 0   | 2      | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 1     | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  | 8.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1     |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 |      | false  | false |
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 2     | 102.1 | 3.0  | 3.0      |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 2     |        |          |   1002 | DAY         | Buy  | 102.1 | 3.0  | 3.0      | 0.0     | NaN    | -1.0      | 4.0    | 102.0 | Too late to replace | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      5 | x0-00001 | 8.0     | 102.1  | 0.0       | 8.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      5 | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 8.0     | 102.1  | 0.0       | 12.0   | 102.066666666 |      | true   | true  |

Scenario Outline: A partially FILLed ADD is resumed after failover. A RWT request to increase the size is accepted. 
  A second RWT to decrease the quantity is accepted.
  Case 1: to below the already filled quantity (with strictRwt = false).
  Case 2: to exactly the already filled quantity.
  The active slice is canceled and the amended order is over filled (Case 1) / fully filled (Case 2).

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | FILL   | 00001 | 0   | 2      | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 1     | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  | 8.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1     |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 |      | false  | false |
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty   | shownQty |
	| RWT     | 00001 | 2     | 102.1 | <r2Q> | <r2Q>    |
  Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 8.0  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      5 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty   | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        | x0-00001 | 1002   | DAY         | Buy  | 102.1 | <r2Q> | <r2Q>    | 0.0     | NaN    | <lQ>      | 4.0    | 102.0 |      | true   | true  |

Examples:
  | r2Q | lQ   |
  | 3.0 | -1.0 |
  | 4.0 | 0.0  |

@UnsolicitedCancel
Scenario: A partially FILLed ADD is resumed after failover. A RWT request to increase the size is accepted. 
  An unsolicited cancel is received for the active order which concludes the parent order.

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | FILL   | 00001 | 0   | 2      | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 1     | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  | 8.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver   | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1     |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 |      | false  | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | done  |
	| DEL     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   | Done for Day | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | ftDone | done  |
	| RWT     | DONE   | 00001 | 1   |        | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 | Done for Day | true   | true  |

Scenario: A partially FILLed ADD is resumed after failover. A RWT request to increase the size is accepted. 
  A partial fill is received and passed to client. A second RWT to decrease the quantity to below the
  filled quantity is rejected as the Order Manager is configured with srtictRwt = true. A third RWT to 
  decrease the quantity to exactly the filled quantity is accepted and a DEL request is sent to the exchange.
  However a partial fill crosses the DEL request and is passed to client. Finally, the DEL request is accepted
  by the exchange and a RWT ACK is sent to client with an overfill.

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | FILL   | 00001 | 0   | 2      | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 1     | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  | 8.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 |      | false  | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      5 | x0-00001 | 3.0     | 102.1  | 5.0       | 3.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      5 | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 3.0     | 102.1  | 5.0       | 7.0    | 102.042857142 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 2     | 102.1 | 5.0  | 5.0      |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          | 1003   | DAY         | Buy  | 102.1 | 5.0 | 5.0      | 0.0     | NaN    | -2.0      | 7.0    | 102.042857142 | Too late to replace | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 3     | 102.1 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 8.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      6 | x0-00001 | 1.0     | 102.1  | 4.0       | 4.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      6 | x0-00001 |   1004 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 1.0     | 102.1  | 4.0       | 8.0    | 102.05 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      7 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        | x0-00001 | 1005   | DAY         | Buy  | 102.1 | 7.0  | 7.0      | 0.0     | NaN    | -1.0      | 8.0    | 102.05 |      | true   | true  |

Scenario: A partially FILLed ADD is resumed after failover. A RWT request to increase the size is accepted. 
  A partial fill is received and passed to client. A second RWT to decrease the quantity to below the
  filled quantity is accepted as the Order Manager is configured with srtictRwt = false and a DEL request is 
  sent to the exchange. However a partial fill crosses the DEL request and is passed to client. Finally, the DEL 
  request is accepted by the exchange and a RWT ACK is sent to client with an overfill.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  | useNative |
	| ADD     | FILL   | 00001 | 0   | 2      | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  And no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 6.0  | 6.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 1     | 102.1 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 8.0  | 8.0      | 102.1 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |   1001 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 8.0       | 4.0    | 102.0 |      | false  | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      5 | x0-00001 | 3.0     | 102.1  | 5.0       | 3.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      5 | x0-00001 |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 3.0     | 102.1  | 5.0       | 7.0    | 102.042857142 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver   | price | qty  | shownQty |
	| RWT     | 00001 | 2     | 102.1 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-2 | 00001~0-1   | x0-00001 | Buy  | 8.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      6 | x0-00001 | 1.0     | 102.1  | 4.0       | 4.0    | 102.1 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      6 | x0-00001 |   1003 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 1.0     | 102.1  | 4.0       | 8.0    | 102.05 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-2 |      7 | x0-00001 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | true  |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx  | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        | x0-00001 | 1004   | DAY         | Buy  | 102.1 | 5.0  | 5.0      | 0.0     | NaN    | -3.0      | 8.0    | 102.05 |      | true   | true  |

