Feature: Order Manager - Optimized Rewrite Scenarios

Background: 
	Given an OrderManagerService is configured with
	| nativeIocSupported | conflateRequests | processOnePendingRequestAtATime | useDelAddForPriceChange | strictRwt |
#	| true               | true             | false                           | true                    | true      |


@OptimizedRwt
Scenario: One active child. Fill in one clip.

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

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. Fill in two clips.

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

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 4.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 4.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. Fill in three clips.

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

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 3.0     | 102.0  | 4.0       | 3.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      3 | x0-00001 | 2.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. No fill. Successful DEL.

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
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. Partial fill. Successful DEL.

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

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 5.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 5.0       | 2.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. Partial fill and child DEL request cross. Successful DEL.

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
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	And no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 5.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| DEL     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 5.0       | 2.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. Full fill and child DEL request cross. Parent DEL is NAKed.

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
	| reqType | ordId | ver |
	| DEL     | 00001 | 1   |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0  |
	And no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| DEL     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 0.0       | 7.0    | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (price change) => child RWT. No fill. Child RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
  # optimization: when only one child exists then do a RWT not a DEL, even though useDelAddForPriceChange=true
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.2 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      3 | x0-00001 | 7.0     | 102.2  | 0.0       | 7.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.2 | 7.0  | 7.0      | 7.0     | 102.2  | 0.0       | 7.0    | 102.2 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (price change) => child RWT. Child partial fill. Child RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
  # optimization: when only one child exists then do a RWT not a DEL, even though useDelAddForPriceChange=true
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
  Then no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.2 | 7.0  | 7.0      | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx      | text | done  |
	| RWT     | FILL   | 00001~0-1 |      4 | x0-00001 | 2.0     | 102.2  | 0.0       | 7.0    | 102.057142 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx              | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.2 | 7.0  | 7.0      | 2.0     | 102.2  | 0.0       | 7.0    | 102.05714285714285 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (price change) => child RWT. Child full fill. Child RWT is NAKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.2 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
  # optimization: when only one child exists then do a RWT not a DEL, even though useDelAddForPriceChange=true
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 7.0 | 7.0      | 102.2 | DAY |
  Then no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 2.0       | 5.0    | 102.0 | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.2 | 7.0  | 7.0      | 0.0     | NaN    | 0.0       | 7.0    | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (size decrease) => child RWT. No fill. Child RWT is ACKed.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      2 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      2 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      3 | x0-00001 | 6.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      3 | x0-00001 |      3 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 6.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (size decrease) => child RWT. Child partial fill. Child RWT ACK.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 5.0       | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 6.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | 4.0       | 2.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-1 |      4 | x0-00001 | 4.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 1   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 4.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: One active child. RWT (size decrease) => child RWT. Child full fill. Child RWT NAK.

  When a parent order is received from client
	| reqType | ordId | ver | timeInForce | side | price | qty  | shownQty | useNative |
	| ADD     | 00001 | 0   | DAY         | Buy  | 102.0 | 7.0  | 7.0      | false     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~0-0 | Buy  | 7.0  | 7.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~0-0 |      1 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | ACK    | 00001 | 0   |        |          |      1 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When a parent order is received from client
	| reqType | ordId | ver | price | qty  | shownQty |
	| RWT     | 00001 | 1   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      2 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| ADD     | FILL   | 00001 | 0   |      2 | x0-00001 |      2 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      3 | x0-00001 | 0.0     | NaN    | 2.0       | 5.0    | 102.0 | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 1   |        |          |      3 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -1.0      | 7.0    | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. No fill. Child DELs are ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 11.0 | 11.0     | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      7 | x0-00004 | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      8 | x0-00004 | 11.0    | 102.2  | 0.0       | 11.0   | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00004 |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 11.0    | 102.2  | 0.0       | 11.0   | 102.2 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. One child partially filled, rest DELeted. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 5.0     | 102.0  | 6.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | 0.0    | 2.0       | 5.0    | 102.0 |      | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 6.0  | 6.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00004 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 6.0       | 5.0    | 102.0 |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 6.0     | 102.2  | 0.0       | 6.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx          | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00004 |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 6.0     | 102.2  | 0.0       | 11.0   | 102.1090909090 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. One child fully filled, rest DELeted. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      5 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 4.0  | 4.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00004 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 4.0       | 7.0    | 102.0 |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 4.0     | 102.2  | 0.0       | 4.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx          | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00004 |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 4.0     | 102.2  | 0.0       | 11.0   | 102.0727272727 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. Two children filled partially, one DELeted. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | 0.0    | 1.0       | 1.0    | 102.0 |      | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      8 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 3.0  | 3.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      9 | x0-00004 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 3.0       | 8.0    | 102.0 |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 3.0     | 102.2  | 0.0       | 3.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx          | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 3.0     | 102.2  | 0.0       | 11.0   | 102.0545454545 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. Two children fully filled, one DELeted. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      8 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      9 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 2.0       | 9.0    | 102.0 |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx          | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.0363636363 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. Three children filled partially. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | 0.0    | 1.0       | 1.0    | 102.0 | Order not in OrderBook 'x0-00002' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
	Then no execution report is sent to client
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 1.0  | 1.0      | 102.2 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |     10 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 1.0       | 10.0   | 102.0 |      | false  | false |

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     11 | x0-00004 | 1.0     | 102.2  | 0.0       | 1.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx          | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     11 | x0-00004 |      8 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 1.0     | 102.2  | 0.0       | 11.0   | 102.0181818181 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseDelAddForPriceChange. All children fully filled. Parent RWT is ACKed as order is fully filled.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      9 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 0.0       | 11.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. No fill. Child RWT are ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      4 | x0-00001 | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 11.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~0-0 |      7 | x0-00001 | 7.0     | 102.2  | 0.0       | 7.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00001 |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 7.0     | 102.2  | 4.0       | 7.0    | 102.2 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 2.0       | 9.0    | 102.2 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |      9 | x0-00003 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00003 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.2 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. One child partially filled, all RWTs ACKed. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 5.0     | 102.0  | 6.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      5 | x0-00001 | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 6.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | done  |
	| RWT     | FILL   | 00001~0-1 |      8 | x0-00001 | 2.0     | 102.2  | 0.0       | 7.0    | 102.057142857 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00001 |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 4.0       | 7.0    | 102.057142857 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-0 |      9 | x0-00002 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00002 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 2.0       | 9.0    | 102.088888888 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |     10 | x0-00003 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     10 | x0-00003 |      8 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.109090909 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. One child fully filled, other child RWTs ACKed. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      5 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

   When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-0 |      8 | x0-00002 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00002 |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 2.0       | 9.0    | 102.044444444 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |      9 | x0-00003 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00003 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.072727272 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. One child fully filled and one partially filled, two child RWTs ACKed. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | 0.0    | 1.0       | 1.0    | 102.0 |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      8 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~1-0 |      9 | x0-00002 | 1.0     | 102.2  | 0.0       | 2.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00002 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 1.0     | 102.2  | 2.0       | 9.0    | 102.022222222 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |     10 | x0-00003 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     10 | x0-00003 |      8 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.054545454 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. Two children fully filled, last child RWT ACKed. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      6 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      8 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-0 |      9 | x0-00003 | 2.0     | 102.2  | 0.0       | 2.0    | 102.2 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      9 | x0-00003 |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 2.0     | 102.2  | 0.0       | 11.0   | 102.036363636 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. Two children fully and one partially filled, last child RWT ACKed. Parent RWT is ACKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      9 | x0-00003 | 0.0     | 0.0    | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-1 |     10 | x0-00003 | 1.0     | 102.2  | 0.0       | 2.0    | 102.1 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx         | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |     10 | x0-00003 |      8 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 1.0     | 102.2  | 0.0       | 11.0   | 102.018181818 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (price change). UseRwtForPriceChange. All children fully filled, all child RWT NAKed. Parent RWT is NAKed.

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
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~2-1 |      9 | x0-00003 | 0.0     | 0.0    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.2 | 11.0 | 11.0     | 0.0     | NaN    | 0.0       | 11.0   | 102.0 | Order already completed | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT.

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      4 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 10.0      | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      5 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 7.0     | 102.0  | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      6 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 1.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-1 |      7 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 1.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT. Fill for child 1 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 3.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      6 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 2.0     | 102.0  | 1.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-1 |      7 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 1.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT. Fills for children 1&2(partial) and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 2.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      7 | x0-00002 | 1.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00002 |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 1.0     | 102.0  | 1.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-1 |      8 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00003 |      8 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 1.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT. Fills for children 1&2 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 1.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | FILL   | 00001~2-1 |      7 | x0-00003 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00003 |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 1.0     | 102.0  | 0.0       | 10.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT. Fills for children 1&2&3(partial) and request for child 3 cross. 

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | 0.0       | 10.0   | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 RWT. Fills for children 1&2&3 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 10.0 | 10.0     |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| RWT     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 10.0 | 10.0     | 0.0     | NaN    | -1.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      4 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 9.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      5 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      5 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 7.0     | 102.0  | 2.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      6 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 2.0     | 102.0  | 0.0       | 9.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fill for child 1 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 2.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      6 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 2.0     | 102.0  | 0.0       | 9.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fills for children 1&2(partial) and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 1.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      7 | x0-00002 | 1.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00002 |      7 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 1.0     | 102.0  | 0.0       | 9.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fills for children 1&2 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | 0.0       | 9.0    | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fills for children 1&2&3 and request for child 3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | -2.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fills for children 1&2&3(partial) and request for child 3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | -1.0      | 10.0   | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL. Fills for children 1&2&3(partial) and request for child 3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 9.0  | 9.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty  |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0  |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 9.0  | 9.0      | 0.0     | NaN    | -1.0      | 10.0   | 102.0 | Too late to replace | true   | true  |

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL and child 2 RWT.

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
	| RWT     | 00001 | 3   | 102.0 | 8.0  | 8.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      4 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 0.0     | NaN    | 8.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 7.0     | 102.0  | 1.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      7 | x0-00002 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 1.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

