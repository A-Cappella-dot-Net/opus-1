Feature: Cembalo - Price Amend
  One order: NOSi 102, OCRRi {101,103}.
  Two merge: NOS1 102, NOSi {101,103}, OCRRi 102.
  Two split: NOSi 102, NOS1 102, OCRRi {101,103}. NOS1 102, NOSi 102, OCRRi {101,103}.
  Three split: NOSi 102, NOS1 102, NOS2 102, OCRRi {101,103}. NOS1 102, NOSi 102, NOS2 102, OCRRi {101,103}. NOS1 102, NOS2 102, NOSi 102, OCRRi {101,103}.
  Three merge: NOSi 102, NOS1 {101,103}, NOS2 {101,103}, OCRRi {101,103}

Background:
  Given the set of available instruments is
    | secId     | minQty | minQtyIncrement | minPriceIncrement | ordering | maxLevels |
    | 912828Q45 | 1.0    | 1.0             | 0.0078125         | 1        | 20        |
  And all books are initialized in open matching state
  And exchange starts with no active orders


Scenario Outline: One order in the stack.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty     | price     |
    | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | <price-i> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves <qty-i> and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | <qty-i> | <price-i> | New      | New       | 0.0     | NaN    | <qty-i>   | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty     | price     |
    |     1 | 00000-1 | <sQty-j> | <qty-j> | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-j> and leaves <qty-j> and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty     | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | <qty-j> | <price-j> | Replaced | Replaced  | 0.0     | NaN    | <qty-j>   | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-i | qty-i | price-i | sQty-j | qty-j | price-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 |
    | Buy  | 7.0    | 7.0   | 102.0   | 7.0    | 7.0   | 101.0   | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 101.0  | NaN    | 0.0     |
    | Buy  | 7.0    | 7.0   | 102.0   | 7.0    | 7.0   | 103.0   | 7.0     | 102.0  | NaN    | 0.0     | 7.0     | 103.0  | NaN    | 0.0     |
    | Buy  | 2.0    | 7.0   | 102.0   | 2.0    | 7.0   | 101.0   | 2.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | NaN    | 0.0     |
    | Buy  | 2.0    | 7.0   | 102.0   | 2.0    | 7.0   | 103.0   | 2.0     | 102.0  | NaN    | 0.0     | 2.0     | 103.0  | NaN    | 0.0     |
    | Buy  | 7.0    | 7.0   | 102.0   | 3.0    | 8.0   | 101.0   | 7.0     | 102.0  | NaN    | 0.0     | 3.0     | 101.0  | NaN    | 0.0     |
    | Buy  | 7.0    | 7.0   | 102.0   | 5.0    | 5.0   | 103.0   | 7.0     | 102.0  | NaN    | 0.0     | 5.0     | 103.0  | NaN    | 0.0     |
    | Buy  | 2.0    | 7.0   | 102.0   | 3.0    | 8.0   | 101.0   | 2.0     | 102.0  | NaN    | 0.0     | 3.0     | 101.0  | NaN    | 0.0     |
    | Buy  | 2.0    | 7.0   | 102.0   | 5.0    | 5.0   | 103.0   | 2.0     | 102.0  | NaN    | 0.0     | 5.0     | 103.0  | NaN    | 0.0     |
    | Sell | 7.0    | 7.0   | 102.0   | 7.0    | 7.0   | 101.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 101.0  | 7.0     |
    | Sell | 7.0    | 7.0   | 102.0   | 7.0    | 7.0   | 103.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 103.0  | 7.0     |
    | Sell | 2.0    | 7.0   | 102.0   | 2.0    | 7.0   | 101.0   | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 101.0  | 2.0     |
    | Sell | 2.0    | 7.0   | 102.0   | 2.0    | 7.0   | 103.0   | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 103.0  | 2.0     |
    | Sell | 7.0    | 7.0   | 102.0   | 3.0    | 8.0   | 101.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 101.0  | 3.0     |
    | Sell | 7.0    | 7.0   | 102.0   | 5.0    | 5.0   | 103.0   | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 103.0  | 5.0     |
    | Sell | 2.0    | 7.0   | 102.0   | 3.0    | 8.0   | 101.0   | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 101.0  | 3.0     |
    | Sell | 2.0    | 7.0   | 102.0   | 5.0    | 5.0   | 103.0   | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 103.0  | 5.0     |

