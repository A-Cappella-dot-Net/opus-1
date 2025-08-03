Feature: Cembalo - Executions on New

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders

  Scenario Outline: IOC order. No order in the stack. No execution.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | IOC | <side> | <sQty>   | <qty>   | 102.0 |
    Then no market data snapshot for 912828Q45 is sent
    And there are no continuous orders for instrument 912828Q45 and side <side> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | IOC | <side> | <sQty>   | <qty>   | 102.0 | New      | New       | 0.0     | NaN    | <qty>     | 0.0    | NaN   |                           |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | IOC | <side> | <sQty>   | <qty>   | 102.0 | Canceled | Canceled  | 0.0     | NaN    | <qty>     | 0.0    | NaN   | Could not match IOC order |

    Examples: Relevant Combinations
      | side | sQty | qty |
      | Buy  | 7.0  | 9.0 |
      | Sell | 7.0  | 9.0 |
      | Buy  | 7.0  | 7.0 |
      | Sell | 7.0  | 7.0 |

  Scenario Outline: Non tradable IOC order. No execution.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty  | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 10.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 10.0 | 102.0 | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side     | shownQty | qty     | price     |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | <price-i> |
    Then no market data snapshot for 912828Q45 is sent
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 10.0 and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text                      |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | <price-i> | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |                           |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | <price-i> | Canceled | Canceled  | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   | Could not match IOC order |

    Examples: Relevant Combinations
      | side | side-i | sQty-i | qty-i | price-i | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 |
      | Buy  | Sell   | 7.0    | 9.0   | 103.0   | 1.0     | 102.0  | NaN    | 0.0     |
      | Sell | Buy    | 7.0    | 9.0   | 101.0   | 0.0     | NaN    | 102.0  | 1.0     |
      | Buy  | Sell   | 7.0    | 7.0   | 103.0   | 1.0     | 102.0  | NaN    | 0.0     |
      | Sell | Buy    | 7.0    | 7.0   | 101.0   | 0.0     | NaN    | 102.0  | 1.0     |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | 1.0 | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 15.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx    | leavesQty | cumQty | avgPx     |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 1.0     | <price-0> | 7.0       | 1.0    | <price-0> |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN       | 3.0       | 0.0    | NaN       |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN       | 5.0       | 0.0    | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty | price     | execType | ordStatus       | lastQty | lastPx    | leavesQty | cumQty  | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | 1.0 | 102.0     | New      | New             | 0.0     | NaN       | 1.0       | 0.0     | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0 | <price-0> | Trade    | PartiallyFilled | 1.0     | <price-0> | 7.0       | 1.0     | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | 1.0 | 102.0     | Trade    | Filled          | 1.0     | <price-0> | 0.0       | 1.0     | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Pf. o02=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves <lQty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <xQty-2> | <price-0> | <lQty-2>  | <xQty-2> | <price-0> |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0      | NaN       | 5.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | PartiallyFilled | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | PartiallyFilled | <xQty-2> | <price-0> | <lQty-2>  | <xQty-2> | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <price-0> | 0.0       | <qty-i>  | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | xQty-2 | lQty-2 | lQty-3 | sQty-3 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 5.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 5.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 5.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 5.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 5.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 5.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 5.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 2.0   | 1.0    | 7.0    | 1.0    | 2.0    | 14.0   | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 5.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 3.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 3.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 3.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 3.0    | 3.0   | 1.0    | 7.0    | 2.0    | 1.0    | 13.0   | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 101.5  | 11.0    | 102.0  | 16.0    |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Pf. o02=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves <lQty-2> and shown 3.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0      | NaN       | 5.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | PartiallyFilled | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <price-0> | 0.0       | <qty-i>  | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | lQty-2 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 2.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 2.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 3.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 3.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 3.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 3.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 4.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 4.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 4.0    | 4.0   | 1.0    | 7.0    | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 4.0    | 4.0   | 1.0    | 7.0    | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Pf. o02=Cf, o03=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves <lQty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <xQty-3> | <price-0> | <lQty-3>  | <xQty-3> | <price-0> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | PartiallyFilled | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | PartiallyFilled | <xQty-3> | <price-0> | <lQty-3>  | <xQty-3> | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <price-0> | 0.0       | <qty-i>  | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | xQty-3 | lQty-3 | lQty-4 | sQty-4 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 5.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 5.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 5.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 5.0    | 5.0   | 1.0    | 7.0    | 1.0    | 4.0    | 11.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 6.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 6.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 6.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 6.0    | 6.0   | 1.0    | 7.0    | 2.0    | 3.0    | 10.0   | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 7.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 7.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 7.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 7.0    | 7.0   | 2.0    | 6.0    | 2.0    | 3.0    | 9.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 8.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 8.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 8.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 3.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 8.0    | 8.0   | 2.0    | 6.0    | 3.0    | 2.0    | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 3.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 9.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 9.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 9.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 9.0    | 9.0   | 2.0    | 6.0    | 4.0    | 1.0    | 7.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 10.0   | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 10.0   | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 10.0   | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 10.0   | 10.0  | 3.0    | 5.0    | 4.0    | 1.0    | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 101.5  | 11.0    | 102.0  | 16.0    |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Pf. o02=Cf, o03=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves <lQty-1> and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | PartiallyFilled | <xQty-1> | <price-0> | <lQty-1>  | <xQty-1> | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <price-0> | 0.0       | <qty-i>  | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 11.0  | 3.0    | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 11.0  | 3.0    | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 11.0  | 3.0    | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 11.0  | 3.0    | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 11.0   | 11.0  | 3.0    | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 11.0   | 11.0  | 3.0    | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 11.0   | 11.0  | 3.0    | 5.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 11.0   | 11.0  | 3.0    | 5.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 12.0  | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 12.0  | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 12.0  | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 12.0  | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 12.0   | 12.0  | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 12.0   | 12.0  | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 12.0   | 12.0  | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 12.0   | 12.0  | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 15.0  | 7.0    | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 15.0  | 7.0    | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 15.0  | 7.0    | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 15.0  | 7.0    | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 15.0   | 15.0  | 7.0    | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 15.0   | 15.0  | 7.0    | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 15.0   | 15.0  | 7.0    | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 16.0    | 102.0  | 11.0    | 102.5  | 1.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 15.0   | 15.0  | 7.0    | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 1.0     | 101.5  | 11.0    | 102.0  | 16.0    |

  Scenario Outline: Three level stack. Sweep level 0 only. Round robin fills. o01=Cf. o02=Cf, o03=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <price-0> | 0.0       | <qty-i>  | <price-0> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 16.0  || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 11.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 16.0  || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 11.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 16.0  || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 11.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 16.0  || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 11.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 16.0   | 16.0  || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 11.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 16.0   | 16.0  || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 11.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 16.0   | 16.0  || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 11.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 16.0   | 16.0  || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 11.0    | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves <lQty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <xQty-1> | <price-1> | <lQty-1>  | <xQty-1> | <price-1> |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0      | NaN       | 6.0       | 0.0      | NaN       |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0      | NaN       | 7.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | PartiallyFilled | <xQty-1> | <price-1> | <lQty-1>  | <xQty-1> | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx>   | 0.0       | <qty-i>  | <avgPx>   |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | avgPx         | lQty-2 | sQty-2 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 17.0  | 1.0    | 3.0    | 102.970588235 | 16.0   | 10.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 10.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 17.0  | 1.0    | 3.0    | 101.029411764 | 16.0   | 10.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 10.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 17.0  | 1.0    | 3.0    | 102.970588235 | 16.0   | 10.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 10.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 17.0  | 1.0    | 3.0    | 101.029411764 | 16.0   | 10.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 10.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 17.0   | 17.0  | 1.0    | 3.0    | 102.970588235 | 16.0   | 10.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 10.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 17.0   | 17.0  | 1.0    | 3.0    | 101.029411764 | 16.0   | 10.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 10.0    | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 17.0   | 17.0  | 1.0    | 3.0    | 102.970588235 | 16.0   | 10.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 10.0    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 17.0   | 17.0  | 1.0    | 3.0    | 101.029411764 | 16.0   | 10.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 10.0    | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 19.0  | 3.0    | 1.0    | 102.921052631 | 14.0   | 8.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 8.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 19.0  | 3.0    | 1.0    | 101.078947368 | 14.0   | 8.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 8.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 19.0  | 3.0    | 1.0    | 102.921052631 | 14.0   | 8.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 8.0     | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 19.0  | 3.0    | 1.0    | 101.078947368 | 14.0   | 8.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 8.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 19.0   | 19.0  | 3.0    | 1.0    | 102.921052631 | 14.0   | 8.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 8.0     | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 19.0   | 19.0  | 3.0    | 1.0    | 101.078947368 | 14.0   | 8.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 8.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 19.0   | 19.0  | 3.0    | 1.0    | 102.921052631 | 14.0   | 8.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 8.0     | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 19.0   | 19.0  | 3.0    | 1.0    | 101.078947368 | 14.0   | 8.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 8.0     | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves 13.0 and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0      | NaN       | 6.0       | 0.0      | NaN       |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0      | NaN       | 7.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx>   | 0.0       | <qty-i>  | <avgPx>   |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | avgPx || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 20.0  | 102.9 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 20.0  | 101.1 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 20.0  | 102.9 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 20.0  | 101.1 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 20.0   | 20.0  | 102.9 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 20.0   | 20.0  | 101.1 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 20.0   | 20.0  | 102.9 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 20.0   | 20.0  | 101.1 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Cf, o12=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves <lQty-3> and shown 7.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0      | NaN       | 7.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | PartiallyFilled | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-2 | lQty-2 | avgPx-i       | lQty-3 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 21.0  | 1.0    | 5.0    | 102.880952380 | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 21.0  | 1.0    | 5.0    | 101.119047619 | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 21.0  | 1.0    | 5.0    | 102.880952380 | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 21.0  | 1.0    | 5.0    | 101.119047619 | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 21.0   | 21.0  | 1.0    | 5.0    | 102.880952380 | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 21.0   | 21.0  | 1.0    | 5.0    | 101.119047619 | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 21.0   | 21.0  | 1.0    | 5.0    | 102.880952380 | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 21.0   | 21.0  | 1.0    | 5.0    | 101.119047619 | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 22.0  | 2.0    | 4.0    | 102.863636363 | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 22.0  | 2.0    | 4.0    | 101.136363636 | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 22.0  | 2.0    | 4.0    | 102.863636363 | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 22.0  | 2.0    | 4.0    | 101.136363636 | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 22.0   | 22.0  | 2.0    | 4.0    | 102.863636363 | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 22.0   | 22.0  | 2.0    | 4.0    | 101.136363636 | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 22.0   | 22.0  | 2.0    | 4.0    | 102.863636363 | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 22.0   | 22.0  | 2.0    | 4.0    | 101.136363636 | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Cf, o12=Pf, o13=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves <lQty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <xQty-3> | <price-1> | <lQty-3>  | <xQty-3> | <price-1> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | PartiallyFilled | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | PartiallyFilled | <xQty-3> | <price-1> | <lQty-3>  | <xQty-3> | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-2 | lQty-2 | xQty-3 | lQty-3 | avgPx-i       | lQty-4 | sQty-4 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 102.847826086 | 10.0   | 7.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 101.152173913 | 10.0   | 7.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 102.847826086 | 10.0   | 7.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 101.152173913 | 10.0   | 7.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 23.0   | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 102.847826086 | 10.0   | 7.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 23.0   | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 101.152173913 | 10.0   | 7.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 23.0   | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 102.847826086 | 10.0   | 7.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 7.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 23.0   | 23.0  | 2.0    | 4.0    | 1.0    | 6.0    | 101.152173913 | 10.0   | 7.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 7.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 102.796296296 | 6.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 101.203703703 | 6.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 102.796296296 | 6.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 101.203703703 | 6.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 27.0   | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 102.796296296 | 6.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 27.0   | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 101.203703703 | 6.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 27.0   | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 102.796296296 | 6.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 27.0   | 27.0  | 2.0    | 4.0    | 5.0    | 2.0    | 101.203703703 | 6.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 102.785714285 | 5.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 101.214285714 | 5.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 102.785714285 | 5.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 101.214285714 | 5.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 28.0   | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 102.785714285 | 5.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 28.0   | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 101.214285714 | 5.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 28.0   | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 102.785714285 | 5.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 28.0   | 28.0  | 3.0    | 3.0    | 5.0    | 2.0    | 101.214285714 | 5.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 102.775862068 | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 101.224137931 | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 102.775862068 | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 101.224137931 | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 29.0   | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 102.775862068 | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 29.0   | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 101.224137931 | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 29.0   | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 102.775862068 | 4.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 4.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 29.0   | 29.0  | 4.0    | 2.0    | 5.0    | 2.0    | 101.224137931 | 4.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 4.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 102.766666666 | 3.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 3.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 101.233333333 | 3.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 3.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 102.766666666 | 3.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 3.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 101.233333333 | 3.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 3.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 30.0   | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 102.766666666 | 3.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 3.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 30.0   | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 101.233333333 | 3.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 3.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 30.0   | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 102.766666666 | 3.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 3.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 30.0   | 30.0  | 4.0    | 2.0    | 6.0    | 1.0    | 101.233333333 | 3.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 3.0     | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Cf, o12=Pf, o13=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves <lQty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | PartiallyFilled | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-2 | lQty-2 | avgPx-i       | sQty-2 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 31.0  | 4.0    | 2.0    | 102.758064516 | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 2.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 31.0  | 4.0    | 2.0    | 101.241935483 | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 2.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 31.0  | 4.0    | 2.0    | 102.758064516 | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 2.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 31.0  | 4.0    | 2.0    | 101.241935483 | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 2.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 31.0   | 31.0  | 4.0    | 2.0    | 102.758064516 | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 2.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 31.0   | 31.0  | 4.0    | 2.0    | 101.241935483 | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 2.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 31.0   | 31.0  | 4.0    | 2.0    | 102.758064516 | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 2.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 31.0   | 31.0  | 4.0    | 2.0    | 101.241935483 | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 2.0     | 102.0  | 16.0    | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 32.0  | 5.0    | 1.0    | 102.75        | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 1.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 32.0  | 5.0    | 1.0    | 101.25        | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 1.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 32.0  | 5.0    | 1.0    | 102.75        | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 1.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 32.0  | 5.0    | 1.0    | 101.25        | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 1.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 32.0   | 32.0  | 5.0    | 1.0    | 102.75        | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 1.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 32.0   | 32.0  | 5.0    | 1.0    | 101.25        | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 1.0     | 102.0  | 16.0    | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 32.0   | 32.0  | 5.0    | 1.0    | 102.75        | 1.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 16.0    | 102.0  | 1.00    | 102.5  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 32.0   | 32.0  | 5.0    | 1.0    | 101.25        | 1.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.5  | 1.0     | 102.0  | 16.0    | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep levels 0 and 1 only. Round robin fills. o11=Cf, o12=Cf, o13=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves 24.0 and shown 16.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | avgPx-i       || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 33.0  | 102.742424242 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 33.0  | 101.257575757 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 33.0  | 102.742424242 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 33.0  | 101.257575757 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 33.0   | 33.0  | 102.742424242 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 33.0   | 33.0  | 101.257575757 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 33.0   | 33.0  | 102.742424242 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 33.0   | 33.0  | 101.257575757 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-2> and shown 16.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | 0.0      | NaN       | 8.0       | 0.0      | NaN       |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | 0.0      | NaN       | 9.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | avgPx-i       | lQty-2 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 34.0  | 1.0    | 6.0    | 102.720588235 | 23.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 34.0  | 1.0    | 6.0    | 101.279411764 | 23.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 34.0  | 1.0    | 6.0    | 102.720588235 | 23.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 34.0  | 1.0    | 6.0    | 101.279411764 | 23.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 34.0   | 34.0  | 1.0    | 6.0    | 102.720588235 | 23.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 34.0   | 34.0  | 1.0    | 6.0    | 101.279411764 | 23.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 34.0   | 34.0  | 1.0    | 6.0    | 102.720588235 | 23.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 34.0   | 34.0  | 1.0    | 6.0    | 101.279411764 | 23.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Pf, o22=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | 0.0      | NaN       | 9.0       | 0.0      | NaN       |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY   | <side>   | 6.0      | 8.0     | <price-2> | Trade    | PartiallyFilled | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | xQty-2 | lQty-2 | avgPx-i       | lQty-3 | sQty-3 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 102.7         | 22.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 101.3         | 22.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 102.7         | 22.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 101.3         | 22.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 35.0   | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 102.7         | 22.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 35.0   | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 101.3         | 22.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 35.0   | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 102.7         | 22.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 35.0   | 35.0  | 1.0    | 6.0    | 1.0    | 7.0    | 101.3         | 22.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 102.680555555 | 21.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 101.319444444 | 21.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 102.680555555 | 21.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 101.319444444 | 21.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 36.0   | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 102.680555555 | 21.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 36.0   | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 101.319444444 | 21.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 36.0   | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 102.680555555 | 21.0   | 16.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 16.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 36.0   | 36.0  | 1.0    | 6.0    | 2.0    | 6.0    | 101.319444444 | 21.0   | 16.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 16.0    | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 102.662162162 | 20.0   | 15.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 15.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 101.337837837 | 20.0   | 15.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 15.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 102.662162162 | 20.0   | 15.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 15.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 101.337837837 | 20.0   | 15.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 15.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 37.0   | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 102.662162162 | 20.0   | 15.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 15.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 37.0   | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 101.337837837 | 20.0   | 15.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 15.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 37.0   | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 102.662162162 | 20.0   | 15.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 15.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 37.0   | 37.0  | 1.0    | 6.0    | 3.0    | 5.0    | 101.337837837 | 20.0   | 15.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 15.0    | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.6125      | 17.0   | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 12.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.3875      | 17.0   | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 12.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.6125      | 17.0   | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 12.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.3875      | 17.0   | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 12.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 40.0   | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.6125      | 17.0   | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 12.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 40.0   | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.3875      | 17.0   | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 12.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 40.0   | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.6125      | 17.0   | 12.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 12.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 40.0   | 40.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.3875      | 17.0   | 12.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 12.0    | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Pf, o22=Pf, o23=Pf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <xQty-3> | <price-2> | <lQty-3>  | <xQty-3> | <price-2> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY   | <side>   | 6.0      | 8.0     | <price-2> | Trade    | PartiallyFilled | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY   | <side>   | 9.0      | 9.0     | <price-2> | Trade    | PartiallyFilled | <xQty-3> | <price-2> | <lQty-3>  | <xQty-3> | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | xQty-2 | lQty-2 | xQty-3 | lQty-3 | avgPx-i       | lQty-4 | sQty-4 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 102.597560975 | 16.0   | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 11.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 101.402439024 | 16.0   | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 11.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 102.597560975 | 16.0   | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 11.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 101.402439024 | 16.0   | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 11.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 41.0   | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 102.597560975 | 16.0   | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 11.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 41.0   | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 101.402439024 | 16.0   | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 11.0    | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 41.0   | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 102.597560975 | 16.0   | 11.0   || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 11.0    | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 41.0   | 41.0  | 1.0    | 6.0    | 6.0    | 2.0    | 1.0    | 8.0    | 101.402439024 | 16.0   | 11.0   || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 11.0    | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 102.510416666 | 9.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 101.489583333 | 9.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 102.510416666 | 9.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 101.489583333 | 9.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 48.0   | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 102.510416666 | 9.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 48.0   | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 101.489583333 | 9.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 48.0   | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 102.510416666 | 9.0    | 4.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 48.0   | 48.0  | 1.0    | 6.0    | 6.0    | 2.0    | 8.0    | 1.0    | 101.489583333 | 9.0    | 4.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Pf, o22=Pf, o23=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY   | <side>   | 6.0      | 8.0     | <price-2> | Trade    | PartiallyFilled | <xQty-2> | <price-2> | <lQty-2>  | <xQty-2> | <price-2> |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY   | <side>   | 9.0      | 9.0     | <price-2> | Trade    | Filled          | 9.0      | <price-2> | 0.0       | 9.0      | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | xQty-2 | lQty-2 | avgPx-i       | lQty-3 | sQty-3 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.5         | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.5         | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.5         | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.5         | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 49.0   | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.5         | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 49.0   | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.5         | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 49.0   | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 102.5         | 8.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 49.0   | 49.0  | 1.0    | 6.0    | 6.0    | 2.0    | 101.5         | 8.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 102.49        | 7.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 101.51        | 7.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 102.49        | 7.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 101.51        | 7.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 50.0   | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 102.49        | 7.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 50.0   | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 101.51        | 7.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 50.0   | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 102.49        | 7.0    | 3.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 50.0   | 50.0  | 2.0    | 5.0    | 6.0    | 2.0    | 101.51        | 7.0    | 3.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 102.480392156 | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 2.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 101.519607843 | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 2.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 102.480392156 | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 2.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 101.519607843 | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 2.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 51.0   | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 102.480392156 | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 2.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 51.0   | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 101.519607843 | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 2.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 51.0   | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 102.480392156 | 6.0    | 2.0    || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 2.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 51.0   | 51.0  | 2.0    | 5.0    | 7.0    | 1.0    | 101.519607843 | 6.0    | 2.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 2.0     | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Pf, o22=Cf, o23=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-1> and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | <xQty-1> | <price-2> | <lQty-1>  | <xQty-1> | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY   | <side>   | 6.0      | 8.0     | <price-2> | Trade    | Filled          | 8.0      | <price-2> | 0.0       | 8.0      | <price-2> |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY   | <side>   | 9.0      | 9.0     | <price-2> | Trade    | Filled          | 9.0      | <price-2> | 0.0       | 9.0      | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | xQty-1 | lQty-1 | avgPx-i       || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 52.0  | 2.0    | 5.0    | 102.471153846 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 52.0  | 2.0    | 5.0    | 101.528846153 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 52.0  | 2.0    | 5.0    | 102.471153846 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 52.0  | 2.0    | 5.0    | 101.528846153 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 52.0   | 52.0  | 2.0    | 5.0    | 102.471153846 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 52.0   | 52.0  | 2.0    | 5.0    | 101.528846153 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 52.0   | 52.0  | 2.0    | 5.0    | 102.471153846 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 52.0   | 52.0  | 2.0    | 5.0    | 101.528846153 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |

      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 56.0  | 6.0    | 1.0    | 102.4375      || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 56.0  | 6.0    | 1.0    | 101.5625      || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 56.0  | 6.0    | 1.0    | 102.4375      || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 56.0  | 6.0    | 1.0    | 101.5625      || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 56.0   | 56.0  | 6.0    | 1.0    | 102.4375      || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 56.0   | 56.0  | 6.0    | 1.0    | 101.5625      || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 56.0   | 56.0  | 6.0    | 1.0    | 102.4375      || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 56.0   | 56.0  | 6.0    | 1.0    | 101.5625      || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     |

  Scenario Outline: Three level stack. Sweep all three levels. Round robin fills. o21=Cf, o22=Cf, o23=Cf.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif   | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And there are no continuous orders for instrument 912828Q45 and side <side> at level 0
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif   | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY   | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY   | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY   | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY   | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY   | <side>   | 1.0      | 7.0     | <price-2> | Trade    | Filled          | 7.0      | <price-2> | 0.0       | 7.0      | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY   | <side>   | 6.0      | 8.0     | <price-2> | Trade    | Filled          | 8.0      | <price-2> | 0.0       | 8.0      | <price-2> |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY   | <side>   | 9.0      | 9.0     | <price-2> | Trade    | Filled          | 9.0      | <price-2> | 0.0       | 9.0      | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | <tif> | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | Filled          | <qty-i>  | <avgPx-i> | 0.0       | <qty-i>  | <avgPx-i> |      |

    Examples: Relevant Combinations
      | ordType | tif | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | avgPx-i       || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 57.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 57.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 57.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 57.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 57.0   | 57.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | IOC | Buy    | Sell | 101.0   | 101.5   | 102.0   | 57.0   | 57.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 57.0   | 57.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Limit   | DAY | Buy    | Sell | 101.0   | 101.5   | 102.0   | 57.0   | 57.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |


  Scenario Outline: IOC order sweeps a three level stack. Partial fill, order is canceled.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And there are no continuous orders for instrument 912828Q45 and side <side> at level 0
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text                      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |                           |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |                           |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |                           |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |                           |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |                           |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |                           |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |                           |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 7.0     | <price-2> | Trade    | Filled          | 7.0      | <price-2> | 0.0       | 7.0      | <price-2> |                           |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side>   | 6.0      | 8.0     | <price-2> | Trade    | Filled          | 8.0      | <price-2> | 0.0       | 8.0      | <price-2> |                           |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side>   | 9.0      | 9.0     | <price-2> | Trade    | Filled          | 9.0      | <price-2> | 0.0       | 9.0      | <price-2> |                           |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | PartiallyFilled | 57.0     | <avgPx-i> | 1.0       | 57.0     | <avgPx-i> |                           |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | IOC | <side-i> | <sQty-i> | <qty-i> | 102.0     | Canceled | Canceled        | 0.0      | NaN       | 1.0       | 57.0     | <avgPx-i> | Could not match IOC order |

    Examples: Relevant Combinations
      | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | avgPx-i       || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 |
      | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 58.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | NaN    | 0.0     |
      | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 58.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | NaN    | 0.0     |
      | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 58.0   | 58.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | NaN    | 0.0     |
      | Buy    | Sell | 101.0   | 101.5   | 102.0   | 58.0   | 58.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 0.0     | NaN    | NaN    | 0.0     |

  Scenario Outline: DAY order sweeps a three level stack. Partial fill, remainder rests.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> |
      | id1 | 912828Q45 |     3 | 00003-0 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> |
      | id1 | 912828Q45 |     4 | 00011-0 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> |
      | id1 | 912828Q45 |     5 | 00012-0 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> |
      | id1 | 912828Q45 |     6 | 00013-0 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> |
      | id1 | 912828Q45 |     7 | 00021-0 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> |
      | id1 | 912828Q45 |     8 | 00022-0 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> |
      | id1 | 912828Q45 |     9 | 00023-0 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 16.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | 0.0     | NaN    | 8.0       | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 17.0 and shown 11.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | 0.0     | NaN    | 7.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 8.0 | <price-0> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 3.0 | <price-0> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 5.0 | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 4.0      | 4.0 | <price-1> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 6.0 | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 5.0      | 7.0 | <price-1> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0 | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 6.0      | 8.0 | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 9.0      | 9.0 | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side     | shownQty | qty     | price |
      | id1 | 912828Q45 |    10 | 00000-0 | Limit   | DAY | <side-i> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side-i> at level 0 with price <price-2> and leaves 1.0 and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | lastQty | lastPx    | leavesQty | cumQty    | avgPx     |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | DAY | <side-i> | <sQty-i> | <qty-i> | 57.0    | <avgPx-i> | 1.0       | 57.0      | <avgPx-i> |
    And there are no continuous orders for instrument 912828Q45 and side <side> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | DAY | <side-i> | <sQty-i> | <qty-i> | 102.0     | New      | New             | 0.0      | NaN       | <qty-i>   | 0.0      | NaN       |      |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 8.0     | <price-0> | Trade    | Filled          | 8.0      | <price-0> | 0.0       | 8.0      | <price-0> |      |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 3.0     | <price-0> | Trade    | Filled          | 3.0      | <price-0> | 0.0       | 3.0      | <price-0> |      |
      | id1 |     3 | 00003-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     4 | 00011-0 | 912828Q45 | Limit   | DAY | <side>   | 4.0      | 4.0     | <price-1> | Trade    | Filled          | 4.0      | <price-1> | 0.0       | 4.0      | <price-1> |      |
      | id1 |     5 | 00012-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 6.0     | <price-1> | Trade    | Filled          | 6.0      | <price-1> | 0.0       | 6.0      | <price-1> |      |
      | id1 |     6 | 00013-0 | 912828Q45 | Limit   | DAY | <side>   | 5.0      | 7.0     | <price-1> | Trade    | Filled          | 7.0      | <price-1> | 0.0       | 7.0      | <price-1> |      |
      | id1 |     7 | 00021-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 7.0     | <price-2> | Trade    | Filled          | 7.0      | <price-2> | 0.0       | 7.0      | <price-2> |      |
      | id1 |     8 | 00022-0 | 912828Q45 | Limit   | DAY | <side>   | 6.0      | 8.0     | <price-2> | Trade    | Filled          | 8.0      | <price-2> | 0.0       | 8.0      | <price-2> |      |
      | id1 |     9 | 00023-0 | 912828Q45 | Limit   | DAY | <side>   | 9.0      | 9.0     | <price-2> | Trade    | Filled          | 9.0      | <price-2> | 0.0       | 9.0      | <price-2> |      |
      | id1 |    10 | 00000-0 | 912828Q45 | Limit   | DAY | <side-i> | <sQty-i> | <qty-i> | 102.0     | Trade    | PartiallyFilled | 57.0     | <avgPx-i> | 1.0       | 57.0     | <avgPx-i> |      |

    Examples: Relevant Combinations
      | side-i | side | price-0 | price-1 | price-2 | sQty-i | qty-i | avgPx-i       || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 |
      | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 1.0    | 58.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 102.0  | 1.0     |
      | Buy    | Sell | 101.0   | 101.5   | 102.0   | 1.0    | 58.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 1.0     | 102.0  | NaN    | 0.0     |
      | Sell   | Buy  | 103.0   | 102.5   | 102.0   | 58.0   | 58.0  | 102.429824561 || 16.0    | 102.0  | 11.0    | 102.5  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 102.0  | 1.0     |
      | Buy    | Sell | 101.0   | 101.5   | 102.0   | 58.0   | 58.0  | 101.570175438 || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 101.5  | 11.0    | 102.0  | 16.0    || 1.0     | 102.0  | NaN    | 0.0     |