Scenario: Three active children. RWT (size decrease). Child 3 DEL and child 2 RWT. Fill for child 1 and requests for children 2&3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 8.0  | 8.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 0.0     | NaN    | 1.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      7 | x0-00002 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00002 |      6 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 1.0     | 102.0  | 0.0       | 8.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL and child 2 RWT. Fills for children 1&2(partial) and requests for children 2&3 cross. Parent RWT is ACKed.

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
	| RWT     | 00001 | 3   | 102.0 | 8.0  | 8.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 0.0     | NaN    | 0.0       | 8.0    | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL and child 2 RWT. Fills for children 1&2(full) and requests for children 2&3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 8.0  | 8.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 0.0     | NaN    | -1.0      | 9.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Child 3 DEL and child 2 RWT. Fills for children 1&2(full) and requests for children 2&3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 8.0  | 8.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 1.0 | 1.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 8.0  | 8.0      | 0.0     | NaN    | -1.0      | 9.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      4 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 7.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      6 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      6 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Partial fill for child 1 and requests for children 2&3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 5.0     | 102.0  | 6.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00001 |      6 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 2.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Full fill for child 1 and requests for children 2&3 cross.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | 0.0       | 7.0    | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2(partial) and requests for children 2&3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -1.0      | 8.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00002 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00002 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 | x0-00002 |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 3.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2 and requests for children 2&3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -2.0      | 9.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2&3(partial) and requests for children 2&3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -3.0      | 10.0   | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      9 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
  Then no execution report is sent to client
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |     10 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2&3 and requests for children 2&3 cross. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -4.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2(partial) and requests for children 2&3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 1.0       | 1.0    | 0.0   |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -1.0      | 8.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2 and requests for children 2&3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -2.0      | 9.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2&3(partial) and DEL requests for children 2&3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      8 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -3.0      | 10.0   | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL. Fills for children 1&2&3 and requests for children 2&3 cross. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 7.0  | 7.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 7.0  | 7.0      | 0.0     | NaN    | -4.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      4 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      5 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      6 | x0-00001 | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      4 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | 6.0       | 0.0    | 0.0   |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      7 | x0-00001 | 6.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      7 | x0-00001 |      5 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 6.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Partial fill for child 1 crosses requests for children 1&2&3. Child RWT request is above filled.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 5.0     | 102.0  | 2.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 5.0     | 102.0  | 6.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      7 | x0-00001 | 0.0     | NaN    | 1.0       | 5.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | 1.0       | 5.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      8 | x0-00001 | 1.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 3   |      8 | x0-00001 |      6 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 1.0     | 102.0  | 0.0       | 6.0    | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Partial fill for child 1 crosses requests for children 1&2&3. Child RWT request is at filled.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 6.0     | 102.0  | 1.0       | 6.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 6.0     | 102.0  | 5.0       | 6.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| RWT     | ACK    | 00001~0-1 |      7 | x0-00001 | 0.0     | NaN    | 0.0       | 6.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                    | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | 0.0       | 6.0    | 102.0 | Order already completed | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Partial fill for child 1 crosses requests for children 1&2&3. Child RWT request is below filled. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -1.0      | 7.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 4.0  | 4.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      8 | x0-00004 | 0.0     | NaN    | 4.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |      9 | x0-00004 | 4.0     | 102.0  | 0.0       | 4.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      9 | x0-00004 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 4.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Partial fill for child 1 crosses requests for children 1&2&3. Child RWT request is below filled. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      5 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      6 | x0-00002 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      7 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      5 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -1.0      | 7.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2(partial) cross requests for children 1&2&3. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -2.0      | 8.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 3.0  | 3.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      9 | x0-00004 | 0.0     | NaN    | 3.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 3.0     | 102.0  | 0.0       | 3.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 3.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2(partial) cross requests for children 1&2&3. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 3.0       | 8.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -2.0      | 8.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2 cross requests for children 1&2&3. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -3.0      | 9.0    | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 2.0  | 2.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |      9 | x0-00004 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     10 | x0-00004 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |     10 | x0-00004 |      7 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2 cross requests for children 1&2&3. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      6 | x0-00003 | 0.0     | NaN    | 2.0       | 0.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      7 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 102.0 | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      8 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      6 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -3.0      | 9.0    | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2&3(partial) cross requests for children 1&2&3. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 0.0   |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 102.0 | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      9 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -4.0      | 10.0   | 102.0 | Too late to replace | false  | false |
  And one or more children orders are sent to exchange
	| reqType | clOrdID   | side | qty  | shownQty | px    | tif |
	| ADD     | 00001~3-0 | Buy  | 1.0  | 1.0      | 102.0 | DAY |

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | ACK    | 00001~3-0 |     10 | x0-00004 | 0.0     | NaN    | 1.0       | 0.0    | 0.0   |      | false |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~3-0 |     11 | x0-00004 | 1.0     | 102.0  | 0.0       | 1.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |     11 | x0-00004 |      8 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2&3(partial) cross requests for children 1&2&3. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 1.0     | 102.0  | 1.0       | 1.0    | 102.0 |      | false |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 1.0     | 102.0  | 1.0       | 10.0   | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| DEL     | ACK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 1.0       | 1.0    | 102.0 |      | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      9 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -4.0      | 10.0   | 102.0 | Too late to replace | true   | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2&3 cross requests for children 1&2&3. StrictRWT.

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      9 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | NAK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -5.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

