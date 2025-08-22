Feature: Order Manager - Simulated IOC Scenarios
  This feature includes scenarios that involve simulated IOC orders.

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
	| true               | true             | false                           | true                    | true      |


Scenario: Basic Scenario - ADD, no FILL
  The ADD request is ACKed by the exchange and a DEL request is sent. When the DEL is ACKed as well the order is complete.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        |          |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true   | true  |


Scenario: Basic Scenario - ADD, full FILL
  The ADD request is ACKed by the exchange and is followed by a FILL message for the entire quantity.
  The subsequent DEL NAK is ignored.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no execution report is sent to client


Scenario: Basic Scenario - ADD, partial FILL
  The ADD request is ACKed by the exchange and is followed by a FILL message for part of the quantity.
  The subsequent DEL request is ACKed, which results in a DONE message.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 7.0       | 3.0    | 102.0 | Could not match IOC order | true   | true  |


Scenario: Basic Scenario - ADD, full FILL in multiple clips
  The ADD request is ACKed by the exchange and is followed by multiple FILLs adding up to the entire quantity.
  The subsequent DEL NAK is ignored.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 6.0     | 101.0  | 4.0       | 6.0    | 101.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 101.0  | 4.0       | 6.0    | 101.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 4.0     | 102.0  | 0.0       | 10.0   | 101.4 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 0.0       | 10.0   | 101.4 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no execution report is sent to client


Scenario: Basic Scenario - ADD, partial FILL in multiple clips
  The ADD request is ACKed by the exchange and is followed by multiple FILLs adding up to less than the entire quantity.
  The subsequent DEL ACK results in a DONE message for the original order.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 4.0     | 101.0  | 6.0       | 4.0    | 101.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 101.0  | 6.0       | 4.0    | 101.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 4.0     | 102.0  | 2.0       | 8.0    | 101.5 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 2.0       | 8.0    | 101.5 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 2.0       | 8.0    | 101.5 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 2.0       | 8.0    | 101.5 | Could not match IOC order | true   | true  |


Scenario: Basic Scenario - ADD, no FILL, buffered RWT and DEL.
  An ADD, RWT and DEL request are received in burst. The RWT and DEL are buffered until the ADD ACK is received,
  at which time they are NAKed with error message 'not supported for IOC orders'

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      3 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        |          |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true   | true  |


Scenario: Basic Scenario - ADD, full FILL, buffered RWT and DEL.
  An ADD, RWT and DEL request are received in burst. The RWT and DEL are buffered until the ADD ACK is received,
  at which time they are NAKed with error message 'not supported for IOC orders'

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      3 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in Orderbook 'x0-00001' | true  |
  Then no execution report is sent to client


Scenario: Basic Scenario - ADD, partial FILL, buffered RWT and DEL.
  An ADD, RWT and DEL request are received in burst. The RWT and DEL are buffered until the ADD ACK is received,
  at which time they are NAKed with error message 'not supported for IOC orders'

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      3 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      5 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 7.0       | 3.0    | 102.0 | Could not match IOC order | true   | true  |

Scenario: Basic Scenario - ADD, partial FILL, buffered RWT and DEL.
  An ADD and a RWT request are received in burst. The RWT is buffered until the ADD ACK is received,
  at which time it is NAKed with error message 'not supported for IOC orders.' After the ADD client
  request is ACKed and it releases the DEL client request and the parent ACK, a parent DEL request
  is received which is NAKed right away with the same 'not supported for IOC orders' error message.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 10.0 | 10.0     | 102.0 | DAY |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 10.0 |
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      3 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 3.0     | 102.0  | 7.0       | 3.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      5 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 7.0       | 3.0    | 102.0 | Could not match IOC order | true   | true  |

