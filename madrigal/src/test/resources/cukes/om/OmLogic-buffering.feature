Feature: Order Manager - buffering scenarios
  This feature includes scenarios where a burst of requests is received from client before 
  the ACK is received for the ADD request from the exchange. All such requests are buffered.
  In shortcut mode, when the ADD ACK is received the latest request is sent to the exchange
  and the rest are NAKed back to the client with a 'superseded' error message.
  In non shortcut mode, when the ADD ACK is received all accumulated requests are sent to the
  exchange in one burst.

Background: 
  The shortcut mode is controlled by the 'conflateRequests' flag

Scenario Outline: DEL request is buffered until ADD ACK is received, at which time it is sent to exchange.
	Given an OrderManagerService is configured with
	| conflateRequests   |
	| <conflateRequests> |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

Examples:
  | conflateRequests |
  | true             |
  | false            |

Scenario Outline: RWT request is buffered until ADD ACK is received, at which time it is sent to exchange.
	Given an OrderManagerService is configured with
	| conflateRequests   |
	| <conflateRequests> |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

Examples:
  | conflateRequests |
  | true             |
  | false            |

Scenario: RWT and DEL requests are buffered until ADD ACK is received, at which time RWT is rejected and DEL is sent to exchange. Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| true             |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      2 | DAY         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

Scenario: RWT and DEL requests are buffered until ADD ACK is received, at which time both are sent to exchange. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 12.0 |          |        |     |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

Scenario: RWTs and DEL requests are buffered until ADD ACK is received, at which time all RWTs are rejected and DEL is sent to exchange. Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| true             |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And no execution report is sent to client

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.01 | 10.0 | 10.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 3   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| RWT     | NAK    | 00001 | 2   |        |          |      2 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | RWT superseded | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text           | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      3 | DAY         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 3   |        | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

Scenario: RWTs and DEL requests are buffered until ADD ACK is received, at which time all RWTs and DEL are sent to exchange. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.01 | 10.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 3   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
	| RWT     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 | 10.0     | 102.01 | DAY |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |          |        |     |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-3 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 3   |        | x0-00001 |      4 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

Scenario: RWTs and DEL are buffered until ADD ACK is received; fills are received after each ACK and apply to the latest ACKed request. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 2   | 102.01 | 10.0 | 10.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 3   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
	| RWT     | 00001-2 | 00001-0     | x0-00001 | Buy  | 10.0 | 10.0     | 102.01 | DAY |
	| DEL     | 00001-3 | 00001-0     | x0-00001 | Buy  | 10.0 |          |        |     |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 10.0      | 2.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | done  |
	| RWT     | FILL   | 00001-1 |      4 | x0-00001 | 2.0     | 102.01 | 8.0       | 4.0    | 102.005 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 2.0     | 102.01 | 8.0       | 4.0    | 102.005 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | done  |
	| RWT     | ACK    | 00001-2 |      5 | x0-00001 | 0.0     | NaN    | 8.0       | 4.0    | 102.005 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx   | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 2   |        | x0-00001 |      5 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 0.0     | NaN    | 6.0       | 4.0    | 102.005 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | done  |
	| RWT     | FILL   | 00001-2 |      6 | x0-00001 | 2.0     | 102.01 | 4.0       | 6.0    | 102.00666666666666 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00001 |      6 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 2.0     | 102.01 | 4.0       | 6.0    | 102.00666666666666 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-3 |      7 | x0-00001 | 0.0     | NaN    | 4.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 3   |        | x0-00001 |      7 | DAY         | Buy  | 102.01 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.00666666666666 |      | true   | true  |

Scenario: DEL is buffered and sent to exchange on receiving the ADD ACK. Complete fill crosses DEL, which is then NAKed. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Scenario: RWT is buffered and sent to exchange on receiving ADD ACK. Complete fill crosses RWT, which is then NAKed. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |

Scenario: RWT and DEL requests are buffered and sent to exchange on receiving ADD ACK. A complete fill crosses them, which are then NAKed. Non Shortcut Mode.
	Given an OrderManagerService is configured with
	| conflateRequests |
	| false            |

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |
	| DEL     | 00001-2 | 00001-0     | x0-00001 | Buy  | 12.0 |          |        |     |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 2.0       | 10.0   | 102.0 | Order already completed | false  | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001-2 |      4 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone   | done  |
	| DEL     | NAK    | 00001 | 2   |        | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false    | true  |