@OptimizedRwt
Scenario: Three active children. RWT (size decrease). Children 2&3 DEL and child 1 RWT. Fills for children 1&2&3 cross requests for children 1&2&3. LaxRWT.

	Given the OrderManagerService is further configured with
	| strictRwt |
	| false     |

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
	| RWT     | 00001 | 3   | 102.0 | 6.0  | 6.0      |
  Then one or more children orders are sent to exchange
	| reqType | clOrdID   | origClOrdId | ecnOrdId | side | qty | shownQty | px    | tif |
	| DEL     | 00001~2-1 | 00001~2-0   | x0-00003 | Buy  | 2.0 |          |       |     |
	| DEL     | 00001~1-1 | 00001~1-0   | x0-00002 | Buy  | 2.0 |          |       |     |
	| RWT     | 00001~0-1 | 00001~0-0   | x0-00001 | Buy  | 6.0 | 6.0      | 102.0 | DAY |
  And no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~0-0 |      4 | x0-00001 | 7.0     | 102.0  | 0.0       | 7.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      4 | x0-00001 |      4 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 7.0     | 102.0  | 4.0       | 7.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~1-0 |      5 | x0-00002 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      5 | x0-00002 |      5 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 2.0       | 9.0    | 102.0 |      | false  | false |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text | done  |
	| ADD     | FILL   | 00001~2-0 |      6 | x0-00003 | 2.0     | 102.0  | 0.0       | 2.0    | 102.0 |      | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text | ftDone | done  |
	| RWT     | FILL   | 00001 | 2   |      6 | x0-00003 |      6 | DAY         | Buy  | 102.0 | 11.0 | 11.0     | 2.0     | 102.0  | 0.0       | 11.0   | 102.0 |      | true   | true  |
  And no child order is sent to exchange

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~2-1 |      7 | x0-00003 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00003' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| DEL     | NAK    | 00001~1-1 |      8 | x0-00002 | 0.0     | NaN    | 0.0       | 0.0    | 102.0 | Order not in OrderBook 'x0-00002' | true  |
	Then no execution report is sent to client

  When an execution report is received from exchange for child order
	| reqType | status | clOrdId   | fillId | ecnOrdId | lastQty | lastPx | leavesQty | cumQty | avgPx | text                              | done  |
	| RWT     | NAK    | 00001~0-1 |      9 | x0-00001 | 0.0     | NaN    | 0.0       | 0.0    | 0.0   | Order not in OrderBook 'x0-00001' | true  |
  Then one or more execution reports are sent to client for parent order
	| reqType | status | ordId | ver | fillId | ecnOrdId | execId | timeInForce | side | price | qty  | shownQty | lastQty | lastPx | leavesQty | cumQty | avgPx | text                | ftDone | done  |
	| RWT     | ACK    | 00001 | 3   |        |          |      7 | DAY         | Buy  | 102.0 | 6.0  | 6.0      | 0.0     | NaN    | -5.0      | 11.0   | 102.0 | Too late to replace | false  | true  |
  And no child order is sent to exchange

