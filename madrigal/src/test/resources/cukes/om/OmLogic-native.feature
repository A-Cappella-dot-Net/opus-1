Feature: Order Manager - Native Logic Scenarios
	This feature includes scenarios that send native orders to the exchange.
	Fully shown and iceberg orders are used, as well as DAY and IOC time in
	force values.


Background:
	All scenarios in this feature make no use of the OrderManagerService configuration parameters (except nativeIocSupported).
	Therefore the OrderManagerService is configured with the default values for all its parameters.

	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
#	| true               | true             | false                           | true                    | true      |

@Fills
Scenario: An ADD request is fully FILLed in one clip.

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

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@Fills
Scenario: An ADD request is fully FILLed in two clips.

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

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 5.0     | 101.0  | 0.0       | 10.0   | 101.5 |      | true   | true  |

@AmendCancelAfterNewAck
Scenario: DEL request is received after the ADD has been ACKed. Nothing filled.
  An ADD request is ACKed by the exchange and is followed by a DEL request which is in turn ACKed by
  the excahnge. No quantity is filled.

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
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | true   | true  |

@AmendCancelAfterNewAck
Scenario: RWT and DEL requests are received after the previous request has been ACKed. Nothing filled.
  An ADD request is followed by a RWT and a DEL request, both after the previos request has been ACKed
  by the exchange. No quantity is filled.

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
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px     | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 12.0 | 12.0     | 102.01 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 12.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   |      | true   | true  |

@Fills
@AmendCancelAfterNewAck
Scenario: An ADD request is partially FILLed in two clips before a DEL request is executed.

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

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 8.0       | 2.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 2.0     | 101.0  | 6.0       | 4.0    | 101.5 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 101.0  | 6.0       | 4.0    | 101.5 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-1 |      4 | x0-00001 | 0.0     | NaN    | 6.0       | 4.0    | 101.5 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 6.0       | 4.0    | 101.5 |      | true   | true  |

@IOC
Scenario: Native IOC no FILL.
  An ADD request is ACKed by the exchange. Without a FILL, a final DONE message is received from 
  the exchange and results in a final DONE message sent to the client.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      2 | x0-00001 | 0.0     | 0.0    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC full FILL.
  An ADD request is ACKed by the exchange and then fully FILLed. The done and complete flags are both set.
  A final DONE message is not received from the exchange.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@IOC
Scenario: Native IOC partial FILL.
  An ADD request is ACKed by the exchange and partailly FILLed. A final DONE message received from the exchange
  results in a final DONE message sent to the client.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC full FILL in two clips.
  An ADD request is ACKed by the exchange and fully FILLed in two clips. A final DONE message is not received
  from the exchange and is not sent to the client. The 'done' and 'complte' flags are set on the final fill response.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 101.0  | 4.0       | 6.0    | 101.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 101.0  | 4.0       | 6.0    | 101.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 4.0     | 102.0  | 0.0       | 10.0   | 101.4 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 4.0     | 102.0  | 0.0       | 10.0   | 101.4 |      | true   | true  |

@IOC
Scenario: Native IOC - RWT is NAKed by the line handler.
  An ADD request is ACKed and partially FILLed. Before the final DONE message is received from the exchange
  a DEL request is received from the client which is NAKed right away by the line handler.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        |          |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC - RWT is NAKed by the line handler.
  An ADD request is ACKed and partially FILLed. Before the final DONE message is received from the exchange
  a RWT request is received from the client which is NAKed right away by the line handler.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 6.0       | 6.0    | 102.0 | RWT not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC - RWT and DEL are both NAKed by the line handler.
  An ADD request is ACKed and partially FILLed. Before the final DONE message is received from the exchange
  a RWT and a DEL request are received from the client which are NAKed right away by the line handler.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange
  And one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 6.0       | 6.0    | 102.0 | RWT not supported for IOC orders | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      5 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC - RWT and DEL are both NAKed by the line handler.
  An ADD request is sent to the exchange. Before it is ACKed a RWT request is received from client, which
  is buffered until the ADD ACK is received. At that time the RWT NAK is sent back to the client. After 
  the ADD is partially FILLed but before the final DONE message is received from the exchange a DEL request
  is received and NAKed right away by the line handler.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

  When a parent order is received from client
	| reqType | ordId | ver | price  | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.01 | 12.0 | 12.0     |
  Then no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      3 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then no child order is sent to exchange
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        |          |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | DEL not supported for IOC orders | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      5 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@IOC
Scenario: Native IOC - RWT and DEL are both NAKed by the line handler.
  An ADD request is sent to the exchange. Before it is ACKed a RWT and a DEL request are received from 
  client, which are buffered until the ADD ACK is received. At that time two NAKs are sent back to the 
  client. A final DONE message received from the exchange results in a final DONE message sent to the 
  client.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | IOC         | Buy  | 102.0 | 10.0 | 10.0     | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 10.0     | 102.0 | IOC |

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
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price  | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                             | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      1 | IOC         | Buy  | 102.01 | 12.0 | 12.0     | 0.0     | NaN    | 12.0      | 0.0    | 0.0   | RWT not supported for IOC orders | false  | false |
	| DEL     | NAK    | 00001 | 2   |        |          |      2 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | DEL not supported for IOC orders | false  | false |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      3 | IOC         | Buy  | 102.0  | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |                                  | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      4 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | done  |
	| ADD     | DONE   | 00001-0 |      3 | x0-00001 | 0.0     | 0.0    | 4.0       | 6.0    | 0.0   | Could not match IOC order | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      5 | IOC         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 4.0       | 6.0    | 102.0 | Could not match IOC order | true   | true  |