Scenario Outline: Two orders in the stack at different levels. Levels get switched.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
    | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | <price-i> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price <price-i> and leaves 4.0 and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | <price-i> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     2 | 00000-1 | <sQty-j> | 4.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-2> | <bid1-2> | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> | <ask1-2> | <askQ1-2> |
  And the continuous orders for 912828Q45 and side <side> at level <level-2> with price <price-j> and leaves 4.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-i | sQty-j | price-i | price-j | level-1 | level-2 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | bidQ1-2 | bid1-2 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | ask1-2 | askQ1-2 |
    # price amend request moves current order from level 1 to level 0 at new price
    | Buy  | 3.0    | 4.0    | 4.0    | 101.0   | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 103.0   | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 101.0   | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 3.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 103.0   | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 3.0     |
    # price amend request moves current order from level 0 to level 1 at new price
    | Buy  | 3.0    | 4.0    | 4.0    | 103.0   | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 101.0   | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 103.0   | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 2.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 101.0   | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 2.0     |

Scenario Outline: Two orders in the stack at different levels. Merge into one level.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
    | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | <price-i> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-1> | <bid1-1> | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> | <ask1-1> | <askQ1-1> |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price <price-i> and leaves 4.0 and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | <price-i> | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price |
    |     2 | 00000-1 | <sQty-j> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <sQty-2> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | 102.0 | Replaced | Replaced  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-i | sQty-j | sQty-2 | price-i | level-1 | level-2 | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ1-1 | bid1-1 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | ask1-1 | askQ1-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     |
    # size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 5.0    | 101.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 5.0    | 103.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     | 0.0     | NaN    | 102.0  | 5.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 7.0    | 101.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 7.0    | 103.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 2.0     | 0.0     | NaN    | 102.0  | 7.0     |
    # price amend request merges two levels into one
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     |
    # size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 5.0    | 103.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 5.0    | 101.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 5.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 7.0    | 103.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 7.0    | 101.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     |

Scenario Outline: Two orders in the stack at the same level. First order amend. Split into two levels.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <sQty-2> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     1 | 00000-1 | <sQty-j> | 4.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-2> | <bid1-2> | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> | <ask1-2> | <askQ1-2> |
  And the continuous orders for 912828Q45 and side <side> at level <level-i> with price <price-j> and leaves 4.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-i | sQty-j | sQty-2 | price-j | level-1 | level-i | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ1-2 | bid1-2 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | ask1-2 | askQ1-2 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 0       | 1       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 7.0    | 101.0   | 0       | 1       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 7.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 2.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 5.0    | 101.0   | 0       | 1       | 2.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 5.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     |
    # price amend request splits one level into two
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 1       | 0       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 7.0    | 103.0   | 1       | 0       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 7.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 3.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 5.0    | 103.0   | 1       | 0       | 2.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 5.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     |

Scenario Outline: Two orders in the stack at the same level. Second order amend. Split into two levels.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <sQty-2> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     2 | 00000-1 | <sQty-j> | 4.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-2> | <bid1-2> | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> | <ask1-2> | <askQ1-2> |
  And the continuous orders for 912828Q45 and side <side> at level <level-j> with price <price-j> and leaves 4.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 4.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-i | sQty-j | sQty-2 | price-j | level-1 | level-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ1-2 | bid1-2 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | ask1-2 | askQ1-2 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 7.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 7.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 2.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 5.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 3.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 5.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 3.0     | 103.0  | 4.0     |
    # price amend request splits one level into two
    | Buy  | 3.0    | 4.0    | 4.0    | 7.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 4.0    | 7.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 4.0    | 2.0    | 7.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 4.0    | 2.0    | 7.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 3.0     |
    | Buy  | 3.0    | 2.0    | 4.0    | 5.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 3.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 2.0    | 4.0    | 5.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 3.0     |

Scenario Outline: Three orders in the stack at the same level. First order amend. Split into two levels.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 4.0 and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     2 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 9.0 and shown <sQty-4> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     1 | 00000-1 | <sQty-j> | 5.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-3> | <bid1-3> | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> | <ask1-3> | <askQ1-3> |
  And the continuous orders for 912828Q45 and side <side> at level <level-j> with price <price-j> and leaves 5.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price 102.0 and leaves 5.0 and shown <sQty-5> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-2 | sQty-i | sQty-j | sQty-3 | sQty-4 | sQty-5 | price-j | level-1 | level-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ1-3 | bid1-3 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 | ask1-3 | askQ1-3 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 101.0   | 0       | 1       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 101.0   | 0       | 1       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 2.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 101.0   | 0       | 1       | 2.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    # price amend request splits one level into two
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 103.0   | 1       | 0       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 103.0   | 1       | 0       | 4.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 4.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 103.0   | 1       | 0       | 2.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 2.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |

Scenario Outline: Three orders in the stack at the same level. Second order amend. Split into two levels.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     2 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 7.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     3 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 9.0 and shown <sQty-4> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     2 | 00000-1 | <sQty-j> | 5.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-3> | <bid1-3> | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> | <ask1-3> | <askQ1-3> |
  And the continuous orders for 912828Q45 and side <side> at level <level-j> with price <price-j> and leaves 5.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price 102.0 and leaves 5.0 and shown <sQty-5> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     3 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-2 | sQty-i | sQty-j | sQty-3 | sQty-4 | sQty-5 | price-j | level-1 | level-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ1-3 | bid1-3 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 | ask1-3 | askQ1-3 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 2.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    # price amend request splits one level into two
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 7.0    | 8.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 7.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 7.0    | 8.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 7.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 4.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 5.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 5.0    | 6.0    | 4.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 5.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |

Scenario Outline: Three orders in the stack at the same level. Third order amend. Split into two levels.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 102.0 | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 5.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 102.0 | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     3 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price 102.0 and leaves 9.0 and shown <sQty-4> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     3 | 00000-1 | <sQty-j> | 5.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-3> | <bid1-3> | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> | <ask1-3> | <askQ1-3> |
  And the continuous orders for 912828Q45 and side <side> at level <level-j> with price <price-j> and leaves 5.0 and shown <sQty-j> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-1> with price 102.0 and leaves 5.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-2 | sQty-i | sQty-j | sQty-3 | sQty-4 | price-j | level-1 | level-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | bidQ1-3 | bid1-3 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 | ask1-3 | askQ1-3 |
    # price amend request moves current order from level 1 to level 0 at existing price
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 8.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 2.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 8.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 2.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 6.0    | 101.0   | 0       | 1       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 6.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     |
    # price amend request splits one level into two
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |
    #   size amend is not relevant if there is also a price amend
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 8.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 8.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 2.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 8.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 8.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 2.0     | 102.0  | 4.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 6.0    | 103.0   | 1       | 0       | 3.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | NaN    | 0.0     | 6.0     | 102.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 6.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 102.0  | 3.0     | 0.0     | NaN    | 102.0  | 4.0     | 0.0     | NaN    | 102.0  | 6.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     |

Scenario Outline: Three orders in the stack at two levels. Merge into one level.
  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
    | id1 | 912828Q45 |     1 | 00001-0 | Limit   | DAY | <side> | <sQty-1> | 3.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-0> | <bid0-0> | <ask0-0> | <askQ0-0> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-j> and leaves 3.0 and shown <sQty-1> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | <price-j> | New      | New       | 0.0     | NaN    | 3.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price     |
    | id1 | 912828Q45 |     2 | 00002-0 | Limit   | DAY | <side> | <sQty-2> | 2.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-1> | <bid0-1> | <ask0-1> | <askQ0-1> |
  And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-j> and leaves 5.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | <price-j> | New      | New       | 0.0     | NaN    | 2.0       | 0.0    | NaN   |      |

  When a new order is received
    | uid | secId     | ordId | clOrdId | ordType | tif | side   | shownQty | qty | price |
    | id1 | 912828Q45 |     3 | 00000-0 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ1     | bid1     | bidQ0     | bid0     | ask0     | askQ0     | ask1     | askQ1     |
    | <bidQ1-2> | <bid1-2> | <bidQ0-2> | <bid0-2> | <ask0-2> | <askQ0-2> | <ask1-2> | <askQ1-2> |
  And the continuous orders for 912828Q45 and side <side> at level <level-i> with price 102.0 and leaves 4.0 and shown <sQty-i> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 0.0     | NaN    | 4.0       | 0.0    | NaN   |
  And the continuous orders for 912828Q45 and side <side> at level <level-j> with price <price-j> and leaves 5.0 and shown <sQty-3> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00000-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-i> | 4.0 | 102.0 | New      | New       | 0.0     | NaN    | 4.0       | 0.0    | NaN   |      |

  When a replacement request is received
    | ordId | clOrdId | shownQty | qty | price     |
    |     3 | 00000-1 | <sQty-j> | 5.0 | <price-j> |
  Then a market data snapshot for 912828Q45 is sent to subscribers
    | bidQ0     | bid0     | ask0     | askQ0     |
    | <bidQ0-3> | <bid0-3> | <ask0-3> | <askQ0-3> |
    And the continuous orders for 912828Q45 and side <side> at level 0 with price <price-j> and leaves 10.0 and shown <sQty-4> are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | lastQty | lastPx | leavesQty | cumQty | avgPx |
    | id1 |     1 | 00001-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-1> | 3.0 | 0.0     | NaN    | 3.0       | 0.0    | NaN   |
    | id1 |     2 | 00002-0 | 912828Q45 | Limit   | DAY | <side> | <sQty-2> | 2.0 | 0.0     | NaN    | 2.0       | 0.0    | NaN   |
    | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | 0.0     | NaN    | 5.0       | 0.0    | NaN   |
  And all execution reports sent back to clients are
    | uid | ordId | clOrdId | secId     | ordType | tif | side   | shownQty | qty | price     | execType | ordStatus | lastQty | lastPx | leavesQty | cumQty | avgPx | text |
    | id1 |     3 | 00000-1 | 912828Q45 | Limit   | DAY | <side> | <sQty-j> | 5.0 | <price-j> | Replaced | Replaced  | 0.0     | NaN    | 5.0       | 0.0    | NaN   |      |

