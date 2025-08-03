Feature: Cembalo - Size Amend
  shown size unchanged scenarios: 7/9->7/8, 4/4->4/5, 3/5->3/6
  shown size decrease scenarios: 7/9->6/9, 7/9->6/8, 9/9->6/9, 9/9->6/8, 9/9->6/6
  shown size increase scenarios: 4/4->5/5, 4/4->6/7, 3/5->4/4, 3/5->4/5, 3/5->4/6, 3/5->5/5, 3/5->6/6

  One order scenarios: NOSi OCRRi
  Two order scenarios: NOSi NOS1 OCRRi, NOS1 NOSi OCRRi
  Three order scenarios: NOSi NOS1 NOS2 OCRRi, NOS1 NOSi NOS2 OCRRi, NOS1 NOS2 NOSi OCRRi

  Background:
    Given the set of available instruments is
      | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
      | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
    And all books are initialized in open matching state
    And exchange starts with no active orders


  Scenario Outline: One order in the stack. No impact. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-j> and shown <sQty-j> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-i | qty-i | sQty-j | qty-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 |
  # shown size unchanged
      | Buy  | 7.0    | 9.0   | 7.0    | 8.0   | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 7.0    | 9.0   | 7.0    | 8.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 4.0    | 4.0   | 4.0    | 5.0   | 4.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     |
      | Sell | 4.0    | 4.0   | 4.0    | 5.0   | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 4.0     |
      | Buy  | 3.0    | 5.0   | 3.0    | 6.0   | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     |
      | Sell | 3.0    | 5.0   | 3.0    | 6.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 3.0     |
  # shown size decreased
      | Buy  | 7.0    | 9.0   | 6.0    | 9.0   | 7.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 7.0    | 9.0   | 6.0    | 9.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 7.0    | 9.0   | 6.0    | 8.0   | 7.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 7.0    | 9.0   | 6.0    | 8.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 9.0    | 9.0   | 6.0    | 9.0   | 9.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 9.0    | 9.0   | 6.0    | 9.0   | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 9.0    | 9.0   | 6.0    | 8.0   | 9.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 9.0    | 9.0   | 6.0    | 8.0   | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 9.0    | 9.0   | 6.0    | 6.0   | 9.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 9.0    | 9.0   | 6.0    | 6.0   | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 6.0     |


  Scenario Outline: Two orders in the stack. First order amended. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-i | qty-i | sQty-j | qty-j | sQty-2 | qty-2 | sQty-3 | qty-3 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 |
	# shown size unchanged
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 8.0    | 10.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 5.0    | 7.0   | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 5.0    | 7.0   | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 4.0    | 8.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 4.0    | 8.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 4.0     |
	# shown size decreased
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 7.0    | 11.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 7.0    | 10.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 7.0    | 11.0  | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 7.0    | 10.0  | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 7.0    | 8.0   | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 7.0    | 8.0   | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |

  Scenario Outline: Two orders in the stack. Second order amended. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     2 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-i | qty-i | sQty-j | qty-j | sQty-2 | qty-2 | sQty-3 | qty-3 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 |
	# shown size unchanged
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 8.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 5.0    | 7.0   | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 5.0    | 7.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 4.0    | 8.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 4.0    | 8.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 4.0     |
	# shown size decreased
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 7.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 7.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 7.0    | 8.0   | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 7.0    | 8.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 7.0     |

  Scenario Outline: Three orders in the stack. First order amended. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
  # shown size unchanged
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 10.0   | 13.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 10.0   | 13.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 10.0    |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 7.0    | 10.0  | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 6.0    | 11.0  | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 6.0    | 11.0  | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 6.0     |
  # shown size decreased
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 14.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 13.0  | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 14.0  | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 13.0  | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 11.0  | 9.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 9.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |

  Scenario Outline: Three orders in the stack. Second order amended. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     2 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
  # shown size unchanged
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 10.0   | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 10.0   | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 10.0    |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 6.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 6.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 6.0     |
	# shown size decreased
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 14.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 8.0    | 11.0  | 10.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 14.0  | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 10.0   | 11.0  | 12.0   | 14.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |

  Scenario Outline: Three orders in the stack. Third order amended. Shown size unchanged or decreased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     3 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
	# shown size unchanged
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 3.0    | 5.0   | 10.0   | 14.0  | 10.0   | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 7.0    | 8.0   | 3.0    | 5.0   | 10.0   | 14.0  | 10.0   | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 10.0    |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 3.0    | 5.0   | 7.0    | 9.0   | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 4.0    | 5.0   | 3.0    | 5.0   | 7.0    | 9.0   | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 6.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 3.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 6.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 6.0     |
	# shown size decreased
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 3.0    | 5.0   | 10.0   | 14.0  | 9.0    | 14.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 9.0   | 3.0    | 5.0   | 10.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 3.0    | 5.0   | 10.0   | 14.0  | 9.0    | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 10.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 7.0    | 9.0   | 6.0    | 8.0   | 3.0    | 5.0   | 10.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 10.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 14.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 9.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 14.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 13.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 8.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 13.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 12.0    | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 9.0    | 9.0   | 6.0    | 6.0   | 3.0    | 5.0   | 12.0   | 14.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 12.0    | 0.0     | NaN    | 102.0  | 9.0     |



  Scenario Outline: Two orders in the stack. First order amended. Shown size increased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-i | qty-i | sQty-j | qty-j | sQty-2 | qty-2 | sQty-3 | qty-3 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 6.0    | 7.0   | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 6.0    | 7.0   | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 5.0    | 6.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 5.0    | 6.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 5.0    | 7.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 5.0    | 7.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 5.0    | 8.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 5.0    | 8.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 7.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 7.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 7.0    | 8.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 7.0    | 8.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     |

  Scenario Outline: Two orders in the stack. Second order amended. Shown size increased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-2> and shown <sQty-2> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     2 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-i | qty-i | sQty-j | qty-j | sQty-2 | qty-2 | sQty-3 | qty-3 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 6.0    | 7.0   | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 6.0    | 7.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 1.0    | 2.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 5.0    | 6.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 5.0    | 6.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 5.0    | 7.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 5.0    | 7.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 5.0    | 8.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 5.0    | 8.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 7.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 7.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     |
      | Buy  | 1.0    | 2.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 7.0    | 8.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 7.0    | 8.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     |

  Scenario Outline: Three orders in the stack. First order amended. Shown size increased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 8.0    | 10.0  | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 9.0    | 12.0  | 4.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 9.0    | 12.0  | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 9.0   | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 9.0   | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 10.0  | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 11.0  | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 8.0    | 10.0  | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 9.0    | 11.0  | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 9.0     |

  Scenario Outline: Three orders in the stack. Second order amended. Shown size increased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     2 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 8.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 5.0    | 6.0   | 7.0    | 9.0   | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 9.0    | 12.0  | 1.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 5.0    | 6.0   | 7.0    | 9.0   | 9.0    | 12.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 9.0   | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 9.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 8.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 4.0    | 7.0   | 6.0    | 10.0  | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 9.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 4.0    | 7.0   | 6.0    | 10.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 9.0     |

  Scenario Outline: Three orders in the stack. Third order amended. Shown size increased.
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-1> and shown <sQty-1> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 102.0 | New      | New       | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-3> and shown <sQty-3> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 102.0 | New      | New       | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     3 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-4> and shown <sQty-4> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 102.0 | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     3 | 00000-1 | <sQty-j> | <qty-j> | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-5> and shown <sQty-5> are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | <qty-1> | 0.0     | NaN    | <qty-1>   | 0.0    | NaN   |
      | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | <qty-2> | 0.0     | NaN    | <qty-2>   | 0.0    | NaN   |
      | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 102.0 | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

    Examples: Relevant Combinations
      | side | sQty-1 | qty-1 | sQty-2 | qty-2 | sQty-i | qty-i | sQty-j | qty-j | sQty-3 | qty-3 | sQty-4 | qty-4 | sQty-5 | qty-5 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 3.0    | 5.0   | 7.0    | 9.0   | 8.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 5.0    | 5.0   | 3.0    | 5.0   | 7.0    | 9.0   | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 3.0    | 5.0   | 7.0    | 9.0   | 9.0    | 12.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 4.0    | 4.0   | 6.0    | 7.0   | 3.0    | 5.0   | 7.0    | 9.0   | 9.0    | 12.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 9.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 9.0   | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 4.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 9.0   | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 5.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 4.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 7.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 7.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 3.0    | 5.0   | 6.0    | 10.0  | 8.0    | 10.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 5.0    | 5.0   | 3.0    | 5.0   | 6.0    | 10.0  | 8.0    | 10.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 8.0     |
      | Buy  | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 9.0    | 11.0  | 1.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 9.0     | 102.0  | NaN    | 0.0     |
      | Sell | 1.0    | 2.0   | 2.0    | 3.0   | 3.0    | 5.0   | 6.0    | 6.0   | 3.0    | 5.0   | 6.0    | 10.0  | 9.0    | 11.0  | 0.0     | NaN    | 102.0  | 1.0     | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 102.0  | 9.0     |



  Scenario: Replace to more than filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 7.0      | 7.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 2.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 2.0 and shown 2.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 7.0      | 7.0     | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 7.0      | 7.0     | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 2.0       | 5.0    | 102.0 |      |

  Scenario: Replace to exactly filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 0.0       | NaN      | NaN      | 0.0       |
    And there are no continuous orders for instrument 912828Q45 and side Buy at level 0
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 5.0      | 5.0     | 102.0 | Replaced | Filled    | 0.0     | NaN    | 0.0       | 5.0    | 102.0 |      |

  Scenario: Replace to less than filled
    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 9.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 9.0 and shown 9.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 0.0     | NaN    | 9.0       | 0.0    | NaN   |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | New      | New       | 0.0     | NaN    | 9.0       | 0.0    | NaN   |      |

    When a new order is received
      | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price |
      | id2 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 |
    Then a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 4.0       | 102.0    | NaN      | 0.0       |
    And the continuous orders for 912828Q45 and side Buy at level 0 with price 102.0 and leaves 4.0 and shown 4.0 are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |
    And all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus       | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | New      | New             | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |
      | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | Buy    | 9.0      | 9.0     | 102.0 | Trade    | PartiallyFilled | 5.0     | 102.0  | 4.0       | 5.0    | 102.0 |      |
      | id2 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | Sell   | 5.0      | 5.0     | 102.0 | Trade    | Filled          | 5.0     | 102.0  | 0.0       | 5.0    | 102.0 |      |

    When a replacement request is received
      | ordId | clOrdId | shownQty | qty     | price |
      |     1 | 00000-1 | 4.0      | 4.0     | 102.0 |
    Then all execution reports sent back to clients are
      | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
      | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | Buy    | 4.0      | 4.0     | 102.0 | Replaced | Filled    | 0.0     | NaN    | -1.0      | 5.0    | 102.0 |      |
  # order book is cleared
    And a market data snapshot for 912828Q45 is sent to subscribers
      | bidQ0     | bid0     | ask0     | askQ0     |
      | 0.0       | NaN      | NaN      | 0.0       |
    And there are no continuous orders for instrument 912828Q45 and side Buy at level 0