@Iceberg
Scenario: An ADD request is fully FILLed in two clips.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      3 | x0-00001 | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

@Iceberg
Scenario: RWT and DEL requests are received after the previous request has been ACKed. Nothing filled.
  An ADD request is followed by a RWT and a DEL request, both after the previos request has been ACKed
  by the exchange. No quantity is filled.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      2 | x0-00001 | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 15.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-2 |      3 | x0-00001 | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 15.0      | 0.0    | 0.0   |      | true   | true  |

@Iceberg
Scenario: RWT is received after the ADD has beenn partially FILLed and DEL is received after the RWT has been ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 15.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-2 |      4 | x0-00001 | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      4 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | true   | true  |

@Iceberg
Scenario: Both ADD and RWT receive FILLs. DEL cancels the remaining quantity.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001-1 |      4 | x0-00001 | 5.0     | 102.0  | 5.0       | 10.0   | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 5.0     | 102.0  | 5.0       | 10.0   | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 15.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-2 |      5 | x0-00001 | 0.0     | NaN    | 5.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      5 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 5.0       | 10.0   | 102.0 |      | true   | true  |

@Iceberg
Scenario: Requests and FILLs cross. Both ADD and RWT receive FILLs. DEL cancels the remaining quantity.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 15.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001-1 |      4 | x0-00001 | 5.0     | 102.0  | 5.0       | 10.0   | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 5.0     | 102.0  | 5.0       | 10.0   | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001-2 |      5 | x0-00001 | 0.0     | NaN    | 5.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 2   |        | x0-00001 |      5 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 5.0       | 10.0   | 102.0 |      | true   | true  |

@Iceberg
Scenario: Requests and FILLs cross. Both ADD and RWT receive FILLs. DEL is rejected (Order already completed).

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 10.0      | 5.0    | 102.0 |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 2   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001-2 | 00001-1     | x0-00001 | Buy  | 15.0 |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001-1 |      4 | x0-00001 | 10.0    | 102.0  | 0.0       | 15.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 10.0    | 102.0  | 0.0       | 15.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001-2 |      5 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | 2   |        | x0-00001 |      5 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 0.0       | 15.0   | 102.0 | Order already completed | false  | true  |

@Iceberg
Scenario: Requests and FILLs cross. ADD receives a full FILL. RWT (size increase) is rejected (Order already completed).

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 15.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 15.0 | 10.0     | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 15.0 | 10.0     | 0.0     | NaN    | 5.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@Iceberg
Scenario: Requests and FILLs cross. ADD receives a full FILL. RWT (size decrease) is rejected (Order already completed).

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | -5.0      | 10.0   | 102.0 | Order already completed | false  | true  |

@TooLateToAmend
Scenario: Requests and FILLs cross. ADD receives a partial FILL. RWT (size decrease) is rejected (Too late to amend). Order is eventually fully FILLed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 6.0     | 102.0  | 4.0       | 6.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Too late to amend | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text              | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | -1.0      | 6.0    | 102.0 | Too late to amend | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      4 | x0-00001 | 4.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 4.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

Scenario: Requests and FILLs cross. ADD receives a partial FILL. RWT (size decrease to filled quantity) is accepted.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 5.0     | 102.0  | 5.0       | 5.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 0.0       | 5.0    | 102.0 |      | true   | true  |

Scenario: Requests and FILLs cross. ADD receives a partial FILL. RWT (size decrease to above filled quantity) is accepted. Another FILL concludes the order.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 5.0  | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 5.0  | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 4.0     | 102.0  | 6.0       | 4.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 1.0       | 4.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 0.0     | NaN    | 1.0       | 4.0    | 102.0 |      | false  | false |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001-0 |      4 | x0-00001 | 1.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 5.0  | 5.0      | 1.0     | 102.0  | 0.0       | 5.0    | 102.0 |      | true   | true  |

@Iceberg
Scenario: Requests and FILLs cross. ADD receives a full FILL. RWT (price change) is rejected (Order already completed).

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 10.0 | 5.0      | true      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | side | qty  | shownQty | px    | tif |
	| ADD     | 00001-0 | Buy  | 10.0 | 5.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001-0 |      1 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        | x0-00001 |      1 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 10.0 | 5.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID | origClOrdId | ecnOrdId | side | qty  | shownQty | px    | tif |
	| RWT     | 00001-1 | 00001-0     | x0-00001 | Buy  | 10.0 | 5.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001-0 |      2 | x0-00001 | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 5.0      | 10.0    | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        | x0-00001 |      3 | DAY         | Buy  | 102.2 | 10.0 | 5.0      | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | false  | true  |

@UnsolicitedCancel
Scenario: Acked order receives an Unsolicited Cancel

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

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | done  |
	| DEL     | ACK    | 00001-0 |      2 | x0-00001 | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Done for Day | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text         | ftDone | done  |
	| ADD     | DONE   | 00001 | 0   |        | x0-00001 |      2 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   | Done for Day | true   | true  |