Examples: Relevant Combinations
    | side | sQty-1 | sQty-2 | sQty-i | sQty-j | sQty-3 | sQty-4 | price-j | level-i | level-j | bidQ0-0 | bid0-0 | ask0-0 | askQ0-0 | bidQ0-1 | bid0-1 | ask0-1 | askQ0-1 | bidQ1-2 | bid1-2 | bidQ0-2 | bid0-2 | ask0-2 | askQ0-2 | ask1-2 | askQ1-2 | bidQ0-3 | bid0-3 | ask0-3 | askQ0-3 |
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 101.0   | 0       | 1       | 3.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 8.0     | 101.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 101.0  | 3.0     | 0.0     | NaN    | 101.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     | 0.0     | NaN    | 101.0  | 8.0     |
    | Buy  | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 103.0   | 1       | 0       | 3.0     | 103.0  | NaN    | 0.0     | 4.0     | 103.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 8.0     | 103.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 4.0    | 4.0    | 8.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 103.0  | 3.0     | 0.0     | NaN    | 103.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     | 0.0     | NaN    | 103.0  | 8.0     |

    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 6.0    | 101.0   | 0       | 1       | 3.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | 4.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 6.0     | 101.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 6.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 101.0  | 3.0     | 0.0     | NaN    | 101.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 4.0     | 0.0     | NaN    | 101.0  | 6.0     |
    | Buy  | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 6.0    | 103.0   | 1       | 0       | 3.0     | 103.0  | NaN    | 0.0     | 4.0     | 103.0  | NaN    | 0.0     | 4.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 6.0     | 103.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 4.0    | 2.0    | 4.0    | 6.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 103.0  | 3.0     | 0.0     | NaN    | 103.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 4.0     | 103.0  | 4.0     | 0.0     | NaN    | 103.0  | 6.0     |

    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 8.0    | 101.0   | 0       | 1       | 3.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | NaN    | 0.0     | 4.0     | 101.0  | 2.0     | 102.0  | NaN    | 0.0     | NaN    | 0.0     | 8.0     | 101.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 8.0    | 101.0   | 1       | 0       | 0.0     | NaN    | 101.0  | 3.0     | 0.0     | NaN    | 101.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 101.0  | 4.0     | 102.0  | 2.0     | 0.0     | NaN    | 101.0  | 8.0     |
    | Buy  | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 8.0    | 103.0   | 1       | 0       | 3.0     | 103.0  | NaN    | 0.0     | 4.0     | 103.0  | NaN    | 0.0     | 2.0     | 102.0  | 4.0     | 103.0  | NaN    | 0.0     | NaN    | 0.0     | 8.0     | 103.0  | NaN    | 0.0     |
    | Sell | 3.0    | 1.0    | 2.0    | 4.0    | 4.0    | 8.0    | 103.0   | 0       | 1       | 0.0     | NaN    | 103.0  | 3.0     | 0.0     | NaN    | 103.0  | 4.0     | 0.0     | NaN    | 0.0     | NaN    | 102.0  | 2.0     | 103.0  | 4.0     | 0.0     | NaN    | 103.0  | 8.0     |
