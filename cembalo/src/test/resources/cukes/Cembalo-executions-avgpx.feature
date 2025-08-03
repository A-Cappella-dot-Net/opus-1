Feature: Cembalo - Executions AvgPx
  Verify that the avgPx is computed correctly

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  Scenario Outline: AvgPx test. Three level stack. Round robin fills. Amend and New.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side     | shownQty | qty     | price     |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side-i> | 1.0      | 2.0     | <price-i> |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side>   | 2.0      | 4.0     | <price-0> |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side>   | 1.0      | 2.0     | <price-0> |
      | id1 | 912828Q45 |     4 | 00003-0 | Limit   | DAY | <side>   | 3.0      | 5.0     | <price-0> |
      | id1 | 912828Q45 |     5 | 00011-0 | Limit   | DAY | <side>   | 2.0      | 10.0    | <price-1> |
      | id1 | 912828Q45 |     6 | 00012-0 | Limit   | DAY | <side>   | 1.0      | 6.0     | <price-1> |
      | id1 | 912828Q45 |     7 | 00013-0 | Limit   | DAY | <side>   | 3.0      | 15.0    | <price-1> |
      | id1 | 912828Q45 |     8 | 00021-0 | Limit   | DAY | <side>   | 1.0      | 7.0     | <price-2> |
      | id1 | 912828Q45 |     9 | 00022-0 | Limit   | DAY | <side>   | 3.0      | 8.0     | <price-2> |
      | id1 | 912828Q45 |    10 | 00023-0 | Limit   | DAY | <side>   | 2.0      | 9.0     | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-0> | <bid2-0> | <bidQ1-0> | <bid1-0> | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> | <ask1-0> | <askQ1-0> | <ask2-0> | <askQ2-0> |
    And the continuous orders for 912828Q45 and side <side-i> at level 0 with price <price-i> and leaves 2.0 and shown 1.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side-i> | 1.0      | 2.0     | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves 11.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
      | id1 |     4 | 00003-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
    And the continuous orders for 912828Q45 and side <side> at level 1 with price <price-1> and leaves 31.0 and shown 6.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty |  qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     5 | 00011-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 10.0 | 0.0     | NaN    | 10.0      | 0.0    | NaN   |
      | id1 |     6 | 00012-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 6.0  | 0.0     | NaN    | 6.0       | 0.0    | NaN   |
      | id1 |     7 | 00013-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 15.0 | 0.0     | NaN    | 15.0      | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side-i> | 1.0      | 2.0     | <price-i> | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 4.0     | <price-0> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 2.0     | <price-0> | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |
      | id1 |     4 | 00003-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 5.0     | <price-0> | New      | New       | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     5 | 00011-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 10.0    | <price-1> | New      | New       | 0.0     | NaN    | 10.0      | 0.0    | NaN   |      |
      | id1 |     6 | 00012-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 6.0     | <price-1> | New      | New       | 0.0     | NaN    | 6.0       | 0.0    | NaN   |      |
      | id1 |     7 | 00013-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 15.0    | <price-1> | New      | New       | 0.0     | NaN    | 15.0      | 0.0    | NaN   |      |
      | id1 |     8 | 00021-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 7.0     | <price-2> | New      | New       | 0.0     | NaN    | 7.0       | 0.0    | NaN   |      |
      | id1 |     9 | 00022-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 8.0     | <price-2> | New      | New       | 0.0     | NaN    | 8.0       | 0.0    | NaN   |      |
      | id1 |    10 | 00023-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 9.0     | <price-2> | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price     |
      |     1 | 00000-1 | 4.0      | 22.0    | 102.0     |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-1> | <bid2-1> | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> | <ask2-1> | <askQ2-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-1> and leaves <lQty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00011-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 10.0 | <xQty-1> | <price-1> | <lQty-1>  | <xQty-1> | <price-1> |
      | id1 |     6 | 00012-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 6.0  | <xQty-2> | <price-1> | <lQty-2>  | <xQty-2> | <price-1> |
      | id1 |     7 | 00013-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 15.0 | <xQty-3> | <price-1> | <lQty-3>  | <xQty-3> | <price-1> |
    And there are no continuous orders for instrument 912828Q45 and side <side-i> at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side-i> | 4.0      | 22.0    | 102.0     | Replaced | Replaced        | 0.0      | NaN       | 22.0      | 0.0      | NaN       |      |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 4.0     | <price-0> | Trade    | Filled          | 4.0      | <price-0> | 0.0       | 4.0      | <price-0> |      |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 2.0     | <price-0> | Trade    | Filled          | 2.0      | <price-0> | 0.0       | 2.0      | <price-0> |      |
      | id1 |     4 | 00003-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 5.0     | <price-0> | Trade    | Filled          | 5.0      | <price-0> | 0.0       | 5.0      | <price-0> |      |
      | id1 |     5 | 00011-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 10.0    | <price-1> | Trade    | PartiallyFilled | 4.0      | <price-1> | 6.0       | 4.0      | <price-1> |      |
      | id1 |     6 | 00012-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 6.0     | <price-1> | Trade    | PartiallyFilled | 2.0      | <price-1> | 4.0       | 2.0      | <price-1> |      |
      | id1 |     7 | 00013-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 15.0    | <price-1> | Trade    | PartiallyFilled | 5.0      | <price-1> | 10.0      | 5.0      | <price-1> |      |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side-i> | 4.0      | 22.0    | 102.0     | Trade    | Filled          | 22.0     | <avgPx-1> | 0.0       | 22.0     | <avgPx-1> |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price     |
      |     5 | 00011-1 | 2.0      | 10.0    | <price-0> |
      |     6 | 00012-1 | 1.0      | 6.0     | <price-0> |
      |     7 | 00013-1 | 3.0      | 15.0    | <price-0> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-2> | <bid2-2> | <bidQ1-2> | <bid1-2> | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> | <ask1-2> | <askQ1-2> | <ask2-2> | <askQ2-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-0> and leaves <lQty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     |
      | id1 |     5 | 00011-1 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 10.0 | 0.0      | NaN       | <lQty-1>  | <xQty-1> | <price-1> |
      | id1 |     6 | 00012-1 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 6.0  | 0.0      | NaN       | <lQty-2>  | <xQty-2> | <price-1> |
      | id1 |     7 | 00013-1 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 15.0 | 0.0      | NaN       | <lQty-3>  | <xQty-3> | <price-1> |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx     | text |
      | id1 |     5 | 00011-1 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 10.0    | <price-0> | Replaced | Replaced        | 0.0      | NaN       | 6.0       | 4.0      | <price-1> |      |
      | id1 |     6 | 00012-1 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 6.0     | <price-0> | Replaced | Replaced        | 0.0      | NaN       | 4.0       | 2.0      | <price-1> |      |
      | id1 |     7 | 00013-1 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 15.0    | <price-0> | Replaced | Replaced        | 0.0      | NaN       | 10.0      | 5.0      | <price-1> |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side     | shownQty | qty     | price     |
      | id1 | 912828Q45 |    11 | 00004-0 | Limit   | DAY | <side-i> | 4.0      | 32.0    | <price-2> |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ2     | bid2     | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     | ask2     | askQ2     |
      | <bidQ2-3> | <bid2-3> | <bidQ1-3> | <bid1-3> | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> | <ask1-3> | <askQ1-3> | <ask2-3> | <askQ2-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-2> and leaves <lQty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty  | lastQty   | lastPx    | leavesQty | cumQty    | avgPx     |
      | id1 |     8 | 00021-0 | 912828Q45 | Limit   | DAY | <side> | 1.0      | 7.0  | <xQty-21> | <price-2> | <lQty-21> | <xQty-21> | <price-2> |
      | id1 |     9 | 00022-0 | 912828Q45 | Limit   | DAY | <side> | 3.0      | 8.0  | <xQty-22> | <price-2> | <lQty-22> | <xQty-22> | <price-2> |
      | id1 |    10 | 00023-0 | 912828Q45 | Limit   | DAY | <side> | 2.0      | 9.0  | <xQty-23> | <price-2> | <lQty-23> | <xQty-23> | <price-2> |
	# avgPx-11: 4@price-1 + 6@price-0 / 10 = 102.6
	# avgPx=12: 2@price-1 + 4@price-0 / 6 = 102.(6)
	# avgPx-13: 5@price-1 + 10@price-0 / 15 = 102.(6)
	# avgPv-2: 20@price-0 + 12@price-2 / 32 = 102.25
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side     | shownQty | qty     | price     | execType | ordStatus       | lastQty  | lastPx    | leavesQty | cumQty   | avgPx      | text |
      | id1 |    11 | 00004-0 | 912828Q45 | Limit   | DAY | <side-i> | 4.0      | 32.0    | <price-2> | New      | New             | 0.0      | NaN       | 32.0      | 0.0      | NaN        |      |
      | id1 |     5 | 00011-1 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 10.0    | <price-0> | Trade    | Filled          | 6.0      | <price-0> | 0.0       | 10.0     | <avgPx-11> |      |
      | id1 |     6 | 00012-1 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 6.0     | <price-0> | Trade    | Filled          | 4.0      | <price-0> | 0.0       | 6.0      | <avgPx-12> |      |
      | id1 |     7 | 00013-1 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 15.0    | <price-0> | Trade    | Filled          | 10.0     | <price-0> | 0.0       | 15.0     | <avgPx-13> |      |
      | id1 |     8 | 00021-0 | 912828Q45 | Limit   | DAY | <side>   | 1.0      | 7.0     | <price-2> | Trade    | PartiallyFilled | 2.0      | <price-2> | 5.0       | 2.0      | <price-2>  |      |
      | id1 |     9 | 00022-0 | 912828Q45 | Limit   | DAY | <side>   | 3.0      | 8.0     | <price-2> | Trade    | PartiallyFilled | 6.0      | <price-2> | 2.0       | 6.0      | <price-2>  |      |
      | id1 |    10 | 00023-0 | 912828Q45 | Limit   | DAY | <side>   | 2.0      | 9.0     | <price-2> | Trade    | PartiallyFilled | 4.0      | <price-2> | 5.0       | 4.0      | <price-2>  |      |
      | id1 |    11 | 00004-0 | 912828Q45 | Limit   | DAY | <side-i> | 4.0      | 32.0    | <price-2> | Trade    | Filled          | 32.0     | <avgPx-2> | 0.0       | 32.0     | <avgPx-2>  |      |

    Examples: Relevant Combinations
      | side-i | side | price-i | price-0 | price-1 | price-2 | xQty-1 | lQty-1 | xQty-2 | lQty-2 | xQty-3 | lQty-3 | lQty-4 | sQty-4 | avgPx-1 | xQty-21 | lQty-21 | xQty-22 | lQty-22 | xQty-23 | lQty-23 | lQty-5 | sQty-5 | avgPx-11 | avgPx-12      | avgPx-13      | avgPx-2 || bidQ2-0 | bid2-0 | bidQ1-0 | bid1-0 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | ask1-0 | askQ1-0 | ask2-0 | askQ2-0 || bidQ2-1 | bid2-1 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | ask2-1 | askQ2-1 || bidQ2-2 | bid2-2 | bidQ1-2 | bid1-2 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | ask1-2 | askQ1-2 | ask2-2 | askQ2-2 || bidQ2-3 | bid2-3 | bidQ1-3 | bid1-3 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 | ask1-3 | askQ1-3 | ask2-3 | askQ2-3 |
      | Sell   | Buy  | 104.0   | 103.0   | 102.0   | 101.0   | 4.0    | 6.0    | 2.0    | 4.0    | 5.0    | 10.0   | 20.0   | 6.0    | 102.5   | 2.0     | 5.0     | 6.0     | 2.0     | 4.0     | 5.0     | 12.0   | 5.0    | 102.6    | 102.666666667 | 102.666666667 | 102.25  || 6.0     | 101.0  | 6.0     | 102.0  | 6.0     | 103.0  | 104.0  | 1.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 6.0     | 101.0  | 6.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 6.0     | 101.0  | 6.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 5.0     | 101.0  | NaN    | 0.0     | NaN    | 0.0     | NaN    | 0.0     |
      | Buy    | Sell | 100.0   | 101.0   | 102.0   | 103.0   | 4.0    | 6.0    | 2.0    | 4.0    | 5.0    | 10.0   | 20.0   | 6.0    | 101.5   | 2.0     | 5.0     | 6.0     | 2.0     | 4.0     | 5.0     | 12.0   | 5.0    | 101.4    | 101.333333334 | 101.333333334 | 101.75  || 0.0     | NaN    | 0.0     | NaN    | 1.0     | 100.0  | 101.0  | 6.0     | 102.0  | 6.0     | 103.0  | 6.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 6.0     | 103.0  | 6.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 6.0     | 103.0  | 6.0     | NaN    | 0.0     || 0.0     | NaN    | 0.0     | NaN    | 0.0     | NaN    | 103.0  | 5.0     | NaN    | 0.0     | NaN    | 0.0     |
