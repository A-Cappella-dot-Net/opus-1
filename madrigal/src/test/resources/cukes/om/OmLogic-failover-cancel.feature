Feature: Order Manager - Failover Scenarios
	This feature includes scenarios that test failover when the OMS is configured to ALWAYS_CANCEL.

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
	| true               | true             | false                           | true                    | true      | ALWAYS_CANCEL    |
  And the OrderManagerService is activated with execId 1000

Scenario: 1XA: An Un-ACKed ADD is rejected.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text            | ftDone | done  |
	| ADD     | NAK    | 00001 | 0   |        |          |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | due to failover | true   | true  |

Scenario Outline: 1XB: Un-ACKed ADD followed by a(n un-ACKed) RWT are both rejected.
	Given the OrderManagerService is further configured with
	| conflateRequests   |
	| <conflateRequests> |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text            | ftDone | done  |
	| ADD     | NAK    | 00001 | 0   |        |          |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | <text>          | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | due to failover | false  | true  |

Examples:
  | conflateRequests | text            |
  | true             | ADD superseded  |
  | false            | due to failover |

Scenario Outline: 1XD: Un-ACKed ADD, RWT, and DEL are all rejected.
	Given the OrderManagerService is further configured with
	| conflateRequests   |
	| <conflateRequests> |

  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | 2   |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text            | ftDone | done  |
	| ADD     | NAK    | 00001 | 0   |        |          |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | <textAdd>       | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | <textRwt>       | false  | true  |
	| DEL     | NAK    | 00001 | 2   |        |          |   1003 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | due to failover | false  | true  |

Examples:
  | conflateRequests | textAdd         | textRwt         |
  | true             | ADD superseded  | RWT superseded  |
  | false            | due to failover | due to failover |

Scenario: 1YA: An Un-ACKed ADD and an un-processed partial FILL. The order is ACKed, partially FILLed, and then ReSTated.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0  .0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |                         | false  | false |
	| ADD     | CXL    | 00001 | 0   |        | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover      | true   | true  |

Scenario: 1YB: The ADD ACK and partial FILL coming from exchange was missed due to the primary crashing. A RWT request received from client during failover needs to be processed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0  .0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |                         | false  | false |
	| ADD     | CXL    | 00001 | 0   |        | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover      | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 | Order already completed | false  | true  |

Scenario Outline: 1YD: The ADD ACK and partial FILL coming from exchange was missed due to the primary crashing. RWT and DEL requests received from client during failover are NAKed.
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
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0  .0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |                         | false  | false |
	| ADD     | CXL    | 00001 | 0   |        | x0-00001 | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover      | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          | 1004   | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 | <text>                  | false  | true  |
	| DEL     | NAK    | 00001 | 2   |        |          | 1005   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | Order already completed | false  | true  |

Examples:
  | conflateRequests | text                    |
  | true             | RWT superseded          |
  | false            | Order already completed |

Scenario: 1ZA: An Un-ACKed ADD and an un-processed full FILL. The order is ACKed, and fully FILLed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |

Scenario: 1ZC: Un-ACKed ADD and DEL, and an un-processed full FILL. The order is ACKed and fully FILLed. DEL request is NAKed.
  When requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
	| DEL     | 00001 | 1   |             |      | NaN   | NaN  | NaN      |           |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0  .0 |                         | false  | false |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                         | true   | true  |
	| DEL     | NAK    | 00001 | 1   |        |          | 1003   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |



Scenario Outline: 2XA: An ACKed ADD/zero filled RWT is re-stated.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | CXL    | 00001 | <v> |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | cancel on failover | true   | true  |

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2YA: A zero filled ACKed ADD/RWT with an un-processed partial FILL is ReSTated.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |                    | false  | false |
	| <rT>    | CXL    | 00001 | <v> |        | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover | true   | true  |

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario Outline: 2ZA: A zero filled ACKed ADD/RWT with an un-processed full FILL is completed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |                    | true   | true  |

Examples:
  | rT  | v |
  | ADD | 0 |
  | RWT | 1 |

Scenario: 2XB: An ACKed ADD is re-stated. A subsequent RWT is NAKed.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And requests are received from cache or clients
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | 1   |             |      | 102.1 | 12.0 | 12.0     |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| ADD     | CXL    | 00001 | 0   |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | cancel on failover      | true   | true  |
	| RWT     | NAK    | 00001 | 1   |        |          |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | Order already completed | false  | true  |

Scenario Outline: 2XD: An ACKed ADD is re-stated. Subsequent RWT and DEL are NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests   |
	| <conflateRequests> |

  When states are received from cache
	| reqType | status | ordId | ver  | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | ACK    | 00001 | <v1> |        | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And requests are received from cache or clients
	| reqType | ordId | ver  | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <v2> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <v3> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver  | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| <rT>    | CXL    | 00001 | <v1> |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | cancel on failover      | true   | true  |
	| RWT     | NAK    | 00001 | <v2> |        |          |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | <text>                  | false  | true  |
	| DEL     | NAK    | 00001 | <v3> |        |          |   1003 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Order already completed | false  | true  |

Examples:
  | conflateRequests | text                    | rT  | v1 | v2 | v3 |
  | true             | RWT superseded          | ADD | 0  | 1  | 2  |
  | false            | Order already completed | ADD | 0  | 1  | 2  |
  | true             | RWT superseded          | RWT | 1  | 2  | 3  |
  | false            | Order already completed | RWT | 1  | 2  | 3  |



Scenario Outline: 3XA: A partially FILLed ADD / RWT is re-stated.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | CXL    | 00001 | <v> |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |

Scenario Outline: 3YA: A partially FILLed ADD / RWT with a partially un-processed FILL is re-stated.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 6.0       | 4.0    | 102.0 |                    | false  | false |
	| <rT>    | CXL    | 00001 | <v> |        | x0-00001 | 1002   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 6.0       | 4.0    | 102.0 | cancel on failover | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |

Scenario Outline: 3ZA: A partially FILLed ADD / RWT with a full un-processed FILL is completed/filled.
  When states are received from cache
	| reqType | status | ordId | ver | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | <s>    | 00001 | <v> | <fI>   | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false |
  And unprocessed fills are received from exchange
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| <rT>    | FILL   | 00001-<v> |      2 | x0-00001 | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | false |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text               | ftDone | done  |
	| <rT>    | FILL   | 00001 | <v> |      2 | x0-00001 | 1001   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 8.0     | 102.0  | 0.0       | 10.0   | 102.0 |                    | true   | true  |

Examples:
  | rT  | s    | v | fI | lQ  | lP    |
  | ADD | FILL | 0 |  2 | 2.0 | 102.0 |
  | RWT | ACK  | 1 |    | 0.0 | NaN   |

Scenario Outline: 3XD: A partially FILLed ADD / RWT is re-stated. Subsequent RWT and DEL are NAKed.
	Given the OrderManagerService is further configured with
	| conflateRequests   |
	| <conflateRequests> |

  When states are received from cache
	| reqType | status | ordId | ver  | fillId | ecnOrdId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| <rT>    | <s>    | 00001 | <v1> |   <fI> | x0-00001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | <lQ>    | <lP>   | 8.0       | 2.0    | 102.0 |      | false  | false |
  And requests are received from cache or clients
	| reqType | ordId | ver  | timeInForce | side | price | qty  | shownQty | useNative |
	| RWT     | 00001 | <v2> |             |      | 102.1 | 12.0 | 12.0     |           |
	| DEL     | 00001 | <v3> |             |      | NaN   | NaN  | NaN      |           |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When trader logging into exchange triggers activation of all trader orders
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver  | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| <rT>    | CXL    | 00001 | <v1> |        | x0-00001 |   1001 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | cancel on failover      | true   | true  |
	| RWT     | NAK    | 00001 | <v2> |        |          |   1002 | DAY         | Buy  | 102.1 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 | <text>                  | false  | true  |
	| DEL     | NAK    | 00001 | <v3> |        |          |   1003 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 8.0       | 2.0    | 102.0 | Order already completed | false  | true  |

Examples:
  | conflateRequests | text                    | rT  | s    | v1 | v2 | v3 | fI | lQ  | lP    |
  | true             | RWT superseded          | ADD | FILL | 0  | 1  | 2  |  2 | 2.0 | 102.0 |
  | false            | Order already completed | ADD | FILL | 0  | 1  | 2  |  2 | 2.0 | 102.0 |
  | true             | RWT superseded          | RWT | ACK  | 1  | 2  | 3  |    | 0.0 | NaN   |
  | false            | Order already completed | RWT | ACK  | 1  | 2  | 3  |    | 0.0 | NaN   |

